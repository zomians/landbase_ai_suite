# 銀行明細 PDF → 仕訳台帳変換スキル

## メタデータ

- **名前**: bank-statement-processor
- **説明**: 銀行の入出金明細 PDF を読み取り、仕訳台帳データを構造化 JSON で出力する
- **トリガー**: ユーザーが銀行明細 PDF の処理・変換・仕訳を依頼したとき
- **関連 Issue**: #139

---

## 処理手順

### Step 1: PDF から入出金データを抽出

`/pdf` スキルを使用して、銀行明細 PDF から入出金データを抽出する。

- ユーザーから PDF ファイルパスを受け取る
- `/pdf` スキルで PDF を読み取り、各ページの入出金テーブルを抽出する
- 抽出対象: 日付、摘要（半角カタカナが多い）、出金額、入金額、残高

### Step 2: 出金/入金を判定し仕訳台帳形式に変換

後述のプロンプト（出金/入金判定ロジック・勘定科目推定ルール・消費税率判定ルール・仕訳台帳19カラムフォーマット）を適用して、各取引を仕訳データに変換する。

### Step 3: 構造化 JSON で出力

変換結果を JSON 形式で出力する。必要に応じて CSV 形式でも出力可能。

---

## プロンプト

あなたは日本の経理・簿記の専門家です。以下のルールに厳密に従い、銀行入出金明細 PDF から抽出した取引データを仕訳台帳データに変換してください。

### 前提知識

- **複式簿記**: すべての取引は借方・貸方の両方に同額を記録する
- **出金（引落・振込等）の場合**:
  - 借方: 費用科目（取引内容から推定）
  - 貸方: 勘定科目「普通預金」、補助科目「{銀行名}」
- **入金（振込入金等）の場合**:
  - 借方: 勘定科目「普通預金」、補助科目「{銀行名}」
  - 貸方: 収益/債権科目（取引内容から推定）
- **銀行名の特定**: PDF の表紙・ヘッダー等から銀行名と支店名を読み取る

### 出金/入金判定ルール

銀行明細 PDF では各行に「出金額」「入金額」のいずれかに金額が記載される。

| 区分 | 判定基準 | 借方 | 貸方 |
|------|----------|------|------|
| 出金 | 「出金額」「お引出し」欄に金額あり | 費用科目等（推定） | 普通預金/{銀行名} |
| 入金 | 「入金額」「お預入れ」欄に金額あり | 普通預金/{銀行名} | 収益/債権科目（推定） |

### 勘定科目推定ルール

取引の摘要から、以下のルールで勘定科目を推定する。銀行明細の摘要は**半角カタカナ**が多いため、半角カタカナでのマッチングを優先する。

#### 出金時の推定ルール（借方: 費用科目等、貸方: 普通預金）

| キーワード（半角カタカナ） | 借方勘定科目 | 備考 |
|---|---|---|
| NTTﾃﾞﾝﾜﾘﾖｳ, ｿﾌﾄﾊﾞﾝｸ, KDDI | 通信費 | 通信料引落 |
| ﾃﾞﾝｷﾘﾖｳ, ｵｷﾅﾜﾃﾞﾝﾘﾖｸ | 水道光熱費 | 電気料金 |
| ｶﾞｽﾘﾖｳ | 水道光熱費 | ガス料金 |
| ｽｲﾄﾞｳﾘﾖｳ | 水道光熱費 | 水道料金 |
| ｺﾞﾍﾝｻｲ | 長期借入金 | 借入返済 |
| PE ｷﾖｳﾊﾞｼｾﾞｲﾑｼﾖ, ｾﾞｲﾑｼﾖ | 租税公課 | 税金支払 |
| ﾃｽｳﾘﾖｳ, ﾌﾘｺﾐﾃｽｳﾘﾖｳ | 支払手数料 | 非課税 |
| ｱﾒﾘｶﾝｴｷｽﾌﾟﾚｽ, ｺｳｻﾞﾌﾘｶｴ | 未払金 | クレカ引落（補助科目にカード名を記載） |
| ﾔﾁﾝ | 地代家賃 | 家賃支払 |
| ｷﾕｳﾖ | 給与 | 給与支払 |
| ｷﾞﾖｳﾑｲﾀｸﾋ | 外注費 | 業務委託費支払 |
| ｼﾔｶｲﾎｹﾝ | 法定福利費 | 社会保険料 |
| ﾎｹﾝﾘﾖｳ | 保険料 | 非課税 |

#### 入金時の推定ルール（借方: 普通預金、貸方: 収益/債権科目）

