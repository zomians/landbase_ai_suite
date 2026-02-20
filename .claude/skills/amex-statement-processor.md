# Amex 明細 PDF → 仕訳台帳変換スキル

## メタデータ

- **名前**: amex-statement-processor
- **説明**: アメリカン・エキスプレスの利用明細 PDF を読み取り、仕訳台帳データを構造化 JSON で出力する
- **トリガー**: ユーザーが Amex 明細 PDF の処理・変換・仕訳を依頼したとき
- **関連 Issue**: #136

---

## 処理手順

### Step 1: PDF からテーブルデータを抽出

`/pdf` スキルを使用して、Amex 明細 PDF から取引データテーブルを抽出する。

- ユーザーから PDF ファイルパスを受け取る
- `/pdf` スキルで PDF を読み取り、各ページの取引テーブルを抽出する
- 抽出対象: 日付、店舗名/利用先、金額、カテゴリ（あれば）

### Step 2: 取引データを仕訳台帳形式に変換

後述のプロンプト（勘定科目推定ロジック・消費税率判定ロジック・仕訳台帳20カラムフォーマット）を適用して、各取引を仕訳データに変換する。

### Step 3: 構造化 JSON で出力

変換結果を JSON 形式で出力する。必要に応じて CSV 形式でも出力可能。

---

## プロンプト

あなたは日本の経理・簿記の専門家です。以下のルールに厳密に従い、Amex 利用明細 PDF から抽出した取引データを仕訳台帳データに変換してください。

### 前提知識

- **複式簿記**: すべての取引は借方・貸方の両方に同額を記録する
- **貸方は全取引共通**: 勘定科目「未払金」、補助科目「アメックス」
- **借方の勘定科目**: 取引内容から推定する（後述のマッピングルール参照）

### 勘定科目推定ルール

取引の店舗名・利用先から、以下の優先順位で借方勘定科目を推定する。

#### 優先度1: 店舗名キーワードでの一致（高精度）

| キーワード | 借方勘定科目 | 備考 |
|---|---|---|
| Amazon, アマゾン | 消耗品費 | 書籍の場合は「新聞図書費」 |
| ENEOS, 出光, コスモ, Shell, エネオス, IDEMITSU | 車両費 | ガソリンスタンド |
| UBER EATS, Uber Eats, ウーバーイーツ | 会議費 | 軽減税率8%対象 |
| 出前館 | 会議費 | 軽減税率8%対象 |
| Adobe, ADOBE | 通信費 | SaaS/サブスクリプション |
| Google, GOOGLE | 通信費 | クラウドサービス |
| Microsoft, MICROSOFT | 通信費 | SaaS/サブスクリプション |
| AWS, Amazon Web Services | 通信費 | クラウドサービス |
| Zoom, ZOOM | 通信費 | SaaS/サブスクリプション |
| Slack, SLACK | 通信費 | SaaS/サブスクリプション |
| ChatGPT, OpenAI, OPENAI | 通信費 | SaaS/サブスクリプション |
| Anthropic, ANTHROPIC | 通信費 | SaaS/サブスクリプション |
| セブンイレブン, セブン-イレブン, 7-ELEVEN | 消耗品費 | 軽減税率8%対象（食品の場合） |
| ローソン, LAWSON | 消耗品費 | 軽減税率8%対象（食品の場合） |
| ファミリーマート, FamilyMart, ファミマ | 消耗品費 | 軽減税率8%対象（食品の場合） |
| ミニストップ, MINISTOP | 消耗品費 | 軽減税率8%対象（食品の場合） |
| イオン, AEON | 消耗品費 | 軽減税率8%対象（食品の場合） |
| 西友, SEIYU | 消耗品費 | 軽減税率8%対象（食品の場合） |
| スターバックス, STARBUCKS | 会議費 | |
| タリーズ, TULLY'S | 会議費 | |
| ドトール, DOUTOR | 会議費 | |
| JR, ＪＲ | 旅費交通費 | |
| ANA, 全日空 | 旅費交通費 | |
| JAL, 日本航空 | 旅費交通費 | |
| タクシー, Taxi | 旅費交通費 | |
| 駐車場, パーキング, PARKING | 旅費交通費 | |
| ETC | 旅費交通費 | 高速道路 |
| ヤマト運輸, 佐川急便, 日本郵便 | 荷造運賃 | 配送料 |
| 東京電力, 関西電力, 沖縄電力 | 水道光熱費 | |
| 東京ガス, 大阪ガス | 水道光熱費 | |
| NTT, ソフトバンク, KDDI, au, docomo | 通信費 | 通信料 |

#### 優先度2: 取引内容・カテゴリからの推定（中精度）

| 取引内容キーワード | 借方勘定科目 |
|---|---|
| 駐車場, パーキング | 旅費交通費 |
| 高速, 有料道路 | 旅費交通費 |
| 宿泊, ホテル, Hotel | 旅費交通費 |
| レンタカー | 車両費 |
| 保険 | 保険料 |
| 修繕, 修理, メンテナンス | 修繕費 |

#### 優先度3: AI 推論（低精度）

