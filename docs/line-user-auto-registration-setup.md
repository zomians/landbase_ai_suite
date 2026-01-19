# LINE ユーザー自動登録機能 セットアップガイド

## 📋 概要

LINE友だち追加だけで、自動的に`Master_User_Config`に登録される機能です。

### 主な機能

- ✅ **自動ユーザー登録**: Follow Eventを検知して自動登録
- ✅ **重複登録防止**: 既存ユーザーの二重登録を防止
- ✅ **登録日時記録**: registration_dateを自動記録
- ✅ **環境変数対応**: スプレッドシートIDを.env.localで管理

### 仕組み

```
ユーザー: LINE友だち追加
    ↓
n8n: Follow Event受信 → userIdを取得
    ↓
既存ユーザー確認（Master_User_Config検索）
    ↓
  ┌─────┴─────┐
新規          既存
  ↓             ↓
登録実行      スキップ
  ↓             ↓
ウェルカム    既存通知
メッセージ    メッセージ
    ↓
管理者: スプレッドシートで顧客情報を設定
```

---

## 🚀 セットアップ手順

### Step 1: 環境変数の設定

`.env.local` に以下の環境変数を設定します（既にissue#64で追加済みの場合はスキップ）:

```bash
# LINE Accounting Workflow
LINE_ACCOUNTING_SHEET_ID=your_google_sheet_id_here
```

**スプレッドシートIDの取得方法:**
1. Google Sheetsを開く
2. URLから取得: `https://docs.google.com/spreadsheets/d/{SHEET_ID}/edit`
3. `{SHEET_ID}` 部分をコピーして設定

### Step 2: Master_User_Configに列を追加

既存のスプレッドシートに `F列: registration_date` を追加します。

**更新後のスキーマ:**

| A: line_user_id | B: customer_name | C: drive_folder_id | D: sheet_id | E: accounting_soft | F: registration_date |
|---|---|---|---|---|---|
| Uxxx... | 未設定 | | | freee | 2025-12-19T10:30:00 |

### Step 3: n8nワークフローのインポート

1. n8n管理画面にアクセス: `http://localhost:5678`
2. 左メニューから「Workflows」を選択
3. 右上の「Import from File」をクリック
4. `n8n/workflows/line-user-auto-registration.json` を選択
5. インポート完了

### Step 4: n8nへの環境変数設定

n8nコンテナに環境変数を設定します:

```bash
# n8nコンテナを再起動して環境変数を反映
make down && make up
```

**注意:** n8nは`.env.local`の環境変数を自動的に読み込みます。`LINE_ACCOUNTING_SHEET_ID`が正しく設定されていることを確認してください。

### Step 5: ワークフロー設定の確認

ワークフローをインポート後、以下のノードが正しく設定されていることを確認します:

#### 5-1. 「既存ユーザー確認」ノード
- **Document ID**: `{{ $env.LINE_ACCOUNTING_SHEET_ID }}` （環境変数から自動取得）
- **Sheet Name**: `Master_User_Config`
- **Credential**: `gsheet-oauth`
- **Lookup Column**: `line_user_id`
- **Continue on Fail**: 有効

#### 5-2. 「新規ユーザー登録」ノード
- **Document ID**: `{{ $env.LINE_ACCOUNTING_SHEET_ID }}` （環境変数から自動取得）
- **Sheet Name**: `Master_User_Config`
- **Credential**: `gsheet-oauth`
- **Columns**: line_user_id, customer_name, drive_folder_id, sheet_id, accounting_soft, registration_date

#### 5-3. 「LINE返信（新規）」「LINE返信（既存）」ノード
- **Authentication**: HTTP Header Auth
- **Credential**: `line-bot-auth`
- **Method**: POST（Push API使用）

### Step 6: Webhook URLの確認

**重要:** 既存の領収書処理ワークフローと同じWebhook URL (`line-webhook`) を使用します。

- 既存ワークフロー: `events[0].type = "message"` をフィルタ
- 新ワークフロー: `events[0].type = "follow"` をフィルタ

**競合しないため、LINE Developers側の設定変更は不要です。**

### Step 5: ワークフローの有効化