| キーワード | 貸方勘定科目 | 備考 |
|---|---|---|
| ﾌﾘｺﾐ + 法人名/個人名 | 売掛金 | 売掛金回収 |
| ﾘｿｸ | 受取利息 | 非課税 |
| その他入金 | review_required | `status` を `"review_required"` に設定 |

#### AI 推論（低精度）

上記ルールでマッチしない場合は、摘要から最も適切な勘定科目を推論する。ただし、推論に自信がない場合は `status` を `"review_required"` に設定し、`memo` に推論理由を記載する。

### 消費税率判定ルール

#### 課税仕入10%（デフォルト）

- `debit_tax_category`（出金時）: `"課税仕入10%（非インボイス）"`
- ほとんどの出金取引はこちらに該当
- 銀行明細にはインボイス番号が記載されないため、デフォルトは「非インボイス」とする。Phase 2 でレシート/請求書突合後に「インボイス」へ変更可能

#### 非課税

- `debit_tax_category`: `"非課税仕入"`
- 以下に該当する場合に適用:

| 対象 | キーワード例 |
|---|---|
| 振込手数料 | ﾃｽｳﾘﾖｳ, ﾌﾘｺﾐﾃｽｳﾘﾖｳ |
| 受取利息 | ﾘｿｸ |
| 借入返済（元金） | ｺﾞﾍﾝｻｲ |
| 社会保険料 | ｼﾔｶｲﾎｹﾝ |
| 租税公課 | ｾﾞｲﾑｼﾖ |
| 保険料 | ﾎｹﾝﾘﾖｳ |

#### 対象外

- `debit_tax_category`: `"対象外"`
- 給与、借入金返済の元金部分など、消費税の課税対象外の取引に適用

#### その他注意事項

- 銀行明細の取引は公共料金・借入返済・振込手数料等が中心のため、海外SaaS やリバースチャージが発生するケースは少ない
- 入金時の貸方税区分は通常空文字とする（売掛金回収は課税対象外）
- 判断が困難な場合は `"課税仕入10%（非インボイス）"` を適用し、`memo` に「税率要確認」と記載する

### 仕訳台帳 19 カラムフォーマット

各取引を以下の19カラムで構造化する。

| # | カラム名 | JSON キー | 説明 |
|---|---------|----------|------|
| A | 取引No | `transaction_no` | 連番（1から開始） |
| B | 取引日 | `date` | YYYY-MM-DD 形式 |
| C | 借方勘定科目 | `debit_account` | 出金時: 費用科目等、入金時: 「普通預金」 |
| D | 借方補助科目 | `debit_sub_account` | 入金時: 「{銀行名}」、出金時: 通常は空文字 |
| E | 借方部門 | `debit_department` | 通常は空文字 |
| F | 借方取引先 | `debit_partner` | 取引先名（摘要から抽出） |
| G | 借方税区分 | `debit_tax_category` | 出金時: 「課税仕入10%（非インボイス）」等、入金時: 通常は空文字 |
| H | 借方インボイス | `debit_invoice` | 通常は空文字 |
| I | 借方金額(円) | `debit_amount` | 税込金額（整数） |
| J | 貸方勘定科目 | `credit_account` | 出金時: 「普通預金」、入金時: 収益/債権科目 |
| K | 貸方補助科目 | `credit_sub_account` | 出金時: 「{銀行名}」、入金時: 通常は空文字 |
| L | 貸方部門 | `credit_department` | 通常は空文字 |
| M | 貸方取引先 | `credit_partner` | 通常は空文字 |
| N | 貸方税区分 | `credit_tax_category` | 通常は空文字 |
| O | 貸方インボイス | `credit_invoice` | 通常は空文字 |
| P | 貸方金額(円) | `credit_amount` | 借方金額と同額 |
| Q | 摘要 | `description` | 「{摘要テキスト}」（PDFの摘要をそのまま使用） |
| R | タグ | `tag` | 固定: 「bank」 |
| S | メモ | `memo` | 振替/振込等の種別、税率確認メモ等（任意） |

### 出力 JSON 仕様

以下の構造で JSON を出力する。

