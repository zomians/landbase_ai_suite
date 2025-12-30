# CLAUDE.md - Claude 向けクイックリファレンス

**LandBase AI Suite を 5 分で理解するガイド**

このドキュメントは、Claude（AI 開発アシスタント）がこのプロジェクトを素早く理解し、適切なコード生成・問題解決を行うための**クイックリファレンス**です。

---

## 📌 5 分で理解する LandBase AI Suite

### プロジェクト概要

**何を作っているか？**

- 沖縄県北部の小規模観光業（ホテル、飲食店、ツアー会社）向け **SaaS 型マルチテナントプラットフォーム**
- AI とワークフロー自動化で、人手不足・データ活用の遅れ・OTA 依存を解決

**コアコンセプト**:

```
データドリブン経営 ← AIソリューション（OperationAI + MarketingAI）
```

### アーキテクチャ（1 分で理解）

```
┌──────────────────────────────────────────────────┐
│  LandBase AI Suite Platform (バックオフィス)      │
│  ┌──────────┐ ┌────────────┐ ┌──────────────┐   │
│  │ Platform │ │    n8n     │ │  Mattermost  │   │
│  │ (Rails)  │ │ワークフロー│ │ チーム通信   │   │
│  │ポート:3001│ │自動化      │ │              │   │
│  └──────────┘ └────────────┘ └──────────────┘   │
└──────────────────────────────────────────────────┘
            │ API連携
┌───────────┴───────────────────────────────────────┐
│          フロントサービス（クライアント固有）       │
│  ┌──────────────────┐  ┌──────────────────┐      │
│  │ Shrimp Shells EC │  │   Hotel App      │      │
│  │ (Rails + Solidus)│  │   (将来)         │      │
│  │ ポート: 3002     │  │   ポート: 3004   │      │
│  └──────────────────┘  └──────────────────┘      │
└──────────────────────────────────────────────────┘
```

**重要なポイント**:

- **バックオフィス（Platform）**: 全クライアント共通機能（クライアント管理、清掃管理、AI 判定等）
- **フロントサービス**: クライアント固有機能（EC、予約サイト等）
- **n8n**: Projects 機能でクライアント毎のワークフロー管理
- **Mattermost**: Teams 機能でクライアント毎のチャット環境
- **PostgreSQL**: client_code 論理分離（物理分離ではない）

### 技術スタック（30 秒で理解）

| レイヤー             | 技術                                  |
| -------------------- | ------------------------------------- |
| **基盤**             | Docker Compose, PostgreSQL 16         |
| **自動化**           | n8n 2.1.1, Mattermost 9.11          |
| **アプリ**           | Rails 8.0.2.1, Solidus 4.5, Devise    |
| **フロント**         | ViewComponent, Tailwind CSS, Stimulus |
| **バックグラウンド** | Solid Queue, Solid Cache, Solid Cable |

**なぜ Rails？**: OSS、MVC/CRUD/REST 原則に忠実、scaffold 機能で 80%自動生成

### マルチテナント分離戦略（30 秒で理解）

| サービス   | 分離方法      | 実装                                 |
| ---------- | ------------- | ------------------------------------ |
| n8n        | Projects 機能 | 単一インスタンス、Project 単位で分離 |
| Mattermost | Teams 機能    | 単一インスタンス、Team 単位で分離    |
| PostgreSQL | client_code   | 単一 DB、WHERE 句で論理分離          |
| Rails      | スコープ      | `for_client(code)`                   |

**重要**: 物理分離ではなく**論理分離**（管理を複雑にしないため）

---

## 🎯 重要な設計原則（DO / DON'T）

### 1. Solidus 拡張は**必ず**Decorator パターン

#### ✅ DO: Decorator パターン（prepend）