1. ワークフロー画面右上の「Active」トグルを **ON** に設定
2. 「Save」をクリック

---

## 💡 使い方

### ユーザー側の操作

1. LINE公式アカウントを友だち追加
2. 自動的にウェルカムメッセージが届く
3. 管理者からの連絡を待つ

**ウェルカムメッセージの内容:**
```
✅ 友だち追加ありがとうございます！

登録が完了しました。
管理者が設定を完了次第、領収書画像を送信できるようになります。

LINE User ID:
Uxxx...
```

### 管理者側の操作

1. 新規友だち追加を確認（LINEアプリの通知で分かる）
2. Master_User_Configスプレッドシートを開く
3. `customer_name: "未設定"` の行を探す
4. 以下の情報を設定：
   - **B列（customer_name）**: 顧客名を入力
   - **C列（drive_folder_id）**: Google DriveフォルダのIDを入力
   - **D列（sheet_id）**: 仕訳台帳スプレッドシートのIDを入力
   - **E列（accounting_soft）**: `freee` または `moneyforward`（デフォルトはfreee）
5. 保存
6. ユーザーに「設定完了しました。領収書を送信してください」と連絡

---

## 🔄 運用フロー

```
                ┌────────────────────────────────┐
                │  1. ユーザーがLINE友だち追加   │
                └───────────┬────────────────────┘
                            │
                            ▼
                ┌────────────────────────────────┐
                │  2. n8n: Follow Event受信      │
                │     - userId取得               │
                │     - 既存ユーザー確認(Lookup) │
                └───────────┬────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
          [新規ユーザー]            [既存ユーザー]
                │                       │
                ▼                       ▼
    ┌──────────────────────┐  ┌──────────────────────┐
    │  3-A. 登録実行       │  │  3-B. スキップ       │
    │  - line_user_id      │  │  - 重複防止          │
    │  - customer_name:    │  │                      │
    │    "未設定"          │  │                      │
    │  - registration_date │  │                      │
    └──────────┬───────────┘  └──────────┬───────────┘
               │                         │
               ▼                         ▼
    ┌──────────────────────┐  ┌──────────────────────┐
    │  4-A. ウェルカム     │  │  4-B. 既存通知       │
    │  メッセージ送信      │  │  メッセージ送信      │
    └──────────┬───────────┘  └──────────────────────┘
               │
               ▼
    ┌──────────────────────────────────────┐
    │  5. 管理者がスプレッドシートで設定   │
    │     - 顧客名                          │
    │     - DriveフォルダID                 │
    │     - 仕訳台帳シートID                │
    └──────────┬───────────────────────────┘
               │
               ▼
    ┌──────────────────────────────────────┐
    │  6. ユーザーに連絡                    │
    │  「設定完了。領収書を送信可能です」   │
    └──────────────────────────────────────┘
```

---

## ⚙️ デフォルト設定値

新規ユーザー登録時のデフォルト値：

| 列名 | デフォルト値 | 説明 |
|---|---|---|
| line_user_id | 自動取得 | LINEから自動取得 |
| customer_name | "未設定" | 管理者が後で設定 |
| drive_folder_id | 空欄 | 管理者が後で設定 |
| sheet_id | 空欄 | 管理者が後で設定 |
| accounting_soft | "freee" | デフォルトはfreee |
| registration_date | 現在時刻 | 登録日時（自動） |

---

## 🐛 トラブルシューティング

### 問題1: 環境変数が読み込まれない

**原因:** n8nコンテナが`.env.local`を読み込んでいない

**解決策:**
1. `.env.local`に`LINE_ACCOUNTING_SHEET_ID`が設定されているか確認
2. n8nコンテナを再起動: `make down && make up`
3. n8nのExecutionログで`$env.LINE_ACCOUNTING_SHEET_ID`の値を確認
4. ワークフローの「既存ユーザー確認」ノードでDocument IDが正しく展開されているか確認

### 問題2: 友だち追加してもウェルカムメッセージが届かない

**原因:** ワークフローがActiveになっていない、またはWebhook URLが正しくない

