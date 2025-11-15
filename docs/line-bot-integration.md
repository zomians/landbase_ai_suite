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

### 3.1 ngrok 認証設定（推奨）

**重要**: ngrok は無料版でも認証することで機能制限が大幅に緩和されます。

#### **無料版の機能比較**

| 項目 | 未認証 | 認証済み（authtoken設定） |
|------|--------|-------------------------|
| セッション時間 | 2時間 | 8時間 |
| トンネル数 | 1本 | 1本 |
| リクエスト数/分 | 20 | 40 |
| HTTPSサポート | ✅ | ✅ |
| カスタムドメイン | ❌ | ❌ (有料プランのみ) |
| 固定URL | ❌ | ❌ (有料プランのみ) |

#### **authtoken の設定方法**

1. **ngrok アカウント作成**:
   ```bash
   # ngrok サインアップページにアクセス
   open https://dashboard.ngrok.com/signup
   ```

2. **authtoken を取得**:
   - サインアップ後、Dashboard で authtoken を確認
   - または: https://dashboard.ngrok.com/get-started/your-authtoken

3. **authtoken を設定**:
   ```bash
   # コマンドで設定（推奨）
   ngrok config add-authtoken <your-authtoken>

   # 設定ファイルの場所確認
   # macOS: ~/.config/ngrok/ngrok.yml
   # Linux: ~/.config/ngrok/ngrok.yml
   # Windows: %USERPROFILE%\AppData\Local\ngrok\ngrok.yml
   ```

4. **設定ファイルの確認**:
   ```bash
   cat ~/.config/ngrok/ngrok.yml
   ```

   **出力例**:
   ```yaml
   version: "2"
   authtoken: <your-authtoken>
   ```

5. **ngrok再起動**:
   ```bash
   # 既存のngrokを終了
   pkill -f "ngrok http"

   # 再起動
   make ngrok
   ```

#### **高度な設定（オプション）**

`~/.config/ngrok/ngrok.yml` で追加設定が可能：

```yaml
version: "2"
authtoken: <your-authtoken>

# カスタム設定
tunnels:
  n8n:
    proto: http
    addr: 5678
    # 基本認証を追加（セキュリティ強化）
    auth: "username:password"
    # カスタムサブドメイン（有料プランのみ）
    # subdomain: my-landbase-n8n

# ログレベル設定
log_level: info
log_format: json
log: /tmp/ngrok.log

# リージョン指定（レイテンシ最適化）
region: jp  # 日本リージョン (ap も可)
```

**利用可能なリージョン**:
- `us` - アメリカ
- `eu` - ヨーロッパ
- `ap` - アジア太平洋
- `au` - オーストラリア
- `sa` - 南アメリカ
- `jp` - 日本
- `in` - インド

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

## 本番運用時の推奨構成

ngrok は開発・テスト環境には最適ですが、本番運用では以下の代替案を検討してください。

### オプション A: Cloudflare Tunnel（推奨・無料）

**メリット**:
- ✅ 完全無料
- ✅ セッション時間無制限
- ✅ 固定URL
- ✅ DDoS保護
- ✅ WAF（Web Application Firewall）
- ✅ カスタムドメイン対応

**デメリット**:
- ⚠️ Cloudflareアカウント必要
- ⚠️ DNSをCloudflareに移管（カスタムドメイン利用時）

#### **セットアップ手順**

1. **Cloudflare Tunnel インストール**:
   ```bash
   brew install cloudflare/cloudflare/cloudflared
   ```

2. **Cloudflare ログイン**:
   ```bash
   cloudflared tunnel login
   ```
   - ブラウザでCloudflareアカウントにログイン
   - サイトを選択（またはカスタムドメイン追加）

3. **Tunnel 作成**:
   ```bash
   cloudflared tunnel create landbase-n8n
   ```
   - Tunnel ID が表示される（保存しておく）

4. **設定ファイル作成**:
   ```bash
   mkdir -p ~/.cloudflared
   cat > ~/.cloudflared/config.yml <<EOF
   tunnel: <your-tunnel-id>
   credentials-file: /Users/<username>/.cloudflared/<your-tunnel-id>.json

   ingress:
     - hostname: n8n.yourdomain.com
       service: http://localhost:5678
     - service: http_status:404
   EOF
   ```

5. **DNS レコード作成**:
   ```bash
   cloudflared tunnel route dns landbase-n8n n8n.yourdomain.com
   ```