```ruby
# app/models/spree/product_decorator.rb
module Spree
  module ProductDecorator
    def self.prepended(base)
      # クラスレベルの定義
      base.validates :shrimp_size,
        inclusion: { in: %w[xl l m s], allow_blank: true }

      base.scope :frozen_products, -> { where('storage_temperature < ?', 0) }
    end

    # インスタンスメソッド追加
    def frozen_product?
      storage_temperature.present? && storage_temperature < 0
    end

    # 既存メソッド上書き（superで元のメソッド呼び出し）
    def requires_special_shipping?
      super || frozen_product?
    end
  end
end

# prepend で適用
Spree::Product.prepend(Spree::ProductDecorator)
```

**理由**:

- Solidus gem のソースコードを変更しない（非侵襲的）
- バージョンアップ時も変更が維持される
- メソッド上書き可能（`prepend`でメソッドチェーン先頭に追加）

#### ❌ DON'T: 直接編集、Fork

```ruby
# ❌ NG: Solidus gemのソースコードを直接編集
# vendor/bundle/gems/solidus_core-X.X.X/app/models/spree/product.rb
class Spree::Product < Spree::Base
  validates :shrimp_size, ...  # bundle update で消える！
end

# ❌ NG: Fork
# Gemfile
gem 'solidus', github: 'your-org/solidus', branch: 'custom'
# → メンテナンスコスト膨大、面倒
```

### 2. マルチテナント分離は**必ず**client_code スコープ

#### ✅ DO: client_code スコープを必ず使用

```ruby
# コントローラー
class Api::V1::ProductsController < Api::V1::BaseController
  before_action :set_current_client

  def index
    # ✅ GOOD: client_code スコープで分離
    @products = Spree::Product.for_client(@current_client.code)
    render json: @products
  end

  private

  def set_current_client
    @current_client = Client.find_by!(code: request.headers['X-Client-Code'])
  end
end

# モデル
class ApplicationRecord < ActiveRecord::Base
  scope :for_client, ->(code) { where(client_code: code) }
end
```

#### ❌ DON'T: スコープなしのクエリ

```ruby
# ❌ NG: 全テナントのデータを取得（データ漏洩リスク）
@products = Spree::Product.all

# ❌ NG: 手動でWHERE句（スコープ忘れのリスク）
@products = Spree::Product.where(client_code: 'shrimp_shells')
```

### 3. 設計パターン

#### ✅ DO: Service Object（複雑なビジネスロジック）

```ruby
# app/services/cleaning_judge_service.rb
class CleaningJudgeService
  def initialize(session)
    @session = session
  end

  def call
    analyze_images
    judge_quality
    notify_result
  end

  private

  def analyze_images
    # AI判定ロジック
  end

  def judge_quality
    # 基準と比較
  end

  def notify_result
    # Mattermost通知
  end
end

# 使用例
CleaningJudgeService.new(session).call
```

#### ✅ DO: ViewComponent（再利用可能な UI コンポーネント）

```ruby
# app/components/product_card_component.rb
class ProductCardComponent < ViewComponent::Base
  def initialize(product:)
    @product = product
  end
end

# app/components/product_card_component.html.erb
<div class="border rounded-lg p-4">
  <h3 class="font-bold"><%= @product.name %></h3>
  <p class="text-gray-600"><%= number_to_currency(@product.price) %></p>
</div>

# 使用例（ビュー）
<%= render(ProductCardComponent.new(product: @product)) %>
```

### 4. コミット規約（Conventional Commits）

**フォーマット**:

```
<type>(<scope>): <subject> (issue#<番号>)

<body>（オプション）

<footer>（オプション）
```

#### Type 一覧

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

#### Scope 一覧（オプション）

- `platform` - Platform 基幹アプリ
- `rails` - Shrimp Shells EC
- `n8n` - n8n ワークフロー
- `docker` - Docker 設定
- `db` - データベース
- `docs` - ドキュメント
- `infra` - インフラ設定

#### 良いコミットメッセージの例

