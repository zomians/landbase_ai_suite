# VPS デプロイ手順書

単一 VPS 上に Caddy リバースプロキシ + Rails アプリをデプロイする手順。

## 前提条件

- Ubuntu 22.04+ の VPS
- Docker & Docker Compose インストール済み
- ドメインの DNS A レコードが VPS の IP を指している
- ポート 80, 443 がファイアウォールで開放されている

## VPS ディレクトリ構成

```
/srv/
├── reverse-proxy/          ← Caddy 独立スタック
│   ├── compose.yaml
│   ├── Caddyfile
│   └── Makefile
│
└── landbase_ai_suite/      ← www.land-bank.ai
    ├── compose.production.yaml
    ├── .env.production
    └── ...
```

## 1. VPS 初期セットアップ

```bash
# デプロイユーザー作成
sudo adduser devuser
sudo usermod -aG sudo devuser
sudo usermod -aG docker devuser

# SSH鍵認証設定（ローカルから）
ssh-copy-id devuser@your-vps-ip

# デプロイディレクトリ作成
sudo mkdir -p /srv
sudo chown devuser:devuser /srv
```

## 2. リポジトリ配置

```bash
ssh devuser@your-vps-ip
cd /srv
git clone <repository-url> landbase_ai_suite
```

## 3. Caddy リバースプロキシ起動

```bash
# reverse-proxy/ を /srv 直下にコピー
cp -r /srv/landbase_ai_suite/reverse-proxy /srv/reverse-proxy

# 共有ネットワーク作成 + Caddy 起動
cd /srv/reverse-proxy
make up
```

Caddy が起動し、Let's Encrypt から自動で SSL 証明書を取得する。

## 4. Platform デプロイ

```bash
cd /srv/landbase_ai_suite

# .env.production を本番値に編集
vi .env.production

# SECRET_KEY_BASE 生成
make prod-secret
# 出力値を .env.production に設定

# デプロイ
make prod-deploy
```

## 5. 更新デプロイ

```bash
ssh devuser@your-vps-ip
cd /srv/landbase_ai_suite
git pull origin main
make prod-deploy
```

## 新規アプリ追加手順

1. アプリの `compose.yaml` でサービス名をユニークにする（例: `app-norn`）
2. `expose` のみ使用し `ports` は使わない
3. `web-proxy-net` 外部ネットワークに参加させる
4. `/srv/reverse-proxy/Caddyfile` にドメインエントリを追加
5. Caddy を再読み込み: `cd /srv/reverse-proxy && make reload`

## トラブルシューティング

### コンテナが起動しない

```bash
cd /srv/landbase_ai_suite && make prod-logs
```

### SSL 証明書が取得できない

- DNS A レコードが正しく設定されているか確認
- ポート 80/443 が開放されているか確認
- `cd /srv/reverse-proxy && make logs` で Caddy のログを確認

### DB 接続エラー

```bash
docker compose -f compose.production.yaml --env-file .env.production exec db-suite pg_isready
```
