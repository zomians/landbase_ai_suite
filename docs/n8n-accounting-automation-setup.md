# n8n経理自動化ワークフロー セットアップガイド

## 📋 目次

- [概要](#概要)
- [前提条件](#前提条件)
- [セットアップ手順](#セットアップ手順)
- [テスト方法](#テスト方法)
- [トラブルシューティング](#トラブルシューティング)

---

## 概要

このワークフローは、LINE公式アカウント経由で領収書画像を受け取り、以下の処理を自動化します：

```
LINE画像受信
    ↓
顧客マスター参照（ユーザー振り分け）
    ↓
Google Driveに保存
    ↓
AI-OCR処理（gpt-4o）
    ↓
勘定科目推論・仕訳データ生成
    ↓
Spreadsheet記帳
    ↓
LINE返信（処理完了通知）
```

**ファイル:** `n8n/workflows/line-accounting-automation.json`

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

| A: line_user_id | B: customer_name | C: drive_folder_id | D: sheet_id | E: accounting_soft |
|---|---|---|---|---|
| U1234567890abcdef... | 株式会社サンプル | 1A2B3C4D5E6F... | 1xYzAbCdEfGh... | freee |
| U9876543210zyxwvu... | 合同会社テスト | 9Z8Y7X6W5V4U... | 9pQrStUvWxYz... | moneyforward |

**取得方法:**

- **line_user_id**: LINE Developersコンソールで確認、またはWebhookのログから取得
- **drive_folder_id**: Google DriveのフォルダURLから抽出
  - 例: `https://drive.google.com/drive/folders/1A2B3C4D5E6F...` → `1A2B3C4D5E6F...`
- **sheet_id**: スプレッドシートのURLから抽出
  - 例: `https://docs.google.com/spreadsheets/d/1xYzAbCdEfGh.../edit` → `1xYzAbCdEfGh...`

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

### Step 2: n8nワークフローのインポート

1. n8n管理画面にアクセス: `http://localhost:5678`
2. 左メニューから「Workflows」を選択
3. 右上の「Import from File」をクリック
4. `n8n/workflows/line-accounting-automation.json` を選択
5. インポート完了後、ワークフローが開きます

### Step 3: ワークフロー設定の編集

#### 3-1. Master_User_Config のシートID設定

「顧客マスター参照」ノードをクリックし、以下を設定：

- **Document ID**: Step 1-1で作成したスプレッドシートのID
- **Sheet Name**: `Master_User_Config`

#### 3-2. OpenAI設定の確認

「AI-OCR処理（GPT-4o）」ノードをクリックし、以下を確認：

- **Model**: `gpt-4o`（Vision対応モデル）
- **Temperature**: `0.2`（一貫性重視）
- **Max Tokens**: `500`

#### 3-3. Credentialsの紐付け

各ノードで以下のCredentialsを選択：

- 「Get LINE Image」「LINE返信」ノード → `line-bot-auth`
- 「Google Drive Upload」ノード → `gdrive-oauth`
- 「顧客マスター参照」「顧客台帳へ記帳」ノード → `gsheet-oauth`
- 「AI-OCR処理（GPT-4o）」ノード → `openai-api`

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

1. n8n画面右上の「Active」トグルを **ON** に設定
2. 「Save」をクリック

---

## テスト方法

### 1. 基本動作テスト

1. LINEで該当の公式アカウントを友だち追加
2. 領収書画像を送信
3. 以下を確認：
   - Google Driveに画像が保存されているか
   - スプレッドシート「仕訳台帳」に行が追加されているか
   - LINEに処理完了メッセージが返信されるか

### 2. エラーケーステスト

#### Test 2-1: 未登録ユーザー

別のLINEアカウント（`Master_User_Config`に未登録）から画像を送信
→ 「ユーザー登録が確認できませんでした」メッセージが返信されるはず

#### Test 2-2: 画像以外のメッセージ

テキストメッセージを送信
→ 無視される（何も起こらない）

### 3. OCR精度テスト

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

### 問題1: 「ユーザー登録が確認できませんでした」が常に表示される

**原因:** `Master_User_Config` のLINE User IDが正しくない

**解決策:**
1. n8nの実行ログ（Executions）を確認
2. Webhookノードの出力から `body.events[0].source.userId` を確認
3. その値を `Master_User_Config` の `line_user_id` 列に追加

### 問題2: Google Driveにアップロードされない

**原因:** フォルダIDが間違っている、または権限がない

**解決策:**
1. `drive_folder_id` が正しいか確認
2. Google Drive OAuth2の権限スコープに `https://www.googleapis.com/auth/drive` が含まれているか確認
3. n8nのサービスアカウントにフォルダの編集権限を付与

### 問題3: AI-OCRが失敗する

**原因:** OpenAI APIキーが無効、またはgpt-4oの利用制限

**解決策:**
1. OpenAI Credentialsのテスト実行
2. APIキーの残高・利用制限を確認
3. モデル名が `gpt-4o` になっているか確認（`gpt-4-vision-preview` ではなく）

### 問題4: スプレッドシートに記帳されない

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
