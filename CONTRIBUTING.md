# 開発ガイド

LandBase AI Suite プロジェクトへようこそ！このガイドでは、プロジェクトへの貢献方法と開発ワークフローを説明します。

## 目次

- [開発環境セットアップ](#開発環境セットアップ)
- [Git ワークフロー](#git-ワークフロー)
- [コミット規約](#コミット規約)
- [PR 作成フロー](#pr作成フロー)
- [コーディング規約](#コーディング規約)
- [テスト方針](#テスト方針)
- [コードレビュー基準](#コードレビュー基準)
- [トラブルシューティング](#トラブルシューティング)

---

## 開発環境セットアップ

### 必要なツール

以下のツールをインストールしてください：

| ツール              | バージョン | 用途                  |
| ------------------- | ---------- | --------------------- |
| **Docker**          | 20.10+     | コンテナ実行環境      |
| **Docker Compose**  | 2.0+       | マルチコンテナ管理    |
| **Git**             | 2.30+      | バージョン管理        |
| **GitHub CLI (gh)** | 2.0+       | Issue/PR 管理（推奨） |
| **Make**            | -          | タスク自動化          |

### セットアップ手順

#### 1. リポジトリクローン

```bash
git clone https://github.com/zomians/landbase_ai_suite.git
cd landbase_ai_suite
```

#### 2. 環境変数設定

```bash
# .env.local.example をコピー
cp .env.local.example .env.local

# .env.local を編集（機密情報を設定）
# - PostgreSQLパスワード
# - n8n暗号化キー
# - Mattermost設定
# - その他APIキー
```

#### 3. Docker 起動

```bash
# 全サービス起動
make up

# 起動確認
docker compose ps
```

#### 4. 各サービスアクセス確認

| サービス             | URL                   | 備考                                   |
| -------------------- | --------------------- | -------------------------------------- |
| **Platform**         | http://localhost:3001 | プラットフォーム                       |
| **Shrimp Shells EC** | http://localhost:3002 | Rails 8 + Solidus                      |
| **n8n**              | http://localhost:5678 | 初回アクセス時にアカウント作成         |
| **Mattermost**       | http://localhost:8065 | 初回アクセス時にセットアップウィザード |

#### 5. データベース初期化（必要に応じて）

```bash
# Shrimp Shells EC
make shrimpshells-migrate
make shrimpshells-seed

# Platform（実装後）
make platform-migrate
make platform-seed
```

---

## Git ワークフロー

このプロジェクトは **[GitHub Flow](https://docs.github.com/ja/get-started/quickstart/github-flow)** を採用しています。

### 基本フロー

```
1. Issue作成 → 2. ブランチ作成 → 3. 実装 → 4. PR作成 → 5. レビュー → 6. マージ
```

### ブランチ戦略

#### ブランチ命名規則

```
<type>/<issue番号>-<機能名>
```

**Type 一覧**:

- `feature/` - 新機能開発
- `bugfix/` - バグ修正
- `hotfix/` - 緊急修正
- `refactor/` - リファクタリング
- `docs/` - ドキュメント変更

**例**:

```bash
feature/55-platform-app
feature/57-documentation-system
bugfix/58-fix-cart-calculation
hotfix/59-critical-security-patch
refactor/60-cleanup-decorators
docs/61-update-readme
```

#### 保護ブランチ

- **main**: 本番環境デプロイ用（直接プッシュ禁止、PR 経由のみ）

### ブランチ作成手順

```bash
# 1. main を最新化
git checkout main
git pull origin main

# 2. Issue番号を確認（例: #57）
gh issue view 57

# 3. ブランチ作成
git checkout -b feature/57-documentation-system

# 4. 実装開始
# ...
```

---

## コミット規約

### Conventional Commits 準拠

**フォーマット**:

```
<type>(<scope>): <subject> (issue#<番号>)

<body>（オプション）

<footer>（オプション）
```

### Type 一覧

| Type       | 説明               | 例                                        |
| ---------- | ------------------ | ----------------------------------------- |
| `feat`     | 新機能             | `feat(platform): 清掃基準管理APIを実装`   |
| `fix`      | バグ修正           | `fix(rails): 在庫計算ロジックを修正`      |
| `docs`     | ドキュメント       | `docs: CONTRIBUTING.mdを追加`             |
| `refactor` | リファクタリング   | `refactor(platform): Decorator構造を整理` |
| `test`     | テスト追加・修正   | `test(rails): 商品モデルのテストを追加`   |
| `chore`    | ビルド・ツール設定 | `chore: Dockerfileを更新`                 |
| `perf`     | パフォーマンス改善 | `perf(rails): N+1クエリを解消`            |
| `style`    | コードスタイル     | `style: RuboCop違反を修正`                |

### Scope 一覧（オプション）

- `platform` - Platform 基幹アプリ
- `rails` - Shrimp Shells EC
- `n8n` - n8n ワークフロー
- `docker` - Docker 設定
- `db` - データベース
- `docs` - ドキュメント
- `infra` - インフラ設定

### 良いコミットメッセージの例

```bash
# ✅ GOOD
feat(platform): 清掃基準管理APIを実装 (issue#54)
fix(rails): カート合計金額の計算ロジックを修正 (issue#58)
docs: ARCHITECTURE.mdを追加 (issue#57)
refactor(rails): Product Decoratorを整理 (issue#60)
test(platform): CleaningStandardモデルのテストを追加 (issue#54)
chore(docker): PostgreSQL 16にアップグレード (issue#62)
```

### 悪いコミットメッセージの例

```bash
# ❌ BAD
update
fix bug
WIP
商品追加
🤖 Generated with Claude Code  # ツール署名は不要
```

### コミット時の注意事項

1. **1 コミット 1 機能**: 関連する変更のみを含める
2. **意味のある単位**: 「WIP」コミットは避ける
3. **日本語 OK**: subject は日本語で明確に
4. **Issue 番号必須**: `(issue#XX)` を必ず含める
5. **ツール署名削除**: Claude Code の署名は削除してからコミット

---

## PR 作成フロー

### 1. 実装とコミット

```bash
# 実装
# ...

# ステージング
git add .

# コミット
git commit -m "feat(platform): 清掃基準管理APIを実装 (issue#54)"

# プッシュ
git push origin feature/54-cleaning-standards
```

### 2. PR 作成

````bash
# GitHub CLIでPR作成
gh pr create --title "清掃基準管理APIを実装" --body "$(cat <<'EOF'
## 概要
issue#54の清掃基準管理APIを実装しました。

## 変更内容
- CleaningStandardモデル作成
- API v1エンドポイント実装
- Active Storage統合
- RSpecテスト追加

## テスト方法
```bash
make platform-up
make platform-console
# CleaningStandard.create!(...)
```

## チェックリスト

- [x] テスト追加
- [x] RuboCop 準拠
- [x] マイグレーション作成
- [x] ドキュメント更新

Closes #54
EOF
)"

````

### 3. PR テンプレート

PR には以下を含めてください：

````markdown
## 概要

[変更の概要を 1-2 文で説明]

## 変更内容

- [主要な変更点 1]
- [主要な変更点 2]
- [主要な変更点 3]

## テスト方法

```bash
[動作確認手順]
```

## スクリーンショット（必要に応じて）

[画面変更がある場合]

## チェックリスト

- [ ] テスト追加
- [ ] RuboCop 準拠
- [ ] マイグレーション作成
- [ ] ドキュメント更新
- [ ] セキュリティチェック

Closes #XX
````

### 4. レビュー対応

1. レビューコメントを確認
2. 修正実施
3. 追加コミット
4. レビュアーに通知

### 5. マージ

- レビュー承認後、main にマージ
- マージ後、ローカルブランチを削除

```bash
git checkout main
git pull origin main
git branch -d feature/54-cleaning-standards
```

---

## コーディング規約

### Rails（Shrimp Shells EC / Platform）

#### 1. Decorator パターン必須

Solidus の拡張は**必ず**Decorator パターンを使用してください。

**✅ DO**: Decorator で拡張

```ruby
# app/models/spree/product_decorator.rb
module Spree
  module ProductDecorator
    def self.prepended(base)
      base.validates :shrimp_size, inclusion: { in: SHRIMP_SIZES.keys.map(&:to_s) }
    end

    def frozen_product?
      storage_temperature.present? && storage_temperature < 0
    end
  end
end

Spree::Product.prepend(Spree::ProductDecorator)
```

**❌ DON'T**: Gem ファイルを直接編集

```ruby
# vendor/bundle/gems/solidus/app/models/spree/product.rb
# 直接編集は絶対禁止！
```

#### 2. RuboCop 準拠

```bash
# チェック
docker compose run --rm shrimpshells-ec rubocop

# 自動修正
docker compose run --rm shrimpshells-ec rubocop -a
```

#### 3. ViewComponent 推奨

再利用可能な UI 部品は ViewComponent で実装：

```ruby
# app/components/product_card_component.rb
class ProductCardComponent < ViewComponent::Base
  def initialize(product:, show_cart: true)
    @product = product
    @show_cart = show_cart
  end
end
```

#### 4. Service Object パターン

複雑なビジネスロジックは Service Object に抽出：

```ruby
# app/services/cleaning_judge_service.rb
class CleaningJudgeService
  def initialize(cleaning_session:)
    @session = cleaning_session
  end

  def call
    # ビジネスロジック
  end
end
```

### JavaScript（Stimulus）

#### 1. Controller 命名規則

```javascript
// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "results"];

  search(event) {
    // ...
  }
}
```

#### 2. data 属性命名

```html
<div data-controller="search" data-search-url-value="<%= search_path %>">
  <input data-search-target="input" data-action="input->search#search" />
</div>
```

### データベース

#### 1. マイグレーション命名規則

```ruby
# タイムスタンプ_動詞_対象_詳細.rb
20251206_add_phone_number_to_spree_users.rb
20251206_create_cleaning_standards.rb
20251206_add_index_to_products_shrimp_size.rb
```

#### 2. ロールバック可能性

すべてのマイグレーションは`down`メソッドを実装：

```ruby
class AddPhoneNumberToSpreeUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :spree_users, :phone_number, :string
  end

  def down
    remove_column :spree_users, :phone_number
  end
end
```

#### 3. カラムコメント必須

```ruby
add_column :spree_products, :shrimp_size, :string, comment: "エビのサイズ（XL/L/M/S）"
add_column :spree_products, :storage_temperature, :decimal, comment: "保管温度（℃）"
```

---

## テスト方針

### RSpec 必須

すべての新機能・修正にはテストを追加してください。

#### モデルテスト

```ruby
# spec/models/spree/product_decorator_spec.rb
require 'rails_helper'

RSpec.describe Spree::Product, type: :model do
  describe '#frozen_product?' do
    it '保管温度が0℃未満の場合trueを返す' do
      product = build(:product, storage_temperature: -18)
      expect(product.frozen_product?).to be true
    end
  end
end
```

#### API テスト（Request Spec）

```ruby
# spec/requests/api/v1/cleaning_standards_spec.rb
require 'rails_helper'

RSpec.describe 'Api::V1::CleaningStandards', type: :request do
  describe 'GET /api/v1/cleaning_standards' do
    it '清掃基準一覧を返す' do
      get '/api/v1/cleaning_standards'
      expect(response).to have_http_status(:ok)
    end
  end
end
```

#### コンポーネントテスト

```ruby
# spec/components/product_card_component_spec.rb
require 'rails_helper'

RSpec.describe ProductCardComponent, type: :component do
  it 'renders product name' do
    product = build(:product, name: 'ガーリックシュリンプ')
    render_inline(ProductCardComponent.new(product: product))

    expect(page).to have_text('ガーリックシュリンプ')
  end
end
```

### テスト実行

```bash
# 全テスト実行
docker compose run --rm shrimpshells-ec rspec

# 特定ファイルのみ
docker compose run --rm shrimpshells-ec rspec spec/models/spree/product_decorator_spec.rb

# カバレッジ確認
docker compose run --rm shrimpshells-ec rspec --format documentation
```

---

## コードレビュー基準

### 必須チェック項目

- [ ] **機能要件**: Issue の要件を満たしているか
- [ ] **テスト**: 十分なテストが追加されているか
- [ ] **コーディング規約**: RuboCop、ESLint に準拠しているか
- [ ] **命名**: 変数、メソッド、クラス名が適切か
- [ ] **コメント**: 複雑なロジックにコメントがあるか
- [ ] **パフォーマンス**: N+1 クエリなどの問題がないか
- [ ] **セキュリティ**: SQL インジェクション、XSS などの脆弱性がないか
- [ ] **データベース**: マイグレーションがロールバック可能か
- [ ] **ドキュメント**: README、ADR など必要に応じて更新されているか

### セキュリティチェック

#### 1. SQL インジェクション対策

**✅ DO**: パラメータバインディング使用

```ruby
Product.where("name LIKE ?", "%#{params[:query]}%")
```

**❌ DON'T**: 文字列補間

```ruby
Product.where("name LIKE '%#{params[:query]}%'")  # 危険！
```

#### 2. XSS 対策

**✅ DO**: ERB の自動エスケープ活用

```erb
<%= @product.name %>  # 自動エスケープ
```

**❌ DON'T**: raw 使用（必要な場合のみ）

```erb
<%=raw @product.html_description %>  # 要注意
```

#### 3. CSRF 対策

Rails 標準の CSRF 保護を維持：

```ruby
protect_from_forgery with: :exception
```

### パフォーマンスチェック

#### 1. N+1 クエリ回避

```ruby
# ✅ GOOD: eager loading
@products = Product.includes(:images, :variants).all

# ❌ BAD: N+1発生
@products = Product.all
@products.each { |p| p.images.first }  # N+1！
```

#### 2. インデックス追加

頻繁に検索するカラムにはインデックス：

```ruby
add_index :spree_products, :shrimp_size
add_index :spree_orders, [:user_id, :created_at]
```

---

## トラブルシューティング

### よくある問題と解決策

#### 1. Docker ビルドエラー

```bash
# エラー: "cannot find package..."
make clean
make up
```

#### 2. マイグレーションエラー

```bash
# エラー: "PG::DuplicateColumn"
# 解決: マイグレーションをロールバック
make shrimpshells-shell
cd /shrimpshells && bin/rails db:rollback
```

#### 3. ポート競合

```bash
# エラー: "port is already allocated"
# 解決: .envのポート番号を変更
PLATFORM_PORT=3004  # デフォルト: 3001
```

#### 4. Bundle install 失敗

```bash
# エラー: "bundle install failed"
# 解決: ボリューム削除して再ビルド
docker volume rm landbase_ai_suite_platform_bundle
make platform-up
```

#### 5. データベース接続エラー

```bash
# エラー: "could not connect to database"
# 解決: PostgreSQLの起動を確認
docker compose ps postgres
docker compose up -d postgres
```

### ログの見方

```bash
# 全サービスログ
make logs

# 特定サービスのログ
make platform-logs
make shrimpshells-logs
make n8n-logs
make mattermost-logs
make postgres-logs
```

### デバッグ方法

#### Rails Console

```bash
make platform-console
make shrimpshells-console
```

#### コンテナシェル接続

```bash
make platform-shell
make shrimpshells-shell
```

#### データベース直接接続

```bash
make postgres-shell
```

---

## 参考リンク

- [プロジェクトアーキテクチャ](./ARCHITECTURE.md)
- [Claude 向けガイド](./CLAUDE.md)
- [GitHub Flow](https://docs.github.com/ja/get-started/quickstart/github-flow)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [RuboCop](https://docs.rubocop.org/)
- [RSpec](https://rspec.info/)

---

## 質問・サポート

- **Issue**: [GitHub Issues](https://github.com/zomians/landbase_ai_suite/issues)
- **連絡先**: 株式会社 AI.LandBase

開発を楽しんでください！🚀
