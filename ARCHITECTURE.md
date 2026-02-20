# アーキテクチャ設計書

LandBase AI Suite の技術アーキテクチャ詳細設計

**最終更新**: 2026-01-18
**バージョン**: 1.0

---

## 目次

- [システム概要](#システム概要)
- [アーキテクチャビジョン](#アーキテクチャビジョン)
- [システム構成](#システム構成)
- [データアーキテクチャ](#データアーキテクチャ)
- [アプリケーションアーキテクチャ](#アプリケーションアーキテクチャ)
- [設計パターン](#設計パターン)
- [API 設計](#api設計)
- [セキュリティアーキテクチャ](#セキュリティアーキテクチャ)
- [パフォーマンス設計](#パフォーマンス設計)
- [運用設計](#運用設計)
- [拡張性設計](#拡張性設計)
- [ADR 参照](#adr参照)

---

## システム概要

### ビジネス要求

LandBase AI Suite は、沖縄県北部の観光業事業者（ホテル、飲食店、ツアー会社など）をワンストップで総合的にサポートするマルチテナント SaaS プラットフォームである。

**主要サービス**:

- **OperationAI**: 業務自動化システム（清掃、在庫、シフト管理）
- **MarketingAI**: マーケティング戦略支援（分析、価格最適化、レコメンド）
- **ConciergeAI**: AI チャットコンシェルジュ（17 言語対応、予約管理、観光スポット推薦）
- **PersonalizeAI**: 顧客分析・CRM（顧客プロファイリング、パーソナライズ提案）
- **ReputationAI**: 口コミ分析・対応支援（感情分析、自動返信支援）
- **MarketingAI**: マーケティング戦略支援（顧客セグメント分析、SNS 戦略）
- **OperationAI**: 業務自動化システム（清掃・メンテナンス管理、シフト最適化）
- **InventoryAI**: スマート在庫管理（使用量予測、最適発注支援）
- **StaffEduAI**: AI スタッフトレーニング（オンライン学習、パフォーマンス分析）
- **フロントサービス**: クライアント業種別 Web サイト（EC、予約サイト）

**対象業種**:

- **restaurant**: 飲食店（冷凍食品 EC 等）
- **hotel**: 宿泊施設（予約サイト、清掃管理）
- **tour**: ツアー会社（体験プログラム予約）

### システム目標

1. **データドリブン経営の支援**: AI とデータ分析による戦略的意思決定
2. **業務効率化**: ワークフロー自動化による人的コスト削減
3. **マルチテナント対応**: 100+クライアントを単一プラットフォームで管理
4. **スケーラビリティ**: 成長に応じた段階的なスケーリング
5. **コスト効率**: OSS 活用による低コスト運用

### 制約条件

1. **技術スタック**: OSS（オープンソースソフトウェア）優先
2. **開発速度**: Rails scaffold による高速開発
3. **保守性**: 非侵襲的拡張（Decorator パターン）
4. **シンプルさ**: 過剰設計を避け、必要十分な設計

---

## アーキテクチャビジョン

### マルチテナント SaaS アーキテクチャ

LandBase AI Suite は、**バックオフィス（共通基盤）とフロントサービス（クライアント固有）を分離**したマルチテナント構成を採用する。

#### 設計原則

1. **関心の分離**:

   - **バックオフィス**: 全クライアント共通の AI・自動化・管理機能
   - **フロントサービス**: クライアント業種別の UI・予約・販売機能

2. **独立性**:

   - ディレクトリ・コンテナレベルでの分離
   - 将来の物理分離を容易にする設計

3. **再利用性**:

   - 共通機能（清掃管理等）を全業種で再利用
   - 業種別フロントサービスのテンプレート化

4. **技術的堅実性**:
   - MVC、CRUD、REST といった基本概念への忠実性
   - 実績ある OSS の活用

#### テナント分離戦略

| レイヤー             | 分離方法             | 詳細                                 |
| -------------------- | -------------------- | ------------------------------------ |
| **n8n**              | Projects 機能        | 単一インスタンス、Project 単位で分離 |
| **Mattermost**       | Teams 機能           | 単一インスタンス、Team 単位で分離    |
| **PostgreSQL**       | client_code 論理分離 | 単一 DB、WHERE 句で分離              |
| **Rails Platform**   | client_code スコープ | スコープ・before_action で分離       |
| **フロントサービス** | 独立コンテナ         | ディレクトリ・コンテナ完全分離       |

**詳細**: [ADR 0005: マルチテナント実装戦略](./docs/adr/0005-multitenancy-strategy.md)

#### スケーリング戦略

**Phase 1** (現在): 論理分離

- 全サービス・DB は論理分離
- 単一サーバー環境

**Phase 2** (成長期): ハイブリッド

- 大規模クライアントのフロントサービスを別サーバーに移行
- バックオフィスは共通維持

**Phase 3** (大規模化): 物理分離

- クライアント毎に独立インフラ
- バックオフィス API のみ共有

---

## システム構成

### 全体構成図

```
┌─────────────────────────────────────────────────────────┐
│              LandBase AI Suite Platform                 │
└─────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌────▼────┐      ┌─────▼──────┐    ┌─────▼──────┐
   │   n8n   │      │ Mattermost │    │ PostgreSQL │
   │ (2.1.1)│     │   (9.11)   │    │ (16-alpine)│
   └────┬────┘      └────────────┘    └─────┬──────┘
        │                                    │
        │           ┌────────────────────────┼─────────┐
        │           │                        │         │
   ┌────▼───────────▼────┐          ┌───────▼────┐ ┌──▼──────────┐
   │ Platform (Rails 8) │          │  Shrimp    │ │  Hotel App  │
   │ :3000              │          │  Shells EC │ │  (将来)     │
   │                    │          │  :3002     │ │  :3004      │
   │ - クライアント管理  │          │            │ │             │
   │ - OperationAI      │          │            │ │ - 予約      │
   │ - 清掃管理         │          │ - EC       │ │ - 清掃      │
   │ - プラットフォームAPI│         └────────────┘ └─────────────┘
   └────────────────────┘           フロントサービス
    バックオフィス（共通）          (クライアント固有)
```

### レイヤー構成

#### 1. インフラストラクチャ層

| コンポーネント           | 技術           | バージョン | 役割               |
| ------------------------ | -------------- | ---------- | ------------------ |
| **コンテナ化**           | Docker         | 20.10+     | 環境統一           |
| **オーケストレーション** | Docker Compose | 2.0+       | マルチコンテナ管理 |
| **データベース**         | PostgreSQL     | 16-alpine  | データ永続化       |

#### 2. 自動化・コミュニケーション層

| コンポーネント               | 技術       | バージョン | 役割                   |
| ---------------------------- | ---------- | ---------- | ---------------------- |
| **ワークフロー自動化**       | n8n        | 2.1.1    | OperationAI のコア     |
| **チームコミュニケーション** | Mattermost | 9.11       | クライアント別チャット |

#### 3. アプリケーション層

| コンポーネント        | 技術            | バージョン | 役割          |
| --------------------- | --------------- | ---------- | ------------- |
| **Platform 基幹**     | Ruby on Rails   | 8.0.2.1    | API、管理、AI |
| **フロントサービス** | クライアント別 | -          | クライアント固有機能 |
| **Hotel App（将来）** | Rails（予定）   | 8.0        | 予約サイト    |

#### 4. プレゼンテーション層

| コンポーネント   | 技術               | 役割                         |
| ---------------- | ------------------ | ---------------------------- |
| **Stimulus**     | @hotwired/stimulus | インタラクティブ UI          |
| **Tailwind CSS** | tailwindcss        | ユーティリティファースト CSS |

---

## データアーキテクチャ

### データベース設計

#### データベース構成

```
PostgreSQL 16-alpine
├── platform_development        # Platform基幹アプリDB
│   ├── clients                 # クライアント管理
│   ├── cleaning_standards      # 清掃基準
│   ├── cleaning_sessions       # 清掃報告
│   ├── journal_entries         # 仕訳データ（経理自動化）
│   └── account_masters         # 勘定科目マスター（経理自動化）
└── （将来）hotel_app_development
```

#### 主要テーブル設計

**Platform 基幹アプリ**:

```sql
-- クライアント管理
CREATE TABLE clients (
  id SERIAL PRIMARY KEY,
  code VARCHAR UNIQUE NOT NULL,      -- 'shrimp_shells'
  name VARCHAR NOT NULL,               -- 'Shrimp Shells'
  industry VARCHAR,                    -- 'restaurant'
  services JSONB DEFAULT '{}',         -- サービス設定
  status VARCHAR DEFAULT 'active',     -- ステータス
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- 清掃基準（hotel向け）
CREATE TABLE cleaning_standards (
  id SERIAL PRIMARY KEY,
  client_code VARCHAR NOT NULL,        -- テナント分離
  room_type VARCHAR NOT NULL,          -- 部屋タイプ
  area VARCHAR NOT NULL,               -- 清掃エリア
  description TEXT,                    -- 基準説明
  reference_images JSONB,              -- 参照画像（Active Storage）
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (client_code) REFERENCES clients(code)
);

-- 清掃セッション
CREATE TABLE cleaning_sessions (
  id SERIAL PRIMARY KEY,
  client_code VARCHAR NOT NULL,
  room_number VARCHAR,
  judge_result VARCHAR,                -- 'passed', 'failed'
  judge_score INTEGER,
  judge_details JSONB,
  judged_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- 仕訳データ（経理自動化）
CREATE TABLE journal_entries (
  id BIGSERIAL PRIMARY KEY,
  client_id BIGINT NOT NULL REFERENCES clients(id),  -- クライアント
  source_type VARCHAR NOT NULL,          -- 'amex' / 'bank' / 'invoice' / 'receipt'
  source_period VARCHAR,                 -- 明細期間（例: '2026-01'）
  transaction_no INTEGER,                -- 取引番号
  date DATE NOT NULL,                    -- 取引日
  debit_account VARCHAR NOT NULL,        -- 借方勘定科目
  debit_sub_account VARCHAR DEFAULT '',  -- 借方補助科目
  debit_department VARCHAR DEFAULT '',   -- 借方部門
  debit_partner VARCHAR DEFAULT '',      -- 借方取引先
  debit_tax_category VARCHAR DEFAULT '', -- 借方税区分
  debit_invoice VARCHAR DEFAULT '',      -- 借方インボイス
  debit_amount INTEGER NOT NULL,         -- 借方金額
  credit_account VARCHAR NOT NULL,       -- 貸方勘定科目
  credit_sub_account VARCHAR DEFAULT '', -- 貸方補助科目
  credit_department VARCHAR DEFAULT '',  -- 貸方部門
  credit_partner VARCHAR DEFAULT '',     -- 貸方取引先
  credit_tax_category VARCHAR DEFAULT '',-- 貸方税区分
  credit_invoice VARCHAR DEFAULT '',     -- 貸方インボイス
  credit_amount INTEGER NOT NULL,        -- 貸方金額
  description TEXT DEFAULT '',           -- 摘要
  tag VARCHAR DEFAULT '',                -- タグ
  memo TEXT DEFAULT '',                  -- メモ
  cardholder VARCHAR DEFAULT '',         -- カード利用者（Amex等の複数会員明細用）
  status VARCHAR DEFAULT 'ok',           -- 'ok' / 'review_required'
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
-- INDEX: client_id, (source_type, source_period), date, status

-- 勘定科目マスター（経理自動化）
CREATE TABLE account_masters (
  id BIGSERIAL PRIMARY KEY,
  client_id BIGINT NOT NULL REFERENCES clients(id),  -- クライアント
  source_type VARCHAR,                   -- 入力元区別（NULLは全ソース共通）
  merchant_keyword VARCHAR,              -- 店舗名キーワード
  description_keyword VARCHAR,           -- 取引内容キーワード
  account_category VARCHAR NOT NULL,     -- 勘定科目カテゴリ
  confidence_score INTEGER DEFAULT 50,   -- 信頼度スコア（0-100）
  last_used_date DATE,                   -- 最終使用日
  usage_count INTEGER DEFAULT 0,         -- 使用回数
  auto_learned BOOLEAN DEFAULT false,    -- 自動学習フラグ
  notes TEXT DEFAULT '',                 -- 備考
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
-- INDEX: client_id, (client_id, source_type), merchant_keyword
```

**フロントサービス（別リポジトリ）**:

フロントサービス固有のデータモデルやカスタムフィールドは各リポジトリで管理します。

### データモデル設計原則

#### 1. マルチテナント分離

**原則**: すべてのテーブルに `client_code` カラムを追加（Platform 基幹アプリ）

```ruby
# ✅ GOOD: client_code スコープを必ず使用
CleaningStandard.for_client('shrimp_shells')

# ❌ BAD: スコープなしのクエリ（全テナントデータ取得）
CleaningStandard.all  # 危険！
```

#### 2. JSON/JSONB カラム活用

**柔軟なデータ構造**:

```ruby
# 栄養成分（構造が動的）
add_column :spree_products, :nutritional_info, :json

# サービス設定（頻繁に検索）
add_column :clients, :services, :jsonb, default: {}
add_index :clients, :services, using: :gin
```

#### 3. カラムコメント必須

```ruby
add_column :spree_products, :storage_temperature, :decimal,
  comment: "保管温度（℃）、冷凍食品は0℃未満"
```

---

## アプリケーションアーキテクチャ

### Rails Platform（基幹アプリ）

**ディレクトリ構造**:

```
rails/platform/
├── app/
│   ├── models/                    # ビジネスロジック
│   │   ├── application_record.rb  # 基底クラス
│   │   ├── client.rb              # クライアント管理
│   │   ├── cleaning_standard.rb   # 清掃基準
│   │   └── cleaning_session.rb    # 清掃報告
│   │
│   ├── controllers/               # リクエスト処理
│   │   └── api/v1/
│   │       ├── clients_controller.rb
│   │       ├── cleaning_standards_controller.rb
│   │       └── cleaning_sessions_controller.rb
│   │
│   ├── services/                  # ビジネスロジック抽出
│   │   ├── cleaning_judge_service.rb      # AI判定
│   │   ├── manual_generator_service.rb    # PDF生成
│   │   └── mattermost_notifier_service.rb # 通知
│   │
│   ├── jobs/                      # バックグラウンド処理
│   │   ├── cleaning_judge_job.rb
│   │   └── image_cleanup_job.rb
│   │
│   └── views/                     # 管理画面（将来）
│
├── config/
│   ├── routes.rb                  # ルーティング定義
│   └── database.yml               # DB接続設定
│
├── db/
│   └── migrate/                   # マイグレーション
│
└── spec/                          # RSpecテスト
```

**責務**:

- **クライアント管理**: CRUD、サービス設定
- **OperationAI**: 清掃管理、在庫管理（将来）
- **MarketingAI**: データ分析、価格最適化（将来）
- **API 提供**: n8n ワークフロー連携、フロントサービス連携
- **管理画面**: プラットフォーム管理者向け UI（将来）

**詳細**: [ADR 0006: Platform 基幹アプリ分離](./docs/adr/0006-platform-app-separation.md)

### フロントサービス（クライアント固有）

フロントサービスはクライアント別に独立し、別リポジトリで管理します。
（例: Shrimp Shells EC）

---

## 設計パターン

### 1. Service Object パターン

**目的**: 複雑なビジネスロジックをモデル・コントローラーから分離

**実装**:

```ruby
# app/services/cleaning_judge_service.rb
class CleaningJudgeService
  def initialize(cleaning_session:, ai_client: nil)
    @session = cleaning_session
    @ai_client = ai_client || OpenAI::Client.new
  end

  def call
    return failure("画像が未添付です") if @session.images.blank?

    results = judge_all_images
    overall_result = calculate_overall_result(results)

    update_session(overall_result, results)
    notify_result(overall_result)

    success(overall_result)
  rescue StandardError => e
    Rails.logger.error("Cleaning judge failed: #{e.message}")
    failure(e.message)
  end

  private

  def judge_all_images
    @session.images.map { |image| judge_single_image(image) }
  end

  def judge_single_image(image)
    response = @ai_client.chat(
      parameters: {
        model: "gpt-4-vision-preview",
        messages: [{ role: "user", content: build_prompt(image) }]
      }
    )
    parse_ai_response(response)
  end

  def success(data)
    OpenStruct.new(success?: true, data: data)
  end

  def failure(error)
    OpenStruct.new(success?: false, error: error)
  end
end
```

**使用**:

```ruby
# コントローラー
result = CleaningJudgeService.new(cleaning_session: session).call
if result.success?
  render json: { result: result.data }, status: :ok
else
  render json: { error: result.error }, status: :unprocessable_entity
end
```

### 2. Query Object パターン

**目的**: 複雑なクエリロジックをモデルから分離

**実装**:

```ruby
# app/queries/products_query.rb
class ProductsQuery
  def initialize(relation = Spree::Product.all)
    @relation = relation.available
  end

  def filter(params)
    @relation = by_shrimp_size(params[:shrimp_size])
    @relation = by_origin(params[:shrimp_origin])
    @relation = exclude_allergens(params[:exclude_allergens])
    @relation = sort_by(params[:sort])
    self
  end

  def results
    @relation
  end

  private

  def by_shrimp_size(size)
    size.present? ? @relation.by_shrimp_size(size) : @relation
  end

  def exclude_allergens(allergens)
    return @relation if allergens.blank?

    allergens.split(',').each do |allergen|
      @relation = @relation.where.not("allergens ILIKE ?", "%#{allergen}%")
    end
    @relation
  end

  def sort_by(sort_key)
    case sort_key
    when 'price_asc'  then @relation.order(price: :asc)
    when 'price_desc' then @relation.order(price: :desc)
    when 'newest'     then @relation.order(created_at: :desc)
    else @relation.order(name: :asc)
    end
  end
end
```

**使用**:

```ruby
products = ProductsQuery.new.filter(params).results.page(params[:page])
```

---

## API 設計

### RESTful API 原則

**Platform 基幹アプリ API**:

```
GET    /api/v1/clients                           # クライアント一覧
GET    /api/v1/clients/:code                     # クライアント詳細
POST   /api/v1/clients                           # クライアント作成

GET    /api/v1/cleaning_standards                # 清掃基準一覧
GET    /api/v1/cleaning_standards/:id            # 清掃基準詳細
POST   /api/v1/cleaning_standards                # 清掃基準作成
POST   /api/v1/cleaning_standards/:id/attach_image  # 画像添付
GET    /api/v1/cleaning_standards/:id/manual     # マニュアルPDF生成

POST   /api/v1/cleaning_sessions                 # セッション作成
GET    /api/v1/cleaning_sessions/:id             # セッション詳細
POST   /api/v1/cleaning_images                   # 画像保存
```

### バージョニング戦略

- **URL バージョニング**: `/api/v1/`, `/api/v2/`
- **後方互換性**: v1 を維持しつつ v2 を追加
- **廃止予定**: ヘッダーで通知 `X-API-Deprecated: true`

### 認証・認可

**トークンベース認証**:

```ruby
# リクエストヘッダー
Authorization: Bearer <JWT_TOKEN>
X-Client-Code: shrimp_shells

# コントローラー
class Api::V1::BaseController < ApplicationController
  before_action :authenticate_token
  before_action :set_current_client

  private

  def authenticate_token
    token = request.headers['Authorization']&.split(' ')&.last
    payload = JWT.decode(token, Rails.application.credentials.secret_key_base)
    @current_user = User.find(payload['user_id'])
  rescue JWT::DecodeError
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def set_current_client
    @current_client = Client.find_by!(code: request.headers['X-Client-Code'])
  end
end
```

### エラーハンドリング

**統一エラーレスポンス**:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "バリデーションエラーが発生しました",
    "details": [
      {
        "field": "shrimp_size",
        "message": "は一覧にありません"
      }
    ]
  }
}
```

**HTTP ステータスコード**:

- `200 OK`: 成功
- `201 Created`: 作成成功
- `400 Bad Request`: リクエストエラー
- `401 Unauthorized`: 認証エラー
- `403 Forbidden`: 権限エラー
- `404 Not Found`: リソースが存在しない
- `422 Unprocessable Entity`: バリデーションエラー
- `500 Internal Server Error`: サーバーエラー

---

## セキュリティアーキテクチャ

### 認証設計

**フロントサービス**:

- **各サービス固有**: サービス毎に選定

**Platform 基幹アプリ**:

- **JWT**: トークンベース認証
- **有効期限**: 24 時間
- **リフレッシュトークン**: 7 日間

### 認可設計

**マルチテナント分離**:

```ruby
# client_code による強制的なスコープ適用
class Api::V1::BaseController < ApplicationController
  before_action :enforce_tenant_scope

  private

  def enforce_tenant_scope
    # すべてのクエリに client_code を強制適用
    ApplicationRecord.current_client = @current_client
  end
end

class ApplicationRecord < ActiveRecord::Base
  def self.current_client=(client)
    Thread.current[:current_client] = client
  end

  def self.current_client
    Thread.current[:current_client]
  end

  default_scope -> {
    where(client_code: current_client&.code) if column_names.include?('client_code')
  }
end
```

### データ保護

1. **SQL インジェクション対策**: パラメータバインディング必須
2. **XSS 対策**: ERB 自動エスケープ、CSP 設定
3. **CSRF 対策**: Rails 標準トークン
4. **機密情報**: Rails Credentials、環境変数

### OWASP Top 10 対応

| 脅威                                            | 対策                                  |
| ----------------------------------------------- | ------------------------------------- |
| **Injection**                                   | パラメータバインディング、ORM 使用    |
| **Broken Authentication**                       | Devise、JWT、強力なパスワードポリシー |
| **Sensitive Data Exposure**                     | HTTPS 必須、Credentials 暗号化        |
| **XXE**                                         | XML パーサー設定、JSON 優先           |
| **Broken Access Control**                       | client_code スコープ、認可チェック    |
| **Security Misconfiguration**                   | 本番環境設定チェックリスト            |
| **XSS**                                         | ERB 自動エスケープ、CSP               |
| **Insecure Deserialization**                    | 信頼できるデータのみデシリアライズ    |
| **Using Components with Known Vulnerabilities** | Bundler Audit、Dependabot             |
| **Insufficient Logging & Monitoring**           | Rails Logger、エラートラッキング      |

---

## パフォーマンス設計

### キャッシング戦略

**Solid Cache 活用**:

```ruby
# config/environments/production.rb
config.cache_store = :solid_cache_store

# 使用例
Rails.cache.fetch("products/#{product.id}", expires_in: 1.hour) do
  product.to_json
end
```

**フラグメントキャッシュ**:

```erb
<% cache product do %>
  <%= render ProductCardComponent.new(product: product) %>
<% end %>
```

### N+1 クエリ回避

**Eager Loading 必須**:

```ruby
# ✅ GOOD
@products = Product.includes(:images, :variants, :taxons).all

# ❌ BAD
@products = Product.all
@products.each { |p| p.images.first }  # N+1発生！
```

### インデックス戦略

**頻繁に検索するカラムにインデックス**:

```ruby
add_index :spree_products, :shrimp_size
add_index :spree_products, :client_code
add_index :spree_orders, [:user_id, :created_at]
add_index :clients, :code, unique: true
```

### バックグラウンドジョブ

**Solid Queue 活用**:

```ruby
# app/jobs/cleaning_judge_job.rb
class CleaningJudgeJob < ApplicationJob
  queue_as :default

  def perform(session_id)
    session = CleaningSession.find(session_id)
    CleaningJudgeService.new(cleaning_session: session).call
  end
end

# 非同期実行
CleaningJudgeJob.perform_later(session.id)
```

---

## 運用設計

### ログ管理

**Rails Logger**:

```ruby
# config/environments/production.rb
config.log_level = :info
config.log_tags = [:request_id, :client_code]

# 使用例
Rails.logger.info "Cleaning judge started: session_id=#{session.id}"
Rails.logger.error "AI request failed: #{e.message}"
```

**ログローテーション**:

```yaml
# logrotate設定
/path/to/app/log/*.log {
daily
missingok
rotate 14
compress
delaycompress
notifempty
copytruncate
}
```

### モニタリング

**健全性チェック**:

```ruby
# config/routes.rb
get '/health', to: 'health#index'

# app/controllers/health_controller.rb
class HealthController < ApplicationController
  def index
    ActiveRecord::Base.connection.execute('SELECT 1')
    render json: { status: 'ok' }, status: :ok
  rescue => e
    render json: { status: 'error', message: e.message }, status: :service_unavailable
  end
end
```

### バックアップ戦略

**PostgreSQL**:

```bash
# 日次バックアップ
pg_dump -h localhost -U postgres platform_production > backup_$(date +%Y%m%d).sql

# リストア
psql -h localhost -U postgres platform_production < backup_20251206.sql
```

---

## 拡張性設計

### 新クライアント追加フロー

1. **クライアント登録**:

   ```ruby
   Client.create!(
     code: 'new_hotel',
     name: 'New Hotel',
     industry: 'hotel',
     status: 'trial'
   )
   ```

2. **n8n Project 作成**: 管理画面で手動作成

3. **Mattermost Team 作成**: 管理画面で手動作成

4. **フロントサービス作成（必要に応じて）**:
   ```bash
   # hotel向けフロントサービス
   mkdir rails/new_hotel_booking
   make hotel-new
   ```

### 新機能追加パターン

**共通機能（Platform）**:

1. モデル作成: `rails g model Feature client_code:string`
2. API 実装: `rails g controller Api::V1::Features`
3. サービス層: `app/services/feature_service.rb`
4. テスト: `spec/models/feature_spec.rb`

**クライアント固有機能（EC 等）**:

1. Decorator 作成: `app/models/spree/model_decorator.rb`
2. マイグレーション: `rails g migration AddFieldToSpreeModel`
3. テスト: `spec/models/spree/model_decorator_spec.rb`

### 技術スタック更新戦略

**Rails バージョンアップ**:

1. テスト環境で検証
2. 段階的ロールアウト

---

## ADR 参照

このアーキテクチャは、以下の ADR（Architecture Decision Records）に基づいて設計されています：

- **[ADR 0001: n8n + Mattermost + Rails 統合アーキテクチャ](./docs/adr/0001-n8n-mattermost-rails-integration.md)**

  - 基本技術スタックの選定
  - OSS 要件、Rails scaffold、マルチテナント対応

- **[ADR 0002: フロント/バックオフィス分離設計](./docs/adr/0002-frontend-backend-separation.md)**

  - バックオフィス（共通）とフロントサービス（クライアント固有）の分離
  - MarketingAI 連携、将来の分離可能性

- **[ADR 0005: マルチテナント実装戦略](./docs/adr/0005-multitenancy-strategy.md)**

  - n8n Projects、Mattermost Teams、client_code 論理分離
  - 将来の物理分離戦略

- **[ADR 0006: Platform 基幹アプリ分離](./docs/adr/0006-platform-app-separation.md)**
  - プラットフォーム共通機能の分離
  - 独立した Rails アプリ構成

---

## 参考リンク

- [開発ガイド](./CONTRIBUTING.md)
- [Claude 向けガイド](./CLAUDE.md)
- [ビジネス概要](./docs/business/company-overview.md)
- [Ruby on Rails Guides](https://guides.rubyonrails.org/)

---

**Document Version**: 1.0
**Last Updated**: 2025-12-06
**Maintained by**: 株式会社 AI.LandBase 開発チーム
