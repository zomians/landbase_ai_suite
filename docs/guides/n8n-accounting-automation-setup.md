# n8n経理自動化ワークフロー セットアップガイド

## 📋 目次

- [概要](#概要)
- [前提条件](#前提条件)
- [セットアップ手順](#セットアップ手順)
- [テスト方法](#テスト方法)
- [トラブルシューティング](#トラブルシューティング)

---

## 概要

このワークフローは、LINE公式アカウント経由で以下の処理を自動化します：

1. **友だち追加時の自動登録**（Follow Event）
2. **領収書画像の自動処理**（Image Event）

### アーキテクチャ（親-子ワークフロー構造）

```
LINE Messaging API (Webhook)
    ↓
┌──────────────────────────────────────────┐
│ 親ワークフロー: Webhook Dispatcher       │
│  - Webhook受信（/line-webhook）          │
│  - イベントタイプ判定                     │
│  - 子ワークフロー呼び出し                 │
└─────────┬────────────┬───────────────────┘
          │            │
   ┌──────┴───┐  ┌────┴──────┐
   │ Follow   │  │  Image    │
   │ Handler  │  │  Handler  │
   └──────────┘  └───────────┘
```

### 処理フロー

#### 1. Follow Event（友だち追加時の自動登録）

```
LINE友だち追加
    ↓
Webhook Dispatcher（親）
    ↓
Follow Handler（子）呼び出し
    ↓
既存ユーザー確認（Master_User_Config）
    ↓
IF 新規ユーザー？
    ↓               ↓
新規              既存
    ↓               ↓
登録（未設定）    スキップ
    ↓               ↓
ウェルカム        登録済み
メッセージ        メッセージ
```

#### 2. Image Event（領収書画像の自動処理）

```
LINE画像受信
    ↓
Webhook Dispatcher（親）
    ↓
Image Handler（子）呼び出し
    ↓
顧客マスター参照（ユーザー振り分け）
    ↓
IF 設定完了？（drive_folder_id & sheet_id）
    ↓               ↓
本登録              仮登録
    ↓               ↓
Google Drive      設定待ち
に保存            メッセージ
    ↓
AI-OCR処理（gpt-4o）
    ↓
勘定科目マスター参照（ナレッジベース）
    ↓
勘定科目判定（優先度：ナレッジベース > AI推論）
    ↓
使用データ更新（信頼度スコア +5、使用回数 +1）
    ↓
仕訳データ生成
    ↓
Spreadsheet記帳
    ↓
LINE返信（処理完了通知）
```

**ファイル:**
- 親ワークフロー: `n8n/workflows/line-webhook-dispatcher.json`
- Follow Handler: `n8n/workflows/line-follow-handler.json`
- Image Handler: `n8n/workflows/line-image-handler.json`
- 学習バッチ: `n8n/workflows/knowledge-base-learning-batch.json`（毎日深夜2時実行）

---

## 前提条件

### 1. 必要なサービス

- ✅ n8n (Self-hosted: `http://localhost:5678`)
- ✅ LINE Developers アカウント（Messaging API）
- ✅ Google Cloud Platform アカウント（Drive & Sheets API有効化）
- ✅ OpenAI アカウント（gpt-4o使用可能なAPIキー）

### 2. n8n Credentialsの準備

以下の認証情報をn8nに事前登録してください：

| Credential名 | 種類 | 用途 |
|---|---|---|
| `line-bot-auth` | HTTP Header Auth | LINE Messaging API |
| `gsheet-oauth` | Google Sheets OAuth2 | スプレッドシート読み書き |
| `gdrive-oauth` | Google Drive OAuth2 | ファイルアップロード |
| `openai-api` | OpenAI API | GPT-4o OCR処理 |

---

## セットアップ手順

### Step 1: Google スプレッドシートの準備

#### 1-1. マスター設定シートの作成

新しいスプレッドシートを作成し、以下の構成で `Master_User_Config` シートを作成します。

**シート名:** `Master_User_Config`

| A: line_user_id | B: customer_name | C: drive_folder_id | D: sheet_id | E: accounting_soft | F: registration_date |
|---|---|---|---|---|---|
| U1234567890abcdef... | 株式会社サンプル | 1A2B3C4D5E6F... | 1xYzAbCdEfGh... | freee | 2025-01-15T10:30:00.000Z |
| U9876543210zyxwvu... | 合同会社テスト | 9Z8Y7X6W5V4U... | 9pQrStUvWxYz... | moneyforward | 2025-01-16T14:20:00.000Z |
| Uabc123def456ghi... | 未設定 | | | freee | 2025-01-17T09:15:00.000Z |

**各列の説明:**

- **line_user_id**: LINE User ID（Follow Eventで自動取得）
- **customer_name**: 顧客名（初期値: "未設定"、管理者が後から更新）
- **drive_folder_id**: Google DriveフォルダID（初期値: 空欄、管理者が後から設定）
- **sheet_id**: 顧客別スプレッドシートID（初期値: 空欄、管理者が後から設定）
- **accounting_soft**: 会計ソフト（初期値: "freee"）
- **registration_date**: 登録日時（ISO 8601形式、自動記録）

**取得方法:**

- **line_user_id**: Follow Eventで自動取得（手動の場合: LINE Developersコンソールで確認、またはWebhookのログから取得）
- **drive_folder_id**: Google DriveのフォルダURLから抽出
  - 例: `https://drive.google.com/drive/folders/1A2B3C4D5E6F...` → `1A2B3C4D5E6F...`
- **sheet_id**: スプレッドシートのURLから抽出
  - 例: `https://docs.google.com/spreadsheets/d/1xYzAbCdEfGh.../edit` → `1xYzAbCdEfGh...`

**重要: 友だち追加時の自動登録**

- Follow Handler（友だち追加イベント）により、以下の初期値で自動登録されます：
  - `line_user_id`: 自動取得
  - `customer_name`: "未設定"
  - `drive_folder_id`: 空欄
  - `sheet_id`: 空欄
  - `accounting_soft`: "freee"
  - `registration_date`: 登録日時（自動）

- 管理者は後から `customer_name`、`drive_folder_id`、`sheet_id` を設定します

**ユーザー状態の定義**

| 状態 | 条件 | 動作 |
|------|------|------|
| **仮登録** | `line_user_id` は存在、`drive_folder_id` または `sheet_id` が空欄 | 領収書画像を送信しても「管理者が設定中です。しばらくお待ちください」メッセージを返す |
| **本登録** | `line_user_id`、`drive_folder_id`、`sheet_id` すべて設定済み | 領収書画像の自動処理が実行される |

**設計の意図:**
- 友だち追加直後は仮登録状態（管理者の設定待ち）
- Image Handlerは早期チェックで無駄な処理（画像取得、OCR）を回避
- ユーザーには適切なメッセージで状況を説明

#### 1-2. 顧客別仕訳台帳シートの作成

各顧客用に新しいスプレッドシートを作成し、`仕訳台帳` シートを作成します。

**シート名:** `仕訳台帳`

```
A: 取引No
B: 取引日
C: 借方勘定科目
D: 借方補助科目
E: 借方部門
F: 借方取引先
G: 借方税区分
H: 借方インボイス
I: 借方金額(円)
J: 貸方勘定科目
K: 貸方補助科目
L: 貸方部門
M: 貸方取引先
N: 貸方税区分
O: 貸方インボイス
P: 貸方金額(円)
Q: 摘要
R: タグ
S: メモ
```

**ヘッダー行（1行目）を必ず作成してください。**

#### 1-3. 勘定科目マスターシートの作成

各顧客用スプレッドシート（Step 1-2で作成したもの）に、`勘定科目マスター` シートを作成します。

**シート名:** `勘定科目マスター`

| A: merchant_keyword | B: description_keyword | C: account_category | D: confidence_score | E: last_used_date | F: usage_count | G: auto_learned | H: notes |
|---|---|---|---|---|---|---|---|
| セブンイレブン | | 消耗品費 | 95 | 2025-01-15 | 28 | false | 手動登録 |
| ローソン | | 消耗品費 | 90 | 2025-01-14 | 15 | false | 手動登録 |
| | 駐車場 | 旅費交通費 | 85 | 2025-01-13 | 10 | true | 自動学習 |
| スターバックス | | 会議費 | 80 | 2025-01-12 | 5 | false | 手動登録 |

**各列の説明:**

- **merchant_keyword**: 店舗名キーワード（部分一致で判定、優先度：高）
- **description_keyword**: 取引内容キーワード（merchant_keywordでマッチしない場合に使用、優先度：中）
- **account_category**: 勘定科目（借方勘定科目として使用）
- **confidence_score**: 信頼度スコア（0〜100、マッチング時に使用、使用の度に+5ずつ増加）
- **last_used_date**: 最終使用日（YYYY-MM-DD形式）
- **usage_count**: 使用回数（マッチングの度に+1）
- **auto_learned**: 自動学習フラグ（true/false、学習バッチで追加された場合はtrue）
- **notes**: メモ（任意）

**ヘッダー行（1行目）を必ず作成してください。**

**初期データの作成:**

最初は空のシート（ヘッダー行のみ）でも構いません。領収書処理を実行するたびに、自動学習バッチ（毎日深夜2時実行）が過去30日分のデータを分析し、頻出パターン（3回以上出現）を自動で追加します。

また、手動で初期データを登録することも可能です。よく使う店舗や取引内容を事前に登録しておくと、初回からマッチング精度が向上します。

### Step 2: n8nワークフローのインポート

**重要: インポート順序**

親ワークフローが子ワークフローを参照するため、必ず以下の順序でインポートしてください：

1. Follow Handler（子）
2. Image Handler（子）
3. Webhook Dispatcher（親）
4. 学習バッチ（オプション）

#### 2-1. Follow Handler（友だち追加処理）のインポート

1. n8n管理画面にアクセス: `http://localhost:5678`
2. 左メニューから「Workflows」を選択
3. 右上の「Import from File」をクリック
4. `n8n/workflows/line-follow-handler.json` を選択
5. インポート完了後、ワークフローが開きます

このワークフローは、友だち追加時に自動的にMaster_User_Configへユーザーを登録します。

#### 2-2. Image Handler（領収書処理）のインポート

1. n8n管理画面で、再度「Import from File」をクリック
2. `n8n/workflows/line-image-handler.json` を選択
3. インポート完了後、ワークフローが開きます

このワークフローは、領収書画像の受信から記帳までの処理を実行します。

**注意:**
- 既存の `line-accounting-automation.json` ワークフローがある場合は、無効化してください
- Image Handlerは既存ワークフローを親-子構造に対応させたものです

#### 2-3. Webhook Dispatcher（親ワークフロー）のインポート

1. n8n管理画面で、再度「Import from File」をクリック
2. `n8n/workflows/line-webhook-dispatcher.json` を選択
3. インポート完了後、ワークフローが開きます

このワークフローは、LINE Messaging APIからのWebhookを受信し、イベントタイプ（follow/message）に応じて適切な子ワークフローを呼び出します。

#### 2-4. 学習バッチワークフローのインポート

1. n8n管理画面で、再度「Import from File」をクリック
2. `n8n/workflows/knowledge-base-learning-batch.json` を選択
3. インポート完了後、ワークフローが開きます

このワークフローは毎日深夜2時（JST）に自動実行され、過去30日分の仕訳データから頻出パターン（3回以上）を抽出し、勘定科目マスターに自動追加します。

### Step 3: ワークフロー設定の編集

#### 3-1. Follow Handler - Master_User_Config のシートID設定

Follow Handlerワークフローを開き、以下のノードを設定：

**「既存ユーザー確認」ノード:**
- **Document ID**: Step 1-1で作成したMaster_User_ConfigスプレッドシートのID
- **Sheet Name**: `Master_User_Config`

**「新規ユーザー登録」ノード:**
- **Document ID**: 同上（Master_User_ConfigスプレッドシートのID）
- **Sheet Name**: `Master_User_Config`

**シートIDの取得方法:**
```
https://docs.google.com/spreadsheets/d/16qhVQNDn_5Y1Ayw_H0ziUw1nu2b70o6IcRn1rr4Pa94/edit
                                         ↑ ここがシートID ↑
```

#### 3-2. Image Handler - Master_User_Config のシートID設定

Image Handlerワークフローを開き、以下のノードを設定：

**「顧客マスター参照」ノード:**
- **Document ID**: Step 1-1で作成したMaster_User_ConfigスプレッドシートのID
- **Sheet Name**: `Master_User_Config`

#### 3-3. Image Handler - OpenAI設定の確認

「AI-OCR処理（GPT-4o）」ノードをクリックし、以下を確認：

- **Model**: `gpt-4o`（Vision対応モデル）
- **Temperature**: `0.2`（一貫性重視）
- **Max Tokens**: `500`

#### 3-4. Credentialsの紐付け

各ワークフローで以下のCredentialsを選択：

**Follow Handler:**
- 「既存ユーザー確認」ノード → `gsheet-oauth`
- 「新規ユーザー登録」ノード → `gsheet-oauth`
- 「LINE返信（新規ユーザー）」ノード → `line-bot-auth`
- 「LINE返信（既存ユーザー）」ノード → `line-bot-auth`

**Image Handler:**
- 「顧客マスター参照」ノード → `gsheet-oauth`
- 「Get LINE Image」ノード → `line-bot-auth`
- 「Google Drive Upload」ノード → `gdrive-oauth`
- 「AI-OCR処理（GPT-4o）」ノード → `openai-api`
- 「顧客台帳へ記帳」ノード → `gsheet-oauth`
- 「LINE返信」ノード → `line-bot-auth`

**Webhook Dispatcher（親）:**
- Credentialsの設定は不要

### Step 4: LINE Messaging API設定

#### 4-1. Webhook URLの設定

1. LINE Developersコンソールにアクセス
2. チャネル設定から「Webhook URL」を編集
3. n8nのWebhook URLを設定:
   ```
   https://your-domain.com/webhook/line-webhook
   ```
   または、開発環境の場合:
   ```
   make ngrok
   ```
   で取得したngrok URLを使用: `https://xxxx.ngrok.io/webhook/line-webhook`

#### 4-2. Webhook送信を有効化

- 「Webhook送信」を **ON** に設定
- 「グループ・複数人トークへの参加を許可する」を **ON** に設定（必要に応じて）

### Step 5: ワークフローの有効化

**重要: 有効化の注意点**

- **親ワークフロー（Webhook Dispatcher）のみ有効化します**
- **子ワークフロー（Follow Handler, Image Handler）は有効化不要です**
  - Execute Workflow Triggerを使用する子ワークフローは、親から呼び出されるため、Activeにする必要はありません
  - 保存するだけでOKです

#### 5-1. 親ワークフロー（Webhook Dispatcher）の有効化

1. `LINE Webhook Dispatcher` ワークフローを開く
2. n8n画面右上の「Active」トグルを **ON** に設定
3. 「Save」をクリック

これで、Follow EventとImage Eventが自動的に処理されます。

#### 5-2. 学習バッチワークフローの有効化

1. `勘定科目ナレッジベース学習バッチ` ワークフローを開く
2. 「全クライアント取得」ノードをクリックし、`Master_User_Config` のシートIDを設定
3. n8n画面右上の「Active」トグルを **ON** に設定
4. 「Save」をクリック

これで、毎日深夜2時に自動的に学習バッチが実行され、勘定科目マスターが更新されます。

---

## テスト方法

### 1. 友だち追加（Follow Event）テスト

#### Test 1-1: 新規ユーザーの友だち追加

1. 新しいLINEアカウントで該当の公式アカウントを友だち追加
2. 以下を確認：
   - ウェルカムメッセージが届くか
     ```
     ✅ 友だち追加ありがとうございます！

     自動登録が完了しました。
     管理者が設定を完了次第、領収書画像を送信できるようになります。

     しばらくお待ちください。
     ```
   - Master_User_Configに新しい行が追加されているか
   - `line_user_id` が自動取得されているか
   - `customer_name` が「未設定」になっているか
   - `registration_date` が記録されているか（ISO 8601形式）

#### Test 1-2: 既存ユーザーの重複登録防止

1. 既に登録済みのLINEアカウントで一旦ブロック
2. 再度友だち追加
3. 以下を確認：
   - 「既に登録済みです」メッセージが届くか
   - Master_User_Configに重複行が追加されていないか

### 2. 領収書処理（Image Event）テスト

#### Test 2-1: 基本動作テスト

1. LINEで該当の公式アカウントを友だち追加（既に追加済みの場合はスキップ）
2. 管理者がMaster_User_Configで以下を設定：
   - `customer_name`: 実際の顧客名
   - `drive_folder_id`: 顧客専用フォルダID
   - `sheet_id`: 顧客専用スプレッドシートID
3. 領収書画像を送信
4. 以下を確認：
   - Google Driveに画像が保存されているか
   - スプレッドシート「仕訳台帳」に行が追加されているか
   - LINEに処理完了メッセージが返信されるか

#### Test 2-2: 仮登録ユーザーの領収書送信（設定未完了）

1. 友だち追加したが、管理者がまだ設定を完了していない状態で領収書画像を送信
   - Master_User_Configに `line_user_id` は登録済み
   - `drive_folder_id` と `sheet_id` が空欄（仮登録状態）
2. 以下を確認：
   - 「管理者が設定中です。しばらくお待ちください」メッセージが返信されるか
   - 画像取得やOCR処理が実行されていないか（早期チェックで処理がスキップされる）

### 3. エラーケーステスト

#### Test 3-1: 画像以外のメッセージ

テキストメッセージを送信
→ 無視される（何も起こらない）

### 4. OCR精度テスト

以下のような領収書でテスト：

- ✅ 日付が記載されている
- ✅ インボイス番号（T〜）がある
- ✅ 消費税が明記されている
- ✅ 店舗名が明瞭

**期待される動作:**
- 勘定科目が正しく推論される（駐車場→旅費交通費、など）
- 税区分が正しく判定される（インボイス有無）

### 5. ナレッジベースマッチングテスト

#### Test 5-1: 店舗名マッチング（優先度：高）

1. 勘定科目マスターに以下を登録：
   ```
   merchant_keyword: セブンイレブン
   account_category: 消耗品費
   confidence_score: 80
   ```
2. セブンイレブンの領収書を送信
3. 以下を確認：
   - 勘定科目が「消耗品費」になっているか
   - LINEメッセージに `[ナレッジベースマッチ]` と表示されるか
   - 勘定科目マスターの `confidence_score` が +5 増加しているか（85になる）
   - `usage_count` が +1 増加しているか
   - `last_used_date` が今日の日付になっているか

#### Test 5-2: 取引内容マッチング（優先度：中）

1. 勘定科目マスターに以下を登録：
   ```
   description_keyword: 駐車場
   account_category: 旅費交通費
   confidence_score: 70
   ```
2. 取引内容に「駐車場」が含まれる領収書を送信（店舗名は未登録）
3. 以下を確認：
   - 勘定科目が「旅費交通費」になっているか
   - LINEメッセージに `[ナレッジベースマッチ]` と表示されるか

#### Test 5-3: AI推論フォールバック（優先度：低）

1. 勘定科目マスターに登録されていない店舗の領収書を送信
2. 以下を確認：
   - 勘定科目がAI推論結果になっているか
   - LINEメッセージに `[AI推論]` と表示されるか
   - 勘定科目マスターは更新されないか

#### Test 5-4: 自動学習バッチ

1. 同じ店舗の領収書を3回以上送信（例：ファミリーマート）
2. 翌日深夜2時以降（または手動でワークフロー実行）
3. 以下を確認：
   - 勘定科目マスターに新しい行が追加されているか
   - `merchant_keyword` が「ファミリーマート」になっているか
   - `account_category` が3回の取引で使用された勘定科目になっているか
   - `confidence_score` が 50（初期値）になっているか
   - `auto_learned` が true になっているか
   - `notes` が「自動学習」になっているか

---

## トラブルシューティング

### 問題1: 友だち追加してもウェルカムメッセージが届かない

**原因1:** Webhook Dispatcherが無効、またはWebhook URLが正しくない

**解決策:**
1. LINE DevelopersコンソールでWebhook URLを確認
   - パスが `/webhook/line-webhook` になっているか
2. n8nの「LINE Webhook Dispatcher」ワークフローがActiveになっているか確認
3. n8nの実行ログ（Executions）を確認
   - Webhook Dispatcherが実行されているか
   - Follow Handlerが呼び出されているか

**原因2:** LINE Bot Credentialsが無効

**解決策:**
1. n8nのCredentials設定で `line-bot-auth` をテスト
2. LINE DevelopersコンソールでChannel Access Tokenを再発行

### 問題2: 重複登録が発生する

**原因:** Follow Handlerの既存ユーザー確認が失敗している

**解決策:**
1. Follow Handlerの「既存ユーザー確認」ノードを確認
2. n8nの実行ログで、Lookupノードの結果を確認
3. `line_user_id` が完全一致しているか確認（前後の空白に注意）

**注意:** 通常、重複登録は発生しません。Follow Handlerは `line_user_id` でLookupを実行し、マッチした場合は「既存ユーザー」として処理します。

### 問題3: スプレッドシートに登録されない（Follow Event）

**原因:** Master_User_ConfigのシートIDが間違っている

**解決策:**
1. Follow Handlerの「新規ユーザー登録」ノードを確認
2. Document IDが正しいスプレッドシートIDになっているか確認
3. Sheet Nameが `Master_User_Config` と完全一致しているか確認（全角・半角注意）

### 問題4: 「管理者が設定中です」が常に表示される（Image Event）

**原因:** `drive_folder_id` または `sheet_id` が未設定（仮登録状態）

**解決策:**
1. Master_User_Configを開き、該当ユーザーの行を確認
2. `drive_folder_id` と `sheet_id` が空欄でないか確認
3. 空欄の場合、以下を設定：
   - `drive_folder_id`: 顧客専用Google DriveフォルダのID
   - `sheet_id`: 顧客専用スプレッドシートのID
4. 設定後、再度領収書画像を送信してテスト

### 問題5: Google Driveにアップロードされない

**原因:** フォルダIDが間違っている、または権限がない

**解決策:**
1. `drive_folder_id` が正しいか確認
2. Google Drive OAuth2の権限スコープに `https://www.googleapis.com/auth/drive` が含まれているか確認
3. n8nのサービスアカウントにフォルダの編集権限を付与

### 問題6: AI-OCRが失敗する

**原因:** OpenAI APIキーが無効、またはgpt-4oの利用制限

**解決策:**
1. OpenAI Credentialsのテスト実行
2. APIキーの残高・利用制限を確認
3. モデル名が `gpt-4o` になっているか確認（`gpt-4-vision-preview` ではなく）

### 問題7: スプレッドシートに記帳されない

**原因:** シートIDが間違っている、またはシート名が一致しない

**解決策:**
1. `sheet_id` が正しいか確認
2. シート名が **完全一致** で `仕訳台帳` になっているか確認（全角・半角注意）
3. ヘッダー行（1行目）が存在するか確認

---

## 📊 データフロー図

### Follow Event（友だち追加）処理フロー

```
┌─────────────────────────────────────────────────┐
│                  LINE User                      │
│              (友だち追加)                        │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│      Webhook Dispatcher (親ワークフロー)        │
│  - Webhook受信 (type = "follow")                │
│  - IF Follow Event → Follow Handler呼び出し     │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│        Follow Handler (子ワークフロー)          │
│  - 既存ユーザー確認 (Master_User_Config)        │
│  - IF 新規ユーザー？                            │
└────────────────┬────────────────────────────────┘
                 │
         ┌───────┴───────┐
         ▼               ▼
┌─────────────┐   ┌─────────────┐
│  新規登録   │   │  既存ユーザー│
│  - 行追加   │   │  - スキップ  │
│  - 未設定   │   │             │
└──────┬──────┘   └──────┬──────┘
       │                 │
       ▼                 ▼
┌─────────────┐   ┌─────────────┐
│ ウェルカム  │   │ 登録済み    │
│ メッセージ  │   │ メッセージ  │
└─────────────┘   └─────────────┘
```

### Image Event（領収書画像）処理フロー

```
┌─────────────────────────────────────────────────┐
│                  LINE User                      │
│            (領収書画像を送信)                    │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│      Webhook Dispatcher (親ワークフロー)        │
│  - Webhook受信 (type = "message", message.type = "image") │
│  - IF Image Event → Image Handler呼び出し       │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│        Image Handler (子ワークフロー)           │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│      顧客マスター参照 (Google Sheets)            │
│  - line_user_id で検索                          │
│  - drive_folder_id, sheet_id, accounting_soft  │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│   IF 設定完了？（drive_folder_id & sheet_id）   │
└────────┬───────────────────────┬────────────────┘
         │                       │
    本登録（設定済み）        仮登録（未設定）
         │                       │
         ▼                       ▼
┌─────────────────┐   ┌─────────────────────────┐
│ 画像取得 & Drive│   │ LINE返信（設定待ち）     │
│ 保存            │   │ 「管理者が設定中です」   │
│                 │   └─────────────────────────┘
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│  - ファイル名: YYYYMMDD_HHmmss_{user_id}.jpg    │
│  - 顧客別フォルダに保存                          │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│          AI-OCR処理 (GPT-4o Vision)             │
│  - 日付、店舗名、金額、インボイス番号抽出        │
│  - 勘定科目の自動推論                            │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│      勘定科目マスター取得 (Google Sheets)        │
│  - 顧客別の勘定科目ナレッジベース読み込み        │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│   勘定科目判定（ナレッジベース優先マッチング）   │
│  - 店舗名での完全一致（優先度：高）              │
│  - 取引内容での部分一致（優先度：中）            │
│  - AI推論結果をフォールバック（優先度：低）      │
│  - 信頼度スコア、使用回数、最終使用日を更新      │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│      データ変換・仕訳データ生成 (Code Node)      │
│  - 税区分判定（インボイス有無）                  │
│  - 会計ソフト別フォーマット変換                  │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│      顧客台帳へ記帳 (Google Sheets)              │
│  - 仕訳台帳シートに行追加                        │
│  - status: Review_Required                      │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│          LINE返信（処理完了通知）                │
│  - 日付、金額、科目、証憑URLを通知               │
└─────────────────────────────────────────────────┘
```

---

## 📌 次のステップ

### 実装済み機能

1. **✅ 勘定科目ナレッジベースの追加（実装済み）**
   - `勘定科目マスター` シートによる店舗×科目マッピング
   - 優先度付きマッチングロジック（店舗名 > 取引内容 > AI推論）
   - 自動学習バッチによる頻出パターン抽出（毎日深夜2時実行）
   - 信頼度スコアの自動更新（使用の度に+5、最大100）

2. **✅ LINE友だち追加時の自動登録（実装済み）**
   - 親-子ワークフロー構造への移行
   - Follow Event処理による自動ユーザー登録
   - 重複登録防止機能
   - ウェルカムメッセージ自動送信

### 今後の拡張機能

1. **管理者通知機能**
   - 新規ユーザー登録時にMattermostへ通知
   - 「未設定」ユーザーの定期レポート（週次）
   - 未設定ユーザー数のダッシュボード表示

2. **Unfollowイベント処理**
   - 新しい子ワークフロー `line-unfollow-handler.json` を追加
   - Master_User_Configから削除（または無効化フラグ）

3. **Postbackイベント処理**
   - 新しい子ワークフロー `line-postback-handler.json` を追加
   - リッチメニューのボタン操作を処理

4. **CSV自動出力**
   - 月次でCSVファイルを生成してDriveに保存
   - 会計ソフトへの直接インポート

5. **承認フロー**
   - statusが `Review_Required` の項目を確認
   - LINEで承認/却下ボタンを追加

6. **レシートOCR精度向上**
   - 画像前処理（明度調整、回転補正）
   - 複数AIモデルの併用

---

## ライセンス

All rights reserved. © 株式会社 AI.LandBase