```bash
# ✅ GOOD
feat(platform): 清掃基準管理APIを実装 (issue#54)
fix(rails): カート合計金額の計算ロジックを修正 (issue#58)
docs: ARCHITECTURE.mdを追加 (issue#57)
refactor(rails): Product Decoratorを整理 (issue#60)
test(platform): CleaningStandardモデルのテストを追加 (issue#54)
chore(docker): PostgreSQL 16にアップグレード (issue#62)
```

#### 悪いコミットメッセージの例

```bash
# ❌ BAD
update
fix bug
WIP
商品追加
🤖 Generated with Claude Code  # ツール署名は不要
```

#### コミット時の注意事項

1. **1 コミット 1 機能**: 関連する変更のみを含める
2. **意味のある単位**: 「WIP」コミットは避ける
3. **日本語 OK**: subject は日本語で明確に
4. **Issue 番号必須**: `(issue#XX)` を必ず含める
5. **ツール署名削除**: Claude Code の署名は削除してからコミット

---

## 📂 ディレクトリ構成クイックマップ

```
landbase_ai_suite/
├── .claude/                       # Claude Code設定（将来）
├── config/
│   └── client_list.yaml           # クライアントレジストリ
├── docs/
│   ├── company-overview.md        # 会社・ビジネス概要
│   └── adr/                       # Architecture Decision Records
│       ├── 0001-n8n-mattermost-rails-integration.md
│       ├── 0002-frontend-backend-separation.md
│       ├── 0003-solidus-for-restaurant-ec.md
│       ├── 0004-decorator-pattern-for-solidus-extension.md
│       ├── 0005-multitenancy-strategy.md
│       └── 0006-platform-app-separation.md
├── n8n/
│   └── workflows/                 # n8nワークフローテンプレート
├── rails/
│   ├── platform/                  # ★プラットフォーム基幹アプリ（issue#55で実装予定）
│   │   ├── app/
│   │   │   ├── models/
│   │   │   │   ├── client.rb
│   │   │   │   ├── cleaning_standard.rb
│   │   │   │   └── cleaning_session.rb
│   │   │   ├── controllers/api/v1/
│   │   │   ├── services/
│   │   │   └── jobs/
│   │   ├── config/
│   │   ├── db/migrate/
│   │   └── spec/
│   │
│   └── shrimp_shells_ec/          # ★Shrimp Shells 冷凍食品EC
│       ├── app/
│       │   ├── models/spree/
│       │   │   ├── product_decorator.rb         # Decoratorパターン
│       │   │   ├── order_decorator.rb
│       │   │   └── user_decorator.rb
│       │   ├── components/                      # ViewComponent
│       │   ├── services/                        # Service Object
│       │   └── queries/                         # Query Object
│       ├── spec/
│       └── Gemfile
│
├── nextjs/                        # マーケティングサイト（将来）
├── .env                           # 環境変数設定
├── .env.local.example             # 機密情報テンプレート
├── compose.yaml                   # Docker Compose定義
├── Makefile                       # 開発自動化コマンド
├── README.md                      # プロジェクト概要
├── CLAUDE.md                      # このファイル（Claude向けガイド）
├── CONTRIBUTING.md                # 開発者向け実践ガイド
└── ARCHITECTURE.md                # 技術アーキテクチャ詳細
```

---

## ⚡ よく使うコマンド

### サービス管理

```bash
# 全サービス起動
make up

# 全サービス停止
make down

# 全サービスログ表示
make logs

# 完全クリーンアップ（注意：データ削除）
make clean
```

### Platform 基幹アプリ（ポート: 3001）

```bash
# Platform起動
make platform-up

# Railsコンソール
make platform-console

# マイグレーション実行
make platform-migrate

# コンテナシェル接続
make platform-shell
```

### Shrimp Shells EC（ポート: 3002）