上記ルールでマッチしない場合は、店舗名・取引内容から最も適切な勘定科目を推論する。ただし、推論に自信がない場合は `status` を `"review_required"` に設定し、`memo` に推論理由を記載する。

### 消費税率判定ルール

#### 標準税率: 10%（デフォルト）

- `debit_tax_category`: `"課税仕入10%"`
- ほとんどの取引はこちらに該当

#### 軽減税率: 8%

- `debit_tax_category`: `"課税仕入8%（軽減）"`
- 以下に該当する場合に適用:

| 対象 | キーワード例 |
|---|---|
| コンビニ（食品購入） | セブンイレブン、ローソン、ファミリーマート、ミニストップ |
| スーパー（食品購入） | イオン、西友、マックスバリュ |
| フードデリバリー | Uber Eats、出前館 |

#### 課税対象外（海外取引）

- `debit_tax_category`: `"課税対象外"`
- 海外での物品購入・飲食など、日本の消費税が課税されない取引に適用
- 判定方法: 外貨建て金額（USD等）の記載がある取引、または明らかに海外店舗での利用

| 対象 | 判定基準 |
|---|---|
| 海外での飲食 | 外貨金額あり + 飲食店名（英語） |
| 海外での物品購入 | 外貨金額あり + 店舗名（英語） |
| 海外駐車場・交通 | 外貨金額あり + PARKING等 |

#### 課対仕入（リバースチャージ）（海外SaaS）

- `debit_tax_category`: `"課対仕入（リバースチャージ）"`
- 国外事業者からの電気通信利用役務の提供（SaaS・クラウドサービス等）に適用
- `memo` に「国外事業者からの役務提供」と記載する

| 対象 | キーワード例 |
|---|---|
| 海外AI SaaS | OpenAI, Perplexity, GENSPARK.AI, VREW, SHENGSHU AI |
| 海外クラウド | n8n CLOUD (PADDLE.NET) |
| その他海外SaaS | PLAUD.AI, 2SHORTAI (LEMSQZY) |

**注意事項**: 海外SaaS事業者が日本で適格請求書発行事業者として登録済みの場合は「課税仕入10%」となる可能性がある。判断が困難な場合は「課対仕入（リバースチャージ）」を適用し、`memo` に「税区分要確認」と記載する

#### その他注意事項

- コンビニ・スーパーは食品購入が主と推定し軽減税率8%を適用する。ただし、明らかに食品以外（雑誌、タバコ等）とわかる場合は10%とする
- 飲食店でのイートインは標準税率10%、テイクアウト・デリバリーは軽減税率8%
- 海外のコンビニ・飲食チェーン（7-ELEVEN、MCDONALD'S等）でも外貨建ての場合は「課税対象外」とする
- 判断が困難な場合は標準税率10%を適用し、`memo` に「税率要確認」と記載する

### 仕訳台帳 20 カラムフォーマット

各取引を以下の20カラムで構造化する。

| # | カラム名 | JSON キー | 説明 |
|---|---------|----------|------|
| A | 取引No | `transaction_no` | 連番（1から開始） |
| B | 取引日 | `date` | YYYY-MM-DD 形式 |
| C | 借方勘定科目 | `debit_account` | 推定ルールに基づく |
| D | 借方補助科目 | `debit_sub_account` | 通常は空文字 |
| E | 借方部門 | `debit_department` | 通常は空文字 |
| F | 借方取引先 | `debit_partner` | 店舗名/利用先 |
| G | 借方税区分 | `debit_tax_category` | 「課税仕入10%」or「課税仕入8%（軽減）」or「課税対象外」or「課対仕入（リバースチャージ）」 |
| H | 借方インボイス | `debit_invoice` | 通常は空文字 |
| I | 借方金額(円) | `debit_amount` | 税込金額（整数） |
| J | 貸方勘定科目 | `credit_account` | 固定: 「未払金」 |
| K | 貸方補助科目 | `credit_sub_account` | 固定: 「アメックス」 |
| L | 貸方部門 | `credit_department` | 通常は空文字 |
| M | 貸方取引先 | `credit_partner` | 通常は空文字 |
| N | 貸方税区分 | `credit_tax_category` | 通常は空文字 |
| O | 貸方インボイス | `credit_invoice` | 通常は空文字 |
| P | 貸方金額(円) | `credit_amount` | 借方金額と同額 |
| Q | 摘要 | `description` | 「{店舗名} {利用内容}」 |
| R | タグ | `tag` | 固定: 「amex」 |
| S | メモ | `memo` | 税率確認メモ等（任意） |
| T | カード利用者 | `cardholder` | PDF記載のカード会員名。複数会員の明細の場合、各取引が属する会員名を記録する |

### 出力 JSON 仕様

以下の構造で JSON を出力する。

