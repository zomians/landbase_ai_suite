# ADR 0007: Caddy リバースプロキシによる複数ドメイン構成

## ステータス

採用（Accepted）

## 日付

2026-02-23

## コンテキスト（背景・課題）

LandBase AI Suite は複数のサービス（Platform、EC サイト等）を異なるドメインで公開する必要がある。単一 VPS 上で運用コストを抑えつつ、各プロジェクトの独立性を保った構成が求められる。

### 具体的な課題

- 各プロジェクトが独自にポート 80/443 をバインドするとポート競合が発生する
- プロジェクトごとにリバースプロキシを立てると管理が煩雑になる
- TLS 証明書管理を各プロジェクトで個別に行う必要がある

## 決定

**Caddy 2 を独立した Docker Compose スタックとして配置し、共有ネットワーク経由で各アプリにルーティングする。**

### アーキテクチャ

```
VPS (単一ホスト)
│
├── reverse-proxy/          ← Caddy 独立スタック
│   ├── compose.yaml
│   ├── Caddyfile
│   └── Makefile
│
└── landbase_ai_suite/      ← www.land-bank.ai
    ├── compose.production.yaml  (app-suite: expose 3000)
    └── ...

[web-proxy-net] ← 共有外部 Docker ネットワーク
  ├── caddy       (80/443 バインド)
  └── app-suite   (expose 3000)

[internal] ← 内部ネットワーク (internal: true)
  ├── app-suite
  └── db-suite
```

### 設計ポイント

1. **ネットワーク分離**: DB は `internal` ネットワークのみに接続し外部アクセス不可
2. **ポート集約**: 80/443 は Caddy コンテナのみがバインド、各アプリは `expose` のみ
3. **自動 HTTPS**: Caddy の Let's Encrypt 自動証明書で TLS を一元管理
4. **独立ライフサイクル**: Caddy と各アプリは別 Compose スタックで独立して再起動可能

## 検討した代替案

### Nginx + Let's Encrypt (certbot)

- 設定が複雑（証明書更新の cron 設定が必要）
- Caddy は設定がシンプルで自動 HTTPS がビルトイン

### Kamal (Rails 標準)

- Rails アプリ単体のデプロイには適しているが、複数プロジェクトの統合管理には向かない
- Kamal の kamal-proxy は単一アプリ前提の設計

### Traefik

- 高機能だが設定が複雑
- 小規模構成には Caddy の方がシンプル

## 結果

- `reverse-proxy/` に Caddy 独立スタックを配置
- `compose.production.yaml` で Platform を `expose` のみで公開
- `.env.production` で本番環境変数をテンプレート管理
- 新規アプリ追加時は Caddyfile にエントリ追加 + `web-proxy-net` 参加のみで完了