```bash
# EC起動
make shrimpshells-up

# Railsコンソール
make shrimpshells-console

# マイグレーション実行
make shrimpshells-migrate

# データ投入
make shrimpshells-seed
```

### PostgreSQL

```bash
# PostgreSQLログ表示
make postgres-logs

# PostgreSQLシェル接続
make postgres-shell
```

### n8n、Mattermost

```bash
# n8nログ表示
make n8n-logs

# Mattermostログ表示
make mattermost-logs
```

---

## 🔍 「○○ したい」クイックリファレンス

### Solidus のカスタムフィールドを追加したい

**手順**:

1. マイグレーション作成
2. Decorator 作成
3. ビュー更新
4. テスト追加

**例**:

```bash
# 1. マイグレーション
cd rails/shrimp_shells_ec
bin/rails generate migration AddShrimpOriginToSpreeProducts shrimp_origin:string

# 2. Decorator作成
# app/models/spree/product_decorator.rb
module Spree
  module ProductDecorator
    def self.prepended(base)
      base.validates :shrimp_origin, length: { maximum: 100 }
    end
  end
end

Spree::Product.prepend(Spree::ProductDecorator)

# 3. マイグレーション実行
make shrimpshells-migrate

# 4. テスト
# spec/models/spree/product_decorator_spec.rb
RSpec.describe Spree::Product, type: :model do
  describe '#shrimp_origin' do
    it 'accepts valid origin' do
      product = build(:product, shrimp_origin: '沖縄県産')
      expect(product).to be_valid
    end
  end
end
```

### 新しい API エンドポイントを追加したい（Platform）

**手順**:

1. ルーティング追加
2. コントローラー作成
3. サービスオブジェクト作成（複雑なロジックの場合）
4. テスト追加

**例**:

```ruby
# 1. config/routes.rb
namespace :api do
  namespace :v1 do
    resources :cleaning_standards, only: [:index, :show, :create, :update]
  end
end

# 2. app/controllers/api/v1/cleaning_standards_controller.rb
class Api::V1::CleaningStandardsController < Api::V1::BaseController
  before_action :set_current_client

  def index
    @standards = CleaningStandard.for_client(@current_client.code)
    render json: @standards
  end

  def create
    @standard = CleaningStandard.new(standard_params)
    @standard.client_code = @current_client.code

    if @standard.save
      render json: @standard, status: :created
    else
      render json: { errors: @standard.errors }, status: :unprocessable_entity
    end
  end

  private

  def standard_params
    params.require(:cleaning_standard).permit(:room_type, :check_items, :threshold)
  end
end

# 3. spec/requests/api/v1/cleaning_standards_spec.rb
RSpec.describe 'Api::V1::CleaningStandards', type: :request do
  describe 'POST /api/v1/cleaning_standards' do
    it 'creates a new cleaning standard' do
      post '/api/v1/cleaning_standards',
        params: { cleaning_standard: { room_type: 'deluxe', threshold: 0.8 } },
        headers: { 'X-Client-Code' => 'shrimp_shells' }

      expect(response).to have_http_status(:created)
    end
  end
end
```

### 新しいクライアント（テナント）を追加したい

**手順**:

1. Client レコード作成
2. n8n Projects で新規 Project 作成
3. Mattermost Teams で新規 Team 作成
4. フロントサービス作成（必要に応じて）

**例**:

```ruby
# 1. Platformで新規クライアント作成
# rails/platform/db/seeds.rb または Railsコンソール
Client.create!(
  code: 'hotel_example',
  name: 'ホテルエグザンプル',
  industry: 'hotel',
  subscription_plan: 'standard',
  active: true
)

# 2. n8n (http://localhost:5678)
# - Projects → Create New Project
# - Name: "Hotel Example"

# 3. Mattermost (http://localhost:8065)
# - Teams → Create New Team
# - Name: "Hotel Example Team"

# 4. 新しいフロントサービス（hotel ECサイト等）作成（必要に応じて）
# rails/hotel_ec/ を作成
```