6. **Tunnel 起動**:
   ```bash
   cloudflared tunnel run landbase-n8n
   ```

7. **systemd サービス化（Linux）または launchd（macOS）**:
   ```bash
   # macOS の場合
   sudo cloudflared service install
   ```

**Webhook URL**:
```
https://n8n.yourdomain.com/webhook/line-webhook
```

---

### オプション B: ngrok 有料プラン

**料金**: $8/月〜

**メリット**:
- ✅ 固定URL（例: https://landbase.ngrok.app）
- ✅ セッション時間無制限
- ✅ ブラウザ警告なし
- ✅ カスタムドメイン対応
- ✅ IP制限・認証機能

**プラン比較**:

| プラン | 料金 | トンネル数 | カスタムドメイン | エージェント数 |
|--------|------|-----------|----------------|-------------|
| Free | $0 | 1本 | ❌ | 1 |
| Personal | $8/月 | 3本 | ✅ 1個 | 2 |
| Pro | $20/月 | 10本 | ✅ 3個 | 5 |
| Business | $58/月 | 無制限 | ✅ 無制限 | 無制限 |

#### **セットアップ手順**

1. **有料プランに登録**:
   ```bash
   open https://dashboard.ngrok.com/billing/subscription
   ```

2. **固定ドメイン取得**:
   - Dashboard → Domains → Reserve Domain
   - 例: `landbase.ngrok.app`

3. **ngrok.yml を更新**:
   ```yaml
   version: "2"
   authtoken: <your-authtoken>

   tunnels:
     n8n:
       proto: http
       addr: 5678
       domain: landbase.ngrok.app  # 固定ドメイン
   ```

4. **起動**:
   ```bash
   ngrok start n8n
   ```

**Webhook URL**:
```
https://landbase.ngrok.app/webhook/line-webhook
```

---

### オプション C: VPS + Nginx リバースプロキシ（完全コントロール）

**料金**: $5〜10/月（VPS代）

**メリット**:
- ✅ 完全コントロール
- ✅ 固定IP/ドメイン
- ✅ 他のサービスも同一サーバーで運用可能
- ✅ Let's Encrypt で無料SSL

**デメリット**:
- ⚠️ サーバー管理が必要
- ⚠️ セキュリティ対策が必要
- ⚠️ メンテナンス負担

#### **アーキテクチャ**

```
[LINE Server]
      ↓
[VPS Public IP]
      ↓
[Nginx (443)]
      ↓ SSH Tunnel / WireGuard VPN
[ローカル n8n (5678)]
```

#### **セットアップ手順（概要）**

1. **VPS 契約**:
   - DigitalOcean, Linode, Vultr 等
   - Ubuntu 22.04 推奨

2. **Nginx インストール**:
   ```bash
   ssh user@your-vps-ip
   sudo apt update
   sudo apt install nginx certbot python3-certbot-nginx
   ```

3. **SSL証明書取得**:
   ```bash
   sudo certbot --nginx -d n8n.yourdomain.com
   ```

4. **Nginx 設定**:
   ```nginx
   # /etc/nginx/sites-available/n8n
   server {
       listen 443 ssl http2;
       server_name n8n.yourdomain.com;

       ssl_certificate /etc/letsencrypt/live/n8n.yourdomain.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/n8n.yourdomain.com/privkey.pem;

       location / {
           proxy_pass http://localhost:5678;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

5. **ローカル → VPS SSH トンネル**:
   ```bash
   # ローカルMacから実行
   ssh -R 5678:localhost:5678 user@your-vps-ip -N
   ```

   **または WireGuard VPN** で常時接続（推奨）

6. **systemd サービス化**:
   ```bash
   # SSH トンネル自動起動設定
   sudo systemctl enable ssh-tunnel
   sudo systemctl start ssh-tunnel
   ```

**Webhook URL**:
```
https://n8n.yourdomain.com/webhook/line-webhook
```

---

### 推奨フロー

**開発環境**:
```
ngrok（無料・認証済み）
  ↓ 動作確認OK
```

**ステージング環境**:
```
Cloudflare Tunnel（無料）
  ↓ 本番想定テスト
```

**本番環境**:
```
Cloudflare Tunnel（無料・推奨）
または
ngrok Pro（$20/月）
または
VPS + Nginx（$5-10/月 + 管理コスト）
```

---

[← README に戻る](../README.md)
