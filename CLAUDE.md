# CLAUDE.md - Claude 向けクイックリファレンス

このドキュメントは、Claude（AI 開発アシスタント）がこのプロジェクトを素早く理解し、適切な開発支援を行うための**クイックリファレンス**です。

---

## ドキュメント役割分担

| ドキュメント        | 役割                                                   |
| ------------------- | ------------------------------------------------------ |
| **README.md**       | プロジェクト概要、技術スタック、クイックスタート、トラブルシューティング |
| **CONTRIBUTING.md** | 開発規約（Issue、Git、コミット、PR、コーディング規約） |
| **CLAUDE.md**       | AI 向けクイックリファレンス（このファイル）            |
| **ARCHITECTURE.md** | 技術アーキテクチャ詳細、DB 設計、API 設計              |
| **docs/adr/**       | 設計判断の背景（Architecture Decision Records）        |

**詳細な開発規約は [CONTRIBUTING.md](./CONTRIBUTING.md) を参照してください。**

---

## プロジェクト概要

**LandBase AI Suite** - 沖縄県北部の観光業向け AI ドリブン経営支援 SaaS プラットフォーム

### アーキテクチャ概要

```
バックオフィス（共通基盤）
├── Platform (Rails 8) :3000  ← クライアント管理、AI機能
├── n8n :5678                 ← ワークフロー自動化
└── Mattermost :8065          ← チームコミュニケーション

フロントサービス（クライアント固有）
├── Shrimp Shells EC (別リポジトリ)           ← 冷凍食品EC
└── Hotel App (将来)                           ← 予約サイト
```

### 技術スタック

- **Rails 8.0.2.1**
- **PostgreSQL 16** (論理分離: client_code)
- **Docker Compose** (5 サービス統合)
- **Tailwind CSS** + **Stimulus**

---

## よく使うコマンド

### 初期セットアップ

```bash
make init                  # Platform Railsアプリ生成（初回のみ）
```

### サービス管理

```bash
make up                    # 全サービス起動（PostgreSQL, Platform, Mattermost, n8n）
make down                  # 全サービス停止
make logs                  # 全サービスログ表示
make clean                 # 完全クリーンアップ（注意：データ削除）
```

### 個別サービス

```bash
make postgres-shell        # PostgreSQLシェル接続
make n8n-logs              # n8nログ表示
make mattermost-logs       # Mattermostログ表示
```

---

## CONTRIBUTING.md 活用方法

開発作業の流れは CONTRIBUTING.md に詳細に記載されています。

### 開発ワークフロー（5 ステップ）

```bash
# 1. Issue 作成（GitHub で実施）
# → CONTRIBUTING.md の「Issue 作成ガイドライン」参照

# 2. ブランチ作成
git checkout main && git pull origin main
git checkout -b feature/XX-description

# 3. 実装
# → CONTRIBUTING.md の「コーディング規約」参照

# 4. コミット
git add .
git commit -m "feat(scope): 変更内容 (issue#XX)"

# 5. PR 作成
gh pr create --title "タイトル" --body "Closes #XX"
```

### コミット規約

```bash
# フォーマット
<type>(<scope>): <subject> (issue#XX)

# 例
feat(platform): 清掃基準管理APIを実装 (issue#54)
fix(rails): カート計算ロジックを修正 (issue#58)
docs: CONTRIBUTING.mdを追加 (issue#57)
```

**禁止事項**:

- ❌ main ブランチへの直接プッシュ
- ❌ issue 番号なしのコミット
- ❌ AI ツール署名の追加（`Co-Authored-By: Claude` など）

---

## 重要な設計原則（プロジェクト固有）

### 1. マルチテナントは client_code スコープ

```ruby
# ✅ GOOD: スコープで分離
CleaningStandard.for_client(@current_client.code)

# ❌ BAD: スコープなし（全テナントデータ取得）
CleaningStandard.all
```

### 2. 詳細は ARCHITECTURE.md 参照

- システム設計詳細
- データベース設計（ER 図）
- API 設計
- 設計パターン（Service Object）

---

## セキュリティチェック

実装時に以下を確認してください：

```ruby
# 1. SQL インジェクション対策
Product.where("name LIKE ?", "%#{query}%")  # ✅ パラメータバインディング
Product.where("name LIKE '%#{query}%'")     # ❌ 文字列補間

# 2. Strong Parameters
params.require(:product).permit(:name, :price)

# 3. 認可チェック
before_action :authenticate_user!
```

---

## トラブルシューティング

### コンテナが起動しない

```bash
make clean && make up
```

### マイグレーションエラー

```bash
docker compose exec platform bash -lc "bin/rails db:rollback"
```

### ポート競合

```bash
# .env でポート番号を変更
PLATFORM_PORT=3004
```

---

## Claude Code 向けワークフロー

### 推奨プロンプト形式

```
issue#XX の [タスク内容] を実装してください。

要件:
- [要件1]
- [要件2]
```

### 作業手順

1. **Issue 確認**: `gh issue view XX`
2. **ブランチ作成**: `git checkout -b feature/XX-description`
3. **実装**: コーディング規約に従う
4. **テスト追加**: RSpec でテスト作成
5. **コミット**: Conventional Commits 形式
6. **PR 作成**: `gh pr create`

---

## 自動実行ポリシー

Claude Code が操作を実行する際の基準を定義します。

### 確認なしで実行可能

以下の**読み取り専用操作**は、確認なしで自動実行できます：

- **ファイル読み取り**: Read, Grep, Glob
- **状態確認コマンド**:
  - `git status`, `git log`, `git diff`
  - `docker ps`, `docker compose ps`
  - `ls`, `cat`, `grep`, `find`
- **ログ確認**:
  - `docker compose logs`
  - `make logs`, `make n8n-logs`, `make mattermost-logs`
- **テスト実行**:
  - `bundle exec rspec`
  - `npm test`

### 必ず確認が必要

以下の**書き込み・変更操作**は、ユーザーの明示的な承認が必要です：

- **データベース操作**:
  - `bin/rails db:create`, `db:migrate`, `db:seed`
  - `bin/rails db:drop`, `db:reset`
  - SQL の INSERT/UPDATE/DELETE
- **Git 操作**:
  - `git commit`, `git push`
  - `git branch` 作成・削除
  - `git merge`, `git rebase`
- **ファイル削除・上書き**:
  - Write, Edit（既存ファイルの上書き）
  - `rm`, `mv`（ファイル削除・移動）
  - `docker compose down -v`（ボリューム削除）
- **本番環境への操作**:
  - デプロイコマンド
  - 環境変数の変更
  - 本番データベースへのアクセス

**原則**: データの永続的な変更や、元に戻せない操作は必ず確認する。

---

## 関連リンク

- [README.md](./README.md) - プロジェクト概要、クイックスタート
- [CONTRIBUTING.md](./CONTRIBUTING.md) - 開発規約の詳細
- [ARCHITECTURE.md](./ARCHITECTURE.md) - 技術アーキテクチャ詳細
- [docs/adr/](./docs/adr/) - 設計判断記録

---

**Last Updated**: 2026-01-20