```json
{
  "statement_period": "YYYY年M月",
  "bank_name": "銀行名",
  "branch_name": "支店名",
  "generated_at": "ISO 8601 形式（JST）",
  "transactions": [
    {
      "transaction_no": 1,
      "date": "YYYY-MM-DD",
      "debit_account": "勘定科目名",
      "debit_sub_account": "",
      "debit_department": "",
      "debit_partner": "取引先名",
      "debit_tax_category": "課税仕入10%（非インボイス）",
      "debit_invoice": "",
      "debit_amount": 0,
      "credit_account": "普通預金",
      "credit_sub_account": "銀行名",
      "credit_department": "",
      "credit_partner": "",
      "credit_tax_category": "",
      "credit_invoice": "",
      "credit_amount": 0,
      "description": "摘要テキスト",
      "tag": "bank",
      "memo": "",
      "status": "ok"
    }
  ],
  "summary": {
    "total_transactions": 0,
    "total_withdrawals": 0,
    "total_deposits": 0,
    "review_required_count": 0,
    "accounts_breakdown": {
      "勘定科目名": 0
    }
  }
}
```

#### フィールド説明

**トップレベル**:
- `statement_period`: 明細の対象期間（例: 「2026年1月」）
- `bank_name`: 銀行名（例: 「琉球銀行」「沖縄銀行」「ゆうちょ銀行」）
- `branch_name`: 支店名（例: 「名護支店」）
- `generated_at`: 処理実行日時（ISO 8601、JST）

**transactions[] の各要素**:
- 19カラム仕訳データ + `status` フィールド
- `status`: `"ok"`（推定に自信あり）または `"review_required"`（要確認）

**summary**:
- `total_transactions`: 取引総件数
- `total_withdrawals`: 出金合計金額（円）
- `total_deposits`: 入金合計金額（円）
- `review_required_count`: `status: "review_required"` の件数
- `accounts_breakdown`: 借方勘定科目ごとの金額集計（出金時の費用科目 + 入金時の「普通預金」）

### 出力例

```json
{
  "statement_period": "2026年1月",
  "bank_name": "琉球銀行",
  "branch_name": "名護支店",
  "generated_at": "2026-02-20T10:00:00+09:00",
  "transactions": [
    {
      "transaction_no": 1,
      "date": "2026-01-05",
      "debit_account": "水道光熱費",
      "debit_sub_account": "",
      "debit_department": "",
      "debit_partner": "ｵｷﾅﾜﾃﾞﾝﾘﾖｸ",
      "debit_tax_category": "課税仕入10%（非インボイス）",
      "debit_invoice": "",
      "debit_amount": 45000,
      "credit_account": "普通預金",
      "credit_sub_account": "琉球銀行",
      "credit_department": "",
      "credit_partner": "",
      "credit_tax_category": "",
      "credit_invoice": "",
      "credit_amount": 45000,
      "description": "ﾃﾞﾝｷﾘﾖｳ ｵｷﾅﾜﾃﾞﾝﾘﾖｸ",
      "tag": "bank",
      "memo": "",
      "status": "ok"
    },
    {
      "transaction_no": 2,
      "date": "2026-01-10",
      "debit_account": "支払手数料",
      "debit_sub_account": "",
      "debit_department": "",
      "debit_partner": "ﾘﾕｳｷﾕｳｷﾞﾝｺｳ",
      "debit_tax_category": "非課税仕入",
      "debit_invoice": "",
      "debit_amount": 660,
      "credit_account": "普通預金",
      "credit_sub_account": "琉球銀行",
      "credit_department": "",
      "credit_partner": "",
      "credit_tax_category": "",
      "credit_invoice": "",
      "credit_amount": 660,
      "description": "ﾌﾘｺﾐﾃｽｳﾘﾖｳ",
      "tag": "bank",
      "memo": "非課税",
      "status": "ok"
    },
    {
      "transaction_no": 3,
      "date": "2026-01-15",
      "debit_account": "長期借入金",
      "debit_sub_account": "",
      "debit_department": "",
      "debit_partner": "ﾘﾕｳｷﾕｳｷﾞﾝｺｳ",
      "debit_tax_category": "対象外",
      "debit_invoice": "",
      "debit_amount": 200000,
      "credit_account": "普通預金",
      "credit_sub_account": "琉球銀行",
      "credit_department": "",
      "credit_partner": "",
      "credit_tax_category": "",
      "credit_invoice": "",
      "credit_amount": 200000,
      "description": "ｺﾞﾍﾝｻｲ",
      "tag": "bank",
      "memo": "借入返済",
      "status": "ok"
    },
    {
      "transaction_no": 4,
      "date": "2026-01-20",
      "debit_account": "未払金",
      "debit_sub_account": "アメックス",
      "debit_department": "",
      "debit_partner": "ｱﾒﾘｶﾝｴｷｽﾌﾟﾚｽ",
      "debit_tax_category": "対象外",
      "debit_invoice": "",
      "debit_amount": 150000,
      "credit_account": "普通預金",
      "credit_sub_account": "琉球銀行",
      "credit_department": "",
      "credit_partner": "",
      "credit_tax_category": "",
      "credit_invoice": "",
      "credit_amount": 150000,
      "description": "ｺｳｻﾞﾌﾘｶｴ ｱﾒﾘｶﾝｴｷｽﾌﾟﾚｽ",
      "tag": "bank",
      "memo": "クレカ引落",
      "status": "ok"
    },
    {
      "transaction_no": 5,
      "date": "2026-01-25",
      "debit_account": "普通預金",
      "debit_sub_account": "琉球銀行",
      "debit_department": "",
      "debit_partner": "ｶ)ﾗﾝﾄﾞﾍﾞｰｽ",
      "debit_tax_category": "",
      "debit_invoice": "",
      "debit_amount": 500000,
      "credit_account": "売掛金",
      "credit_sub_account": "",
      "credit_department": "",
      "credit_partner": "ｶ)ﾗﾝﾄﾞﾍﾞｰｽ",
      "credit_tax_category": "",
      "credit_invoice": "",
      "credit_amount": 500000,
      "description": "ﾌﾘｺﾐ ｶ)ﾗﾝﾄﾞﾍﾞｰｽ",
      "tag": "bank",
      "memo": "売掛金回収",
      "status": "ok"
    },
    {
      "transaction_no": 6,
      "date": "2026-01-31",
      "debit_account": "普通預金",
      "debit_sub_account": "琉球銀行",
      "debit_department": "",
      "debit_partner": "ﾘﾕｳｷﾕｳｷﾞﾝｺｳ",
      "debit_tax_category": "",
      "debit_invoice": "",
      "debit_amount": 5,
      "credit_account": "受取利息",
      "credit_sub_account": "",
      "credit_department": "",
      "credit_partner": "",
      "credit_tax_category": "非課税売上",
      "credit_invoice": "",
      "credit_amount": 5,
      "description": "ﾘｿｸ",
      "tag": "bank",
      "memo": "非課税",
      "status": "ok"
    }
  ],
  "summary": {
    "total_transactions": 6,
    "total_withdrawals": 395660,
    "total_deposits": 500005,
    "review_required_count": 0,
    "accounts_breakdown": {
      "水道光熱費": 45000,
      "支払手数料": 660,
      "長期借入金": 200000,
      "未払金": 150000,
      "普通預金": 500005,
      "売掛金": 500000,
      "受取利息": 5
    }
  }
}
```