**解決策:**
1. n8nでワークフローが「Active」になっているか確認
2. LINE DevelopersのWebhook URLが正しいか確認（既存ワークフローと同じURL）
3. ngrokが起動しているか確認（開発環境の場合）
4. n8nの実行ログ（Executions）でエラーを確認

### 問題3: ウェルカムメッセージは届いたが、スプレッドシートに追加されていない

**原因:** Google Sheets Credentialの権限不足、または環境変数が正しくない

**解決策:**
1. n8nの実行ログ（Executions）でエラーを確認
2. `gsheet-oauth`の権限を再確認（書き込み権限必要）
3. `.env.local`の`LINE_ACCOUNTING_SHEET_ID`が正しいか確認
4. シート名が完全一致で `Master_User_Config` になっているか確認

### 問題4: 既に登録済みのユーザーが再度追加される（重複登録）

**原因:** 「既存ユーザー確認」ノードが正しく動作していない

**解決策:**
1. 「既存ユーザー確認」ノードの設定を確認
2. Lookup Column が `line_user_id` になっているか確認
3. Lookup Value が正しいExpression (`={{ $('Webhook').item.json.body.events[0].source.userId }}`) か確認
4. Continue on Fail が有効になっているか確認
5. n8nのExecution Logで「IF 新規ユーザー」ノードの判定結果を確認

### 問題5: 既存の領収書処理ワークフローが動かなくなった

**原因:** Webhook URLの競合（可能性は低い）

**解決策:**
1. 既存ワークフローのIFノードで `message.type = "image"` のフィルタが正しいか確認
2. 新規ワークフローのIFノードで `events[0].type = "follow"` のフィルタが正しいか確認
3. 両ワークフローが「Active」になっているか確認

---

## ✅ メリット

- ✅ 実装がシンプル（ワークフロー1つ）
- ✅ ユーザーは友だち追加するだけ
- ✅ 追加の画面・システム不要
- ✅ 既存ワークフローとの統合が簡単
- ✅ メンテナンスコストほぼゼロ

## ⚠️ デメリットと対策

### デメリット1: 誰でも登録できる

**対策:** 
- 後から削除可能（スプレッドシートの行を削除）
- LINE公式アカウントの友だち追加設定を制限
- 定期的にスプレッドシートを確認

### デメリット2: 管理者への通知なし

**対策（今後の改善）:**
- Slackやメールで通知機能を追加
- 定期的に「未設定」ユーザーをチェックするスクリプト

---

## 📈 今後の改善案

### Phase 1: 管理者通知の追加

新規登録時にSlackやメールで通知：

```json
{
  "name": "Slack通知",
  "type": "n8n-nodes-base.slack",
  "parameters": {
    "channel": "#経理bot通知",
    "text": "新規ユーザーが登録されました\\nLINE ID: {{ $('Webhook').item.json.body.events[0].source.userId }}"
  }
}
```

### Phase 2: 自動リソース作成

登録時に自動的にGoogle DriveフォルダとSpreadsheetを作成し、IDを自動設定。

### Phase 3: 対話式登録

友だち追加後、ボットが「会社名を教えてください」と質問し、`customer_name`を自動入力。

---

## テスト方法

### 1. 基本動作テスト

1. 別のLINEアカウントで友だち追加
2. ウェルカムメッセージが届くことを確認
3. Master_User_Configに行が追加されていることを確認
4. `customer_name`が「未設定」になっていることを確認

### 2. 二重登録防止テスト（重要）

**手順:**
1. 既に登録済みのLINEアカウントで一旦ブロック
2. 再度友だち追加
3. 「既に登録済みです」メッセージが届くことを確認
4. Master_User_Configに重複行がないことを確認
5. n8nのExecution Logで「既存ユーザー確認」→「IF 新規ユーザー」（false分岐）→「LINE返信（既存）」の流れを確認

**期待結果:**
- ✅ 「既に登録済みです」メッセージが届く
- ✅ スプレッドシートに重複行が追加されない
- ✅ 既存のユーザー情報が保持される

### 3. 既存ワークフローとの共存テスト

1. 領収書画像を送信
2. 既存の処理フローが正常に動作することを確認
3. Follow Eventと競合していないことを確認

---

## ライセンス

All rights reserved. © 株式会社 AI.LandBase
