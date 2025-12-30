# n8n LINE Bot 自動化ワークフロー セットアップガイド

## 📋 目次

- [概要](#概要)
- [アーキテクチャ](#アーキテクチャ)
- [前提条件](#前提条件)
- [セットアップ手順](#セットアップ手順)
- [テスト方法](#テスト方法)
- [トラブルシューティング](#トラブルシューティング)

---

## 概要

LINE公式アカウント経由で以下の機能を自動化するワークフローシステムです：

### 機能1: 友だち追加時の自動ユーザー登録

```
LINE友だち追加
    ↓
既存ユーザー確認
    ↓
新規ユーザー登録（Master_User_Config）
    ↓
ウェルカムメッセージ送信
```

### 機能2: 領収書画像の自動処理

```
LINE画像受信
    ↓
顧客マスター参照（ユーザー振り分け）
    ↓
Google Driveに保存
    ↓
AI-OCR処理（gpt-4o）
    ↓
勘定科目推論・CSV生成
    ↓
Spreadsheet記帳
    ↓
LINE返信（処理完了通知）
```

---

## アーキテクチャ

### ワークフロー構成

親-子ワークフローパターンを採用し、イベントタイプごとに処理を分離しています。

```
┌──────────────────────────────────────────┐
│  line-webhook-router.json                │
│  （親ワークフロー: イベント振り分け）     │
│                                          │
│  Webhook → Switch Event Type             │
└────────┬─────────────────────────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌──────────┐ ┌──────────┐
│ follow   │ │ image    │
│ Execute  │ │ Execute  │
│ Workflow │ │ Workflow │
└────┬─────┘ └────┬─────┘
     │            │
     ▼            ▼
┌───────────────────┐  ┌──────────────────────┐
│ line-follow-      │  │ line-image-          │
│ handler.json      │  │ handler.json         │
│ (Follow処理)       │  │ (画像OCR処理)         │
└───────────────────┘  └──────────────────────┘
```

### ワークフローファイル

| ファイル名 | 役割 | Status |
|-----------|------|--------|
| `line-webhook-router.json` | 親ワークフロー（イベント振り分け） | Active |
| `line-follow-handler.json` | 子ワークフロー（Follow event処理） | Inactive（親から呼び出し） |
| `line-image-handler.json` | 子ワークフロー（画像OCR処理） | Inactive（親から呼び出し） |
| `line-accounting-automation.json` | 旧版の画像処理ワークフロー | Inactive（参考用） |
| `line-user-auto-registration.json` | 旧版のFollow処理ワークフロー | Inactive（参考用） |

---

## 前提条件

### 1. 必要なサービス

- ✅ n8n (Self-hosted: `http://localhost:5678`)
- ✅ LINE Developers アカウント（Messaging API）
- ✅ Google Cloud Platform アカウント（Drive & Sheets API有効化）
- ✅ OpenAI アカウント（gpt-4o使用可能なAPIキー）

### 2. n8n Credentialsの準備

以下の認証情報をn8nに事前登録してください：

#### 2-1. LINE Bot Auth（HTTP Header Auth）

1. n8n Credentials → Create New Credential → HTTP Header Auth
2. 以下を設定：
   - **Credential Name**: `line-bot-auth`
   - **Name**: `authorization`（小文字）
   - **Value**: `Bearer YOUR_CHANNEL_ACCESS_TOKEN`
     - `YOUR_CHANNEL_ACCESS_TOKEN` は LINE Developers Console の Messaging API設定 → Channel access token から取得
3. Save

#### 2-2. Google Sheets OAuth2

1. n8n Credentials → Create New Credential → Google Sheets OAuth2 API
2. 以下を設定：
   - **Credential Name**: `gsheet-oauth`
   - **Auth URI**: `https://accounts.google.com/o/oauth2/auth`
   - **Token URI**: `https://oauth2.googleapis.com/token`
   - **Scope**: `https://www.googleapis.com/auth/spreadsheets`
3. OAuth2 認証フローに従ってGoogleアカウントと連携
4. Save

#### 2-3. Google Drive OAuth2

1. n8n Credentials → Create New Credential → Google Drive OAuth2 API
2. 以下を設定：
   - **Credential Name**: `gdrive-oauth` または `Google Service Account account`
   - **Auth URI**: `https://accounts.google.com/o/oauth2/auth`
   - **Token URI**: `https://oauth2.googleapis.com/token`
   - **Scope**: `https://www.googleapis.com/auth/drive`
3. OAuth2 認証フローに従ってGoogleアカウントと連携
4. Save

**注**: Service Account を使う場合は、JSON Key ファイルをアップロードしてください。

#### 2-4. OpenAI API

1. n8n Credentials → Create New Credential → OpenAI API
2. 以下を設定：
   - **Credential Name**: `openai-api`
   - **API Key**: OpenAI Platform から取得したAPIキー（`sk-proj-...` 形式）
3. Save

**認証情報一覧**:

| Credential名 | 種類 | 用途 | 設定項目 |
|---|---|---|---|
| `line-bot-auth` | HTTP Header Auth | LINE Messaging API | name: `authorization`, value: `Bearer {TOKEN}` |
| `gsheet-oauth` | Google Sheets OAuth2 | スプレッドシート読み書き | OAuth2フロー |
| `gdrive-oauth` | Google Drive OAuth2 | ファイルアップロード | OAuth2フロー または Service Account |
| `openai-api` | OpenAI API | GPT-4o OCR処理 | API Key |

---

## セットアップ手順

### Step 1: Google スプレッドシートの準備

#### 1-1. マスター設定シートの作成

新しいスプレッドシートを作成し、以下の構成で `Master_User_Config` シートを作成します。

**シート名:** `Master_User_Config`

| A: line_user_id | B: customer_name | C: drive_folder_id | D: sheet_id | E: accounting_soft | F: registration_date |
|---|---|---|---|---|---|
| U1234567890abcdef... | 株式会社サンプル | 1A2B3C4D5E6F... | 1xYzAbCdEfGh... | freee | 2025-12-19T10:30:00 |
| U9876543210zyxwvu... | 合同会社テスト | 9Z8Y7X6W5V4U... | 9pQrStUvWxYz... | moneyforward | 2025-12-20T14:15:00 |

**重要**: `F列: registration_date` は友だち追加時に自動的に記録されます（ISO 8601形式）。

**取得方法:**

- **line_user_id**: LINE Developersコンソールで確認、またはWebhookのログから取得
- **drive_folder_id**: Google DriveのフォルダURLから抽出
  - 例: `https://drive.google.com/drive/folders/1A2B3C4D5E6F...` → `1A2B3C4D5E6F...`
- **sheet_id**: スプレッドシートのURLから抽出
  - 例: `https://docs.google.com/spreadsheets/d/1xYzAbCdEfGh.../edit` → `1xYzAbCdEfGh...`

#### 1-2. 顧客別仕訳台帳シートの作成

各顧客用に新しいスプレッドシートを作成し、`仕訳台帳` シートを作成します。

**シート名:** `仕訳台帳`

| A: timestamp | B: date | C: merchant | D: amount | E: debit_account | F: invoice_number | G: drive_link | H: status |
|---|---|---|---|---|---|---|---|
| 2025-11-28T10:30:00 | 2025-11-18 | 株式会社パークジャパン | 1000 | 旅費交通費 | T3011001028695 | https://drive.google.com/... | Review_Required |

**ヘッダー行（1行目）を必ず作成してください。**

### Step 2: n8nワークフローのインポート

**重要**: 以下の順番でインポートしてください（子→親の順）。

1. n8n管理画面にアクセス: `http://localhost:5678`
2. 左メニューから「Workflows」を選択
3. 右上の「Import from File」をクリック
4. **子ワークフローをインポート**:
   - `n8n/workflows/line-follow-handler.json` を選択してインポート
   - `n8n/workflows/line-image-handler.json` を選択してインポート
5. **親ワークフローをインポート**:
   - `n8n/workflows/line-webhook-router.json` を選択してインポート

**注**: 子ワークフローを先にインポートしないと、親ワークフローの Execute Workflow ノードでエラーが発生します。

### Step 3: ワークフロー設定の編集

#### 3-1. line-follow-handler.json の設定

「既存ユーザー確認」ノードと「新規ユーザー登録」ノードで以下を設定：

- **Document ID**: Step 1-1で作成したMaster_User_ConfigスプレッドシートのID
- **Sheet Name**: `Master_User_Config`
- **Credential**: `gsheet-oauth`

#### 3-2. line-image-handler.json の設定

**「顧客マスター参照」ノード**:
- **Document ID**: Master_User_ConfigスプレッドシートのID
- **Sheet Name**: `Master_User_Config`
- **Credential**: `gsheet-oauth`

**「AI-OCR処理（GPT-4o）」ノード**:
- **Model**: `gpt-4o`（Vision対応モデル）
- **Temperature**: `0.2`（一貫性重視）
- **Max Tokens**: `500`
- **Credential**: `openai-api`

**Credentialsの紐付け**:
- 「Get LINE Image」「LINE返信」ノード → `line-bot-auth`
- 「Google Drive Upload」ノード → `gdrive-oauth`
- 「顧客マスター参照」「顧客台帳へ記帳」ノード → `gsheet-oauth`

#### 3-3. line-webhook-router.json の設定

**Execute Workflow ノードの確認**:
- 「Execute Follow Handler」ノード → Workflow ID: `line-follow-handler`
- 「Execute Image Handler」ノード → Workflow ID: `line-image-handler`

**注**: Workflow ID は子ワークフローのファイル名（拡張子なし）と一致している必要があります。

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

**重要**: 親ワークフロー（`line-webhook-router`）のみを有効化してください。

1. `line-webhook-router` ワークフローを開く
2. 右上の「Active」トグルを **ON** に設定
3. 「Save」をクリック

**注**: 子ワークフロー（`line-follow-handler`, `line-image-handler`）は **Inactive のまま** にしてください。親ワークフローから Execute Workflow で呼び出されます。

---

## テスト方法

### 1. 友だち追加テスト（Follow Event）

1. 別のLINEアカウントで公式アカウントを友だち追加
2. 以下を確認：
   - ウェルカムメッセージ「✅ 友だち追加ありがとうございます！」が届くか
   - Master_User_Configに新規行が追加されているか
   - `customer_name`が「未設定」になっているか
   - `registration_date`が記録されているか

### 2. 二重登録防止テスト

1. 同じLINEアカウントで一旦ブロック
2. 再度友だち追加
3. 以下を確認：
   - 「ℹ️ 既に登録済みです」メッセージが届くか
   - Master_User_Configに重複行がないか

### 3. 画像処理テスト（Image Event）

1. 登録済みLINEアカウントで領収書画像を送信
2. 以下を確認：
   - Google Driveに画像が保存されているか
   - スプレッドシート「仕訳台帳」に行が追加されているか
   - LINEに処理完了メッセージが返信されるか

### 4. エラーケーステスト

#### Test 4-1: 未登録ユーザーが画像送信

別のLINEアカウント（`Master_User_Config`に未登録）から画像を送信
→ 「ユーザー登録が確認できませんでした」メッセージが返信されるはず

#### Test 4-2: テキストメッセージ送信

テキストメッセージを送信
→ 無視される（何も起こらない）

### 5. OCR精度テスト

以下のような領収書でテスト：

- ✅ 日付が記載されている
- ✅ インボイス番号（T〜）がある
- ✅ 消費税が明記されている
- ✅ 店舗名が明瞭

**期待される動作:**
- 勘定科目が正しく推論される（駐車場→旅費交通費、など）
- 税区分が正しく判定される（インボイス有無）

---

## トラブルシューティング

### 問題1: 友だち追加してもウェルカムメッセージが届かない

**原因:** 親ワークフローが有効化されていない、または子ワークフローが見つからない

**解決策:**
1. `line-webhook-router` が「Active」になっているか確認
2. `line-follow-handler` がインポートされているか確認
3. n8nの実行ログ（Executions）で `line-webhook-router` のエラーを確認
4. Execute Workflow ノードの Workflow ID が正しいか確認

### 問題2: 「ユーザー登録が確認できませんでした」が常に表示される（画像送信時）

**原因:** `Master_User_Config` のLINE User IDが正しくない

**解決策:**
1. n8nの実行ログ（Executions）を確認
2. `line-webhook-router` の出力から `body.events[0].source.userId` を確認
3. その値を `Master_User_Config` の `line_user_id` 列に追加

### 問題3: 子ワークフローが実行されない

**原因:** Execute Workflow ノードの設定が間違っている、または子ワークフローが存在しない

**解決策:**
1. 親ワークフロー（`line-webhook-router`）を開く
2. Execute Workflow ノードの Workflow ID を確認:
   - `Execute Follow Handler` → `line-follow-handler`
   - `Execute Image Handler` → `line-image-handler`
3. 子ワークフローが n8n にインポートされているか確認
4. 子ワークフローの名前（Name）がファイル名と一致しているか確認

### 問題4: Google Driveにアップロードされない

**原因:** フォルダIDが間違っている、または権限がない

**解決策:**
1. `drive_folder_id` が正しいか確認
2. Google Drive OAuth2の権限スコープに `https://www.googleapis.com/auth/drive` が含まれているか確認
3. n8nのサービスアカウントにフォルダの編集権限を付与

### 問題5: AI-OCRが失敗する

**原因:** OpenAI APIキーが無効、またはgpt-4oの利用制限

**解決策:**
1. OpenAI Credentialsのテスト実行
2. APIキーの残高・利用制限を確認
3. モデル名が `gpt-4o` になっているか確認（`gpt-4-vision-preview` ではなく）

### 問題6: スプレッドシートに記帳されない

**原因:** シートIDが間違っている、またはシート名が一致しない

**解決策:**
1. `sheet_id` が正しいか確認
2. シート名が **完全一致** で `仕訳台帳` になっているか確認（全角・半角注意）
3. ヘッダー行（1行目）が存在するか確認

---

## 📊 データフロー図

```
┌─────────────────────────────────────────────────┐
│                  LINE User                      │
│            (領収書画像を送信)                    │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│          Webhook (LINE Messaging API)           │
│  - message.type = "image" をフィルタ             │
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
│        画像取得 & Drive保存                      │
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
│      データ変換・CSV生成 (Code Node)             │
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

### 拡張機能の実装

1. **勘定科目ナレッジベースの追加**
   - `Master_Account_Mapping` シートを作成
   - 店舗名キーワードと勘定科目のマッピング
   - AI推論の精度向上

2. **CSV自動出力**
   - 月次でCSVファイルを生成してDriveに保存
   - 会計ソフトへの直接インポート

3. **承認フロー**
   - statusが `Review_Required` の項目を確認
   - LINEで承認/却下ボタンを追加

4. **レシートOCR精度向上**
   - 画像前処理（明度調整、回転補正）
   - 複数AIモデルの併用

---

## ライセンス

All rights reserved. © 株式会社 AI.LandBase