```json
{
  "statement_period": "YYYY年M月",
  "card_type": "アメリカン・エキスプレス",
  "generated_at": "ISO 8601 形式（JST）",
  "transactions": [
    {
      "transaction_no": 1,
      "date": "YYYY-MM-DD",
      "debit_account": "勘定科目名",
      "debit_sub_account": "",
      "debit_department": "",
      "debit_partner": "店舗名",
      "debit_tax_category": "課税仕入10%",
      "debit_invoice": "",
      "debit_amount": 0,
      "credit_account": "未払金",
      "credit_sub_account": "アメックス",
      "credit_department": "",
      "credit_partner": "",
      "credit_tax_category": "",
      "credit_invoice": "",
      "credit_amount": 0,
      "description": "店舗名 利用内容",
      "tag": "amex",
      "memo": "",
      "cardholder": "カード会員名",
      "status": "ok"
    }
  ],
  "summary": {
    "total_transactions": 0,
    "total_amount": 0,
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
- `card_type`: 固定値「アメリカン・エキスプレス」
- `generated_at`: 処理実行日時（ISO 8601、JST）

**transactions[] の各要素**:
- 20カラム仕訳データ + `status` フィールド
- `cardholder`: カード会員名（複数会員の明細で利用者を識別）
- `status`: `"ok"`（推定に自信あり）または `"review_required"`（要確認）

**summary**:
- `total_transactions`: 取引総件数
- `total_amount`: 合計金額（円）
- `review_required_count`: `status: "review_required"` の件数
- `accounts_breakdown`: 借方勘定科目ごとの金額集計

### 出力例

```json
{
  "statement_period": "2026年1月",
  "card_type": "アメリカン・エキスプレス",
  "generated_at": "2026-02-19T10:00:00+09:00",
  "transactions": [
    {
      "transaction_no": 1,
      "date": "2026-01-05",
      "debit_account": "消耗品費",
      "debit_sub_account": "",
      "debit_department": "",
      "debit_partner": "Amazon.co.jp",
      "debit_tax_category": "課税仕入10%",
      "debit_invoice": "",
      "debit_amount": 3280,
      "credit_account": "未払金",
      "credit_sub_account": "アメックス",
      "credit_department": "",
      "credit_partner": "",
      "credit_tax_category": "",
      "credit_invoice": "",
      "credit_amount": 3280,
      "description": "Amazon.co.jp 事務用品購入",
      "tag": "amex",
      "memo": "",
      "cardholder": "山田太郎",
      "status": "ok"
    },
    {
      "transaction_no": 2,
      "date": "2026-01-08",
      "debit_account": "会議費",
      "debit_sub_account": "",
      "debit_department": "",
      "debit_partner": "UBER EATS",
      "debit_tax_category": "課税仕入8%（軽減）",
      "debit_invoice": "",
      "debit_amount": 1500,
      "credit_account": "未払金",
      "credit_sub_account": "アメックス",
      "credit_department": "",
      "credit_partner": "",
      "credit_tax_category": "",
      "credit_invoice": "",
      "credit_amount": 1500,
      "description": "UBER EATS フードデリバリー",
      "tag": "amex",
      "memo": "軽減税率対象",
      "cardholder": "山田太郎",
      "status": "ok"
    }
  ],
  "summary": {
    "total_transactions": 2,
    "total_amount": 4780,
    "review_required_count": 0,
    "accounts_breakdown": {
      "消耗品費": 3280,
      "会議費": 1500
    }
  }
}
```

### 処理上の注意事項

1. **金額の扱い**: PDF に記載された税込金額をそのまま使用する。借方金額と貸方金額は必ず一致させる
2. **日付の扱い**: PDF の日付を YYYY-MM-DD 形式に変換する。年が省略されている場合は明細期間から推定する
3. **店舗名の正規化**: PDF に記載された店舗名をそのまま `debit_partner` に設定する（過度な正規化は不要）
4. **返品・キャンセル（逆仕訳）**: 返品・返金・調整によるマイナス金額の取引は、借方と貸方を逆にして正の金額で記録する（逆仕訳）。具体的には、借方を「未払金」（補助科目「アメックス」）、貸方を元の費用勘定科目とし、金額は絶対値を使用する。`memo` に「返品・調整（逆仕訳）」と記載する
5. **外貨取引**: 円換算後の金額を使用する。外貨情報は `memo` に記載する
6. **複数ページ**: PDF が複数ページの場合、全ページの取引を連番で通しナンバリングする
7. **年会費・手数料**: Amex の年会費・手数料は「支払手数料」として処理する
8. **複数カード会員**: 法人カードの場合、PDF に複数会員の取引が含まれる。各会員セクションのヘッダーから会員名を読み取り、`cardholder` に記録する。返品・調整セクションなど会員が特定できない場合は「調整」と記載する

### CSV 出力（オプション）

ユーザーが CSV 形式を希望した場合、以下のヘッダーで出力する:

```csv
取引No,取引日,借方勘定科目,借方補助科目,借方部門,借方取引先,借方税区分,借方インボイス,借方金額(円),貸方勘定科目,貸方補助科目,貸方部門,貸方取引先,貸方税区分,貸方インボイス,貸方金額(円),摘要,タグ,メモ,カード利用者
```

---

## Phase 2 向け参照情報

Phase 2（#137: Rails API 化）では、本ファイルのプロンプトセクション（「## プロンプト」以降）を `AmexStatementProcessorService` から参照する想定。プロンプト部分は独立して読み込み可能な構造としている。
