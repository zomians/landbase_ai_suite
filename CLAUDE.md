# CLAUDE.md - Claude 向けクイックリファレンス

このドキュメントは、Claude（AI 開発アシスタント）がこのプロジェクトを素早く理解し、適切な開発支援を行うための**クイックリファレンス**です。

**詳細な開発規約は [CONTRIBUTING.md](./CONTRIBUTING.md)、技術設計は [ARCHITECTURE.md](./ARCHITECTURE.md) を参照してください。**

---

## プロジェクト概要

**LandBase AI Suite** - 沖縄県北部の観光業向け AI ドリブン経営支援 SaaS プラットフォーム

### システム構成

```
Platform (Rails 8) :3000  ← AI モジュール、API、クライアント管理
n8n :5678                 ← ワークフロー自動化（LINE Bot 連携）
Mattermost :8065          ← チームコミュニケーション
PostgreSQL :5432          ← データベース
```

### 技術スタック

- **Rails 8.0.2.1** / **Ruby 3.4.6**
- **PostgreSQL 16** (マルチテナント: client_code 論理分離)
- **Docker Compose** (4 サービス統合)
- **Anthropic SDK** (Claude API)
- **Tailwind CSS** + **Stimulus**

---

## よく使うコマンド

```bash
# サービス管理
make up                    # 全サービス起動
make down                  # 全サービス停止
make logs                  # 全サービスログ表示
make clean                 # 完全クリーンアップ（注意：データ削除）
make postgres-shell        # PostgreSQLシェル接続

# LINE Bot 連携
make ngrok                 # ngrokでn8nを公開（LINE Webhook用）

# 本番デプロイ
make prod-deploy           # Platformデプロイ
make prod-logs             # 本番ログ表示
```

---

## コミット規約

```bash
# フォーマット
<type>(<scope>): <subject> (issue#XX)

# 例
feat(platform): 清掃基準管理APIを実装 (issue#54)
fix(platform): カート計算ロジックを修正 (issue#58)
docs: CONTRIBUTING.mdを追加 (issue#57)
```

**禁止事項**:

- main ブランチへの直接プッシュ
- issue 番号なしのコミット
- AI ツール署名の追加（`Co-Authored-By: Claude` など）

---

## 重要な設計原則

### マルチテナントは client_code スコープ

```ruby
# GOOD: スコープで分離
JournalEntry.for_client(@current_client.code)
CleaningManual.for_client(@current_client.code)

# BAD: スコープなし（全テナントデータ取得）
JournalEntry.all
```

### セキュリティチェック

```ruby
# 1. SQL インジェクション対策
Client.where("name LIKE ?", "%#{query}%")   # パラメータバインディング
Client.where("name LIKE '%#{query}%'")      # NG: 文字列補間

# 2. Strong Parameters
params.require(:journal_entry).permit(:debit_account, :credit_account, :description)

# 3. 認証
before_action :authenticate_user!            # Web UI（Devise）
before_action :authenticate_api_token!       # API（Bearer トークン）
```

---

## トラブルシューティング

### コンテナが起動しない

```bash
make clean && make up
```

### マイグレーションエラー

```bash
docker compose -f compose.development.yaml --env-file .env.development exec platform bash -lc "bin/rails db:rollback"
```

### ポート競合

```bash
# .env.development でポート番号を変更
PLATFORM_PORT=3004
```

---

## 自動実行ポリシー

### 確認なしで実行可能

- **ファイル読み取り**: Read, Grep, Glob
- **状態確認**: `git status`, `git log`, `git diff`, `docker compose ps`
- **ログ確認**: `make logs`
- **テスト実行**: `bundle exec rspec`

### 必ず確認が必要

- **データベース操作**: `db:migrate`, `db:drop`, `db:reset`
- **Git 操作**: `git commit`, `git push`, ブランチ作成・削除
- **ファイル変更**: Write, Edit, `rm`, `mv`
- **本番環境**: デプロイ、環境変数変更、本番 DB アクセス

**原則**: データの永続的な変更や、元に戻せない操作は必ず確認する。

---

**Last Updated**: 2026-02-25