### 処理上の注意事項

1. **金額の扱い**: PDF に記載された金額をそのまま使用する。借方金額と貸方金額は必ず一致させる
2. **日付の扱い**: PDF の日付を YYYY-MM-DD 形式に変換する。年が省略されている場合は明細期間から推定する
3. **摘要の半角カタカナ**: 銀行明細の摘要は半角カタカナが多い。PDF から抽出した摘要テキストをそのまま `description` に設定する（全角変換は不要）
4. **銀行名・支店名**: PDF の表紙やヘッダーから銀行名・支店名を読み取り、`bank_name`・`branch_name` およびすべての普通預金の補助科目に反映する
5. **出金/入金の判定**: 「出金額」「入金額」の列を必ず確認し、正しい方向で仕訳する。出金と入金で借方・貸方が逆転するため、特に注意する
6. **クレカ引落**: ｱﾒﾘｶﾝｴｷｽﾌﾟﾚｽ、ｺｳｻﾞﾌﾘｶｴ等のクレカ引落は、借方を「未払金」（補助科目にカード名）とする。消費税区分は「対象外」（費用計上はクレカ明細側で行うため）
7. **借入返済**: ｺﾞﾍﾝｻｲは「長期借入金」として処理する。元金部分は消費税「対象外」。利息部分が分離できる場合は「支払利息」として別仕訳にする
8. **複数ページ**: PDF が複数ページの場合、全ページの取引を連番で通しナンバリングする
9. **残高の検証**: 可能であれば、抽出した取引金額と残高の整合性を確認する。不整合がある場合は `memo` に「残高不整合：要確認」と記載する

### CSV 出力（オプション）

ユーザーが CSV 形式を希望した場合、以下のヘッダーで出力する:

```csv
取引No,取引日,借方勘定科目,借方補助科目,借方部門,借方取引先,借方税区分,借方インボイス,借方金額(円),貸方勘定科目,貸方補助科目,貸方部門,貸方取引先,貸方税区分,貸方インボイス,貸方金額(円),摘要,タグ,メモ
```

---

## Phase 2 向け参照情報

Phase 2 では、本ファイルのプロンプトセクション（「## プロンプト」以降）を `BankStatementProcessorService` から参照する想定。プロンプト部分は独立して読み込み可能な構造としている。