### マイグレーションを作成したい

**Platform**:

```bash
cd rails/platform
bin/rails generate migration CreateClients code:string name:string industry:string
make platform-migrate
```

**Shrimp Shells EC**:

```bash
cd rails/shrimp_shells_ec
bin/rails generate migration AddExpiryDateToSpreeStockItems expiry_date:date
make shrimpshells-migrate
```

### テストを実行したい

**Platform**:

```bash
cd rails/platform
bundle exec rspec

# 特定のファイル
bundle exec rspec spec/models/client_spec.rb

# 特定の行
bundle exec rspec spec/models/client_spec.rb:10
```

**Shrimp Shells EC**:

```bash
cd rails/shrimp_shells_ec
bundle exec rspec spec/models/spree/product_decorator_spec.rb
```

---

## 🔧 トラブルシューティング

### Solidus の拡張が反映されない

**症状**: Decorator で追加したメソッドが呼び出せない

**原因**: `prepend`の適用漏れ

**解決**:

```ruby
# ファイル末尾に必ず追加
Spree::Product.prepend(Spree::ProductDecorator)

# Railsサーバー再起動
make shrimpshells-down
make shrimpshells-up
```

### client_code スコープが漏れた

**症状**: 他のクライアントのデータが見える

**原因**: `for_client(code)`スコープの使用漏れ

**解決**:

```ruby
# ❌ NG
@products = Spree::Product.all

# ✅ OK
@products = Spree::Product.for_client(@current_client.code)

# コントローラーで必ずset_current_clientを実行
before_action :set_current_client
```

### マイグレーションが失敗する

**症状**: `ActiveRecord::PendingMigrationError`

**原因**: マイグレーション未実行

**解決**:

```bash
# Platform
make platform-migrate

# Shrimp Shells EC
make shrimpshells-migrate

# 強制的にリセット（開発環境のみ）
cd rails/platform
bin/rails db:reset
```

### n8n ワークフローがクライアントを混同している

**症状**: ワークフローが別クライアントのデータにアクセス

**原因**: Project 分離されていない

**解決**:

