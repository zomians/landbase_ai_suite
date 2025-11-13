# LINE Bot 統合

## 概要

LINE Bot と n8n を連携して、LINE グループに投稿された画像を自動的に Google Drive の `inbox` フォルダに保存するワークフローです。

## アーキテクチャ

```
[LINE Group] → [LINE Bot] → [ngrok] → [ローカルn8n] → [Google Drive]
                             Webhook
```

---

## セットアップ手順

### 1. LINE Bot 作成

**LINE Developers Console での設定:**

```bash
# 1. LINE Developers Console にアクセス
https://developers.line.biz/console/

# 2. 新しいプロバイダー作成

# 3. Messaging API チャネル作成

# 4. 以下の情報を取得:
#    - Channel Secret
#    - Channel Access Token (Long-lived)

# 5. 以下の設定を ON にする:
#    - Webhook送信: ON
#    - グループトーク参加: ON
```

### 2. 環境変数設定

`.env.local` に LINE Bot の認証情報を設定:

```bash
# .env.local.example をコピー
cp .env.local.example .env.local

# .env.local を編集
LINE_CHANNEL_SECRET=your_actual_channel_secret
LINE_CHANNEL_ACCESS_TOKEN=your_actual_channel_access_token
```

設定状況を確認:

```bash
make line-bot-info
```

### 3. ngrok で n8n を公開

ローカルの n8n を外部から Webhook 受信できるように公開:

```bash
# ngrok のインストール (未インストールの場合)
brew install ngrok

# n8n を公開
make ngrok

# 出力例:
# Forwarding https://xxxx-xxxx-xxxx.ngrok-free.app -> http://localhost:5678
```

### 4. LINE Webhook URL 設定

LINE Developers Console で Webhook URL を設定:

```
https://<ngrok-url>/webhook/line-webhook
```

**確認方法:**

```bash
# Webhook 接続テスト
make line-bot-test
```

### 5. Google Drive 認証設定

**n8n UI で Google Drive Credential を作成:**

1. n8n にアクセス: http://localhost:5678
2. Credentials → New Credential → Google Drive OAuth2 API
3. OAuth 認証フロー実行
4. Google Drive に `inbox` フォルダを作成

### 6. n8n ワークフローのインポート

**ワークフローファイル:** `n8n/workflows/line-to-gdrive.json`

**n8n UI でインポート:**

1. n8n UI の Workflows → Import from File
2. `n8n/workflows/line-to-gdrive.json` を選択
3. Credentials を設定:
   - **LINE Bot Auth**: HTTP Header Auth で以下を設定
     - Header Name: `Authorization`
     - Header Value: `Bearer <LINE_CHANNEL_ACCESS_TOKEN>`
   - **Google Drive OAuth2**: 上記で作成した Credential を選択
4. ワークフローを Activate

### 7. LINE グループで動作確認

```bash
# 1. LINE Bot をグループに招待

# 2. グループで画像を送信

# 3. Google Drive の inbox フォルダを確認
#    ファイル名: YYYY-MM-DD_HHmmss_<groupId>.jpg
```

---

## ワークフロー詳細

### ノード構成

```
1. Webhook          : LINE からメッセージ受信
2. IF Image         : 画像メッセージか判定
3. Get LINE Image   : LINE API から画像データ取得
4. Google Drive     : inbox フォルダにアップロード
5. Response Success : 成功レスポンス返却
6. Response Ignored : 画像以外は無視
```

### ファイル命名規則

```javascript
// Google Drive に保存されるファイル名
{timestamp}_{groupId}.jpg

// 例:
2025-11-13_163000_Cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.jpg
```

### マルチグループ対応

複数の LINE グループに対応しています。グループ ID でファイルを識別可能です。

---

## 主要コマンド

```bash
# ngrok 起動
make ngrok

# LINE Bot 設定情報表示
make line-bot-info

# Webhook 接続テスト
make line-bot-test

# n8n ログ確認
make n8n-logs
```

---

## トラブルシューティング

### 問題: ngrok URL が変更される

**症状:**
```
ngrok の無料版は 8時間で URL が変更される
```

**解決策:**
```bash
# 1. 新しい ngrok URL を取得
make ngrok

# 2. LINE Developers Console で Webhook URL を更新
https://<new-ngrok-url>/webhook/line-webhook
```

**代替案:**
- ngrok 有料プラン (固定 URL)
- localtunnel の使用
- Cloudflare Tunnel の使用

### 問題: 画像が Google Drive に保存されない

**確認項目:**

```bash
# 1. n8n ログを確認
make n8n-logs

# 2. LINE Webhook が届いているか確認
#    n8n UI の Executions タブで確認

# 3. Google Drive Credential が有効か確認
#    n8n UI の Credentials タブで確認

# 4. inbox フォルダが存在するか確認
#    Google Drive で確認
```

### 問題: LINE Bot がグループに参加できない

**確認項目:**

```bash
# LINE Developers Console で以下を確認:
# 1. グループトーク参加が ON になっているか
# 2. Bot が Blocked 状態になっていないか
```

---

[← README に戻る](../README.md)
