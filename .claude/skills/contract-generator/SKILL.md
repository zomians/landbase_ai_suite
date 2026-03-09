---
name: contract-generator
description: 月額報酬・レベニューシェア業務委託契約書HTMLを生成します
---

# 業務委託契約書HTML生成スキル

月額固定報酬とレベニューシェア条項を含む業務委託契約書をHTMLで自動生成します。ブラウザの印刷機能でPDF化する運用です。

## 使い方

```
/contract-generator <クライアント名> <契約開始日> [オプション]
```

**引数**:
- `<クライアント名>` (必須): 委託者（甲）の正式名称（例: 株式会社サンプル）
- `<契約開始日>` (必須): 契約開始日（例: 2026-04-01）
- 報酬条件・その他詳細はインタラクティブに確認する

## 実行手順

### Step 1: 契約情報の収集

ユーザーから以下の情報を収集する。不足があれば質問して確認する。

#### 甲（委託者）情報

| 項目 | 必須 | 説明 |
|------|:----:|------|
| 会社名（甲） | Yes | 委託者の正式名称 |
| 代表者名（甲） | Yes | 代表者または担当者名 |
| 住所（甲） | Yes | 委託者の住所 |
| 契約開始日 | Yes | 契約の効力発生日 |

#### 月額報酬

| 項目 | 必須 | 説明 |
|------|:----:|------|
| 月額報酬額 | Yes | 税抜き金額（例: 200,000円） |
| 消費税扱い | Yes | 「外税（別途10%）」or「内税（税込）」 |
| 支払期日 | Yes | 例: 毎月末日、翌月25日 |
| 支払方法 | Yes | 例: 銀行振込（振込先口座を記載） |

#### レベニューシェア（オプション）

| 項目 | 必須 | 説明 |
|------|:----:|------|
| レベニューシェアの有無 | Yes | あり / なし |
| 対象売上の定義 | No | 「総売上」or「純売上（返金・手数料控除後）」 |
| シェア率 | No | 例: 売上の 10% |
| 計算・支払サイクル | No | 「月次」or「四半期」 |
| 最低保証額 | No | 例: 月額 50,000円（省略可） |
| 上限額 | No | 例: 月額 500,000円（省略可） |

### Step 2: 契約書番号の採番

契約書番号は `CTR-YYYYMM-NNNN` 形式で採番する。

1. `docs/templates/contract/` ディレクトリ内の既存HTMLファイルを Glob で検索する
2. ファイル名から最新の契約書番号を特定する
3. 同月内で連番をインクリメントする（初回は `0001`）

例: `CTR-202604-0001`, `CTR-202604-0002`

### Step 3: HTMLファイルの生成

以下の構成・デザインで業務委託契約書HTMLを生成する。

#### 乙（受託者）固定情報

```
株式会社AI.LandBase
代表取締役　末永 壽蔵
〒905-0412 沖縄県国頭郡今帰仁村湧川852-2
```

#### HTMLの基本構成

```html
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>業務委託契約書 - CTR-YYYYMM-NNNN</title>
  <style>
    /* 印刷・画面共通 */
    body { font-family: "Hiragino Kaku Gothic Pro", "Yu Gothic", sans-serif; font-size: 10.5pt; color: #222; margin: 0; padding: 0; }
    .page { width: 210mm; min-height: 297mm; margin: 0 auto; padding: 20mm 25mm; box-sizing: border-box; }
    h1 { font-size: 18pt; text-align: center; margin-bottom: 8mm; }
    .meta { text-align: right; margin-bottom: 8mm; font-size: 9pt; color: #555; }
    .parties { display: flex; justify-content: space-between; margin-bottom: 8mm; }
    .party-block { width: 48%; }
    .party-block h3 { font-size: 10pt; border-bottom: 1px solid #333; padding-bottom: 2mm; margin-bottom: 2mm; }
    article { margin-bottom: 6mm; }
    article h2 { font-size: 11pt; border-left: 3px solid #333; padding-left: 3mm; margin-bottom: 2mm; }
    article p, article ul, article ol { margin: 1mm 0 1mm 4mm; line-height: 1.8; }
    .signature { margin-top: 15mm; display: flex; justify-content: space-between; }
    .sig-block { width: 45%; border-top: 1px solid #333; padding-top: 3mm; text-align: center; font-size: 9pt; }
    /* 印刷設定 */
    @media print {
      body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      .page { padding: 15mm 20mm; }
      @page { size: A4; margin: 0; }
    }
  </style>
</head>
<body>
  <div class="page">
    ...
  </div>
</body>
</html>
```

#### 生成する条項（全10条）

以下の条項をすべて含む契約書本文を生成する。

**第1条　業務内容**
- ユーザーから業務内容の説明を収集し記載する（省略時は「甲が指定するAI活用・システム開発支援業務」とする）

**第2条　契約期間**
- 契約期間: 契約締結日から1か月間
- 期間満了の1か月前までに甲乙いずれからも書面による解約の申し入れがない場合、同一条件でさらに1か月間自動更新する（以降も同様）

**第3条　月額報酬・支払条件**
- 月額報酬額（消費税扱いを明記）
- 支払期日・支払方法

**第4条　レベニューシェア**（レベニューシェアありの場合のみ生成）
- 対象売上の定義
- シェア率
- 計算・支払サイクル
- 最低保証額・上限額（設定がある場合のみ）

**第5条　知的財産権**
- 成果物のうち、乙の技術・知見・知識に基づく部分の権利は乙に帰属する
- 甲は、当該部分を乙の事前書面承諾なしに無断転載・第三者への譲渡・改造・改変することはできない

**第6条　秘密保持**
- 甲乙は、本契約の履行において知り得た相手方の業務上の秘密を第三者に開示・漏洩してはならない
- 本条の義務は契約終了後も3年間存続する

**第7条　再委託**
- 乙は、甲の事前書面承諾を得た場合に限り、業務の全部または一部を第三者に再委託できる

**第8条　損害賠償**
- 賠償範囲: 相手方の責に帰すべき事由により生じた実質的損害に限る（間接損害・逸失利益・特別損害は含まない）
- 賠償上限: 損害発生時点における直近1か月分の月額報酬相当額

**第9条　契約解除**
- 甲または乙は、相手方が本契約に違反し、相当期間を定めた催告後も是正されない場合、本契約を解除できる
- 倒産・破産・業務停止等の場合は催告なしに即時解除できる

**第10条　準拠法・管轄裁判所**
- 本契約は日本法に準拠する
- 本契約に関する紛争は、那覇地方裁判所または東京地方裁判所を第一審の専属的合意管轄裁判所とする

#### 署名欄

契約書末尾に甲乙の署名欄を生成する:

```
本契約の成立を証するため、本書2通を作成し、甲乙各1通を保有する。

　　　　　　　　　　　　　　　　　　　　YYYY年MM月DD日

甲（委託者）                    乙（受託者）
住所：                          住所：〒905-0412 沖縄県国頭郡今帰仁村湧川852-2
会社名：                        会社名：株式会社AI.LandBase
代表者：　　　　　　印           代表者：末永 壽蔵　　　印
```

### Step 4: ファイルの保存

1. 生成したHTMLを `docs/templates/contract/CTR-YYYYMM-NNNN.html` として Write ツールで保存する
2. ユーザーに以下を報告する:
   - 出力ファイルパス
   - 契約書番号
   - 委託者（甲）
   - 契約開始日
   - 月額報酬（消費税扱い）
   - レベニューシェア条件（設定がある場合）
3. 「ブラウザで開いて印刷/PDF保存してください」と案内する