1. n8n (http://localhost:5678) にアクセス
2. Projects → Create New Project
3. クライアント毎に Project を作成
4. ワークフローを Project 内で作成

### Docker コンテナが起動しない

**症状**: `docker compose up` が失敗

**原因**: ポート競合、データ破損

**解決**:

```bash
# ポート確認
lsof -i :3001  # Platform
lsof -i :3002  # Shrimp Shells EC
lsof -i :5678  # n8n
lsof -i :8065  # Mattermost

# 完全クリーンアップ（注意：データ削除）
make clean
make up
```

---

## 📚 さらに詳しく学ぶ

### ドキュメント階層

```
概要を知りたい → README.md
     ↓
開発に参加したい → CONTRIBUTING.md
     ↓
設計判断の背景を知りたい → docs/adr/*.md
     ↓
技術アーキテクチャを深く理解したい → ARCHITECTURE.md
     ↓
ビジネス・企業情報を知りたい → docs/company-overview.md
```

### ドキュメント別用途

| ドキュメント                 | 用途                                                 | 対象読者             |
| ---------------------------- | ---------------------------------------------------- | -------------------- |
| **README.md**                | プロジェクト概要、クイックスタート                   | 全員                 |
| **CLAUDE.md**                | Claude 向けクイックリファレンス                      | AI 開発アシスタント  |
| **CONTRIBUTING.md**          | 環境セットアップ、Git/コミット規約、コーディング規約 | 開発者               |
| **ARCHITECTURE.md**          | 技術アーキテクチャ詳細、データベース設計、API 設計   | 開発者、アーキテクト |
| **docs/adr/\*.md**           | 設計判断の背景・理由                                 | 開発者、アーキテクト |
| **docs/company-overview.md** | ビジョン・ミッション、料金体系                       | 全員                 |

---

## 🎓 よくある質問（FAQ）

### Q1: なぜ Rails と Next.js の両方を使うのか？

**A**:

- **Rails**: バックオフィス、API 提供、データ処理（MVC/CRUD/REST に忠実、scaffold 機能）
- **Next.js**: マーケティングサイト（将来、マーケティングしやすいという理由のみ）

現時点では Rails のみ。Next.js はマーケティング必要性が生じたら導入。

### Q2: なぜ Solidus を選んだのか？

**A**:

- EC サイトを複数立ち上げる可能性があるため、**80%までは自動で生成**したかった
- Rails + Solidus であれば、自前実装部分が少ない
- 冷凍食品の特殊性（保管温度、賞味期限等）は**PoC**レベルで Decorator 拡張

### Q3: なぜ物理分離ではなく論理分離なのか？

**A**:

- **管理を複雑にしないため**
- 分離する明確な理由ができるまでは、論理分離（client_code）で十分
- 将来、必要に応じて物理分離へ移行可能（YAGNI 原則）

### Q4: Platform と Shrimp Shells EC の違いは？

**A**:
| 項目 | Platform | Shrimp Shells EC |
|------|----------|------------------|
| **責務** | 全クライアント共通機能 | restaurant 固有 EC 機能 |
| **例** | クライアント管理、清掃管理、AI 判定 | 冷凍食品販売、在庫管理 |
| **ポート** | 3001 | 3002 |
| **技術** | Rails 8 | Rails 8 + Solidus |
| **データ** | マルチテナント | クライアント固有 |

### Q5: n8n の Projects 機能とは？

**A**:

- n8n 2.1.1 で提供される**ワークフロー管理機能**
- Project 単位でワークフロー・クレデンシャルを**完全分離**
- クライアント毎に Project を作成することで、マルチテナント対応

### Q6: コミットメッセージの (issue#XX) は必須？

**A**:

- **必須**（Issue に紐付けることで、変更履歴を追跡可能）
- Conventional Commits: `<type>(<scope>): <subject> (issue#<番号>)`

---

## 💡 Claude 向け Tips

### コード生成時の注意点

1. **Solidus は Decorator パターンを必ず使用**:

   - Solidus 拡張は`prepend`で実装
   - 直接編集、Fork は絶対 NG

2. **client_code スコープを必ず使用**:

   - マルチテナントデータアクセスは`for_client(code)`
   - スコープなしのクエリは危険

3. **Service Object / ViewComponent パターン**:

   - 複雑なビジネスロジック → Service Object
   - 再利用可能な UI コンポーネント → ViewComponent

4. **テスト必須**:

   - 新機能追加時は必ず RSpec テストを追加
   - カバレッジ目標: 80%以上

5. **コミットメッセージ規約**:
   - Conventional Commits 形式
   - `(issue#XX)` を必ず含める

### 推奨する回答フォーマット

**問題解決時**:

```markdown
## 原因

（問題の原因を説明）

## 解決策

（具体的なコード例を提示）

## テスト

（テストコード例を提示）

## 参考

（関連ドキュメント、ADR 等へのリンク）
```

**実装提案時**:

```markdown
## 提案内容

（何を実装するか）

## 設計方針

（どのパターンを使うか、なぜか）

## 実装例

（具体的なコード例）

## テスト方針

（どのようにテストするか）

## 関連 ADR

（関連する設計判断記録）
```

---

## 🔗 関連リンク

- **GitHub Issues**: https://github.com/zomians/landbase_ai_suite/issues
- **Solidus Guides**: https://guides.solidus.io/
- **n8n Documentation**: https://docs.n8n.io/
- **Mattermost Documentation**: https://docs.mattermost.com/
- **Rails Guides**: https://guides.rubyonrails.org/

---

**Last Updated**: 2025-12-07
**Version**: 1.0
