# Shrimp Shells EC: Solidus アーキテクチャ設計書

**プロジェクト**: LandBase AI Suite - Shrimp Shells EC
**技術スタック**: Rails 8.0.2.1 + Solidus v4.5 + PostgreSQL 16
**作成日**: 2025-01-14
**ステータス**: 設計フェーズ

---

## 1. プロジェクト概要

### 1.1 ビジネス要件

**商品**: ガーリックシュリンプ冷凍食品
**ターゲット**: 通販購入層（国内市場）
**ローンチ予定**: 2026年
**初期規模**: 1-5 SKU、月間~50件受注

### 1.2 技術要件

- Rails 8.0 + Solidus v4.5（最新版）
- landbase_ai_suite との完全統合
- PostgreSQL マルチスキーマによるデータ分離
- n8n 連携による自動化（受注通知、SNS投稿、顧客フォロー）
- AIドリブン管理会計との統合
- 冷凍食品特化機能（配送温度帯、賞味期限管理）

---

## 2. システムアーキテクチャ

### 2.1 全体構成図

```
┌───────────────────────────────────────────────────────────────┐
│           LandBase AI Suite (Multi-tenant Platform)           │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Platform Services (Internal Management)                 │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │  - n8n Platform (Port 5678)                             │ │
│  │  - Mattermost (Port 8065)                               │ │
│  │  - PostgreSQL Master (Port 5432)                        │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Shrimp Shells Client Services                          │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │                                                          │ │
│  │  ┌──────────────────────────────────────────┐          │ │
│  │  │  n8n Client (Port 5679)                  │          │ │
│  │  │  - Workflow Automation Engine            │          │ │
│  │  │  - PostgreSQL Schema: n8n_shrimp_shells  │          │ │
│  │  └──────────────────────────────────────────┘          │ │
│  │                        ↕                                 │ │
│  │  ┌──────────────────────────────────────────┐          │ │
│  │  │  Rails EC Application (Port 3000)        │◄─────────┼─┼─ Customer
│  │  ├──────────────────────────────────────────┤          │ │   (Browser)
│  │  │  ┌────────────────────────────────────┐  │          │ │
│  │  │  │  Solidus Core                      │  │          │ │
│  │  │  │  - Order Management                │  │          │ │
│  │  │  │  - Product Catalog                 │  │          │ │
│  │  │  │  - Inventory Management            │  │          │ │
│  │  │  │  - Payment Processing (Stripe)     │  │          │ │
│  │  │  │  - Shipping Management             │  │          │ │
│  │  │  └────────────────────────────────────┘  │          │ │
│  │  │                                           │          │ │
│  │  │  ┌────────────────────────────────────┐  │          │ │
│  │  │  │  Custom Extensions                 │  │          │ │
│  │  │  │  - Frozen Food Module              │  │          │ │
│  │  │  │  - Webhook Publisher               │  │          │ │
│  │  │  │  - AI Accounting Integration       │  │          │ │
│  │  │  └────────────────────────────────────┘  │          │ │
│  │  │                                           │          │ │
│  │  │  ┌────────────────────────────────────┐  │          │ │
│  │  │  │  Admin Dashboard                   │  │          │ │
│  │  │  │  - Solidus Backend                 │  │          │ │
│  │  │  │  - AI Assistant (Claude API)       │  │          │ │
│  │  │  │  - Management Accounting UI        │  │          │ │
│  │  │  └────────────────────────────────────┘  │          │ │
│  │  │                                           │          │ │
│  │  │  PostgreSQL Schema: ec_shrimp_shells     │          │ │
│  │  │  - spree_* (Solidus tables)              │          │ │
│  │  │  - frozen_products                       │          │ │
│  │  │  - temperature_zones                     │          │ │
│  │  └──────────────────────────────────────────┘          │ │
│  │                        ↕                                 │ │
│  │  ┌──────────────────────────────────────────┐          │ │
│  │  │  Management Accounting System            │          │ │
│  │  ├──────────────────────────────────────────┤          │ │
│  │  │  - Sales & Order Analytics               │          │ │
│  │  │  - Inventory & COGS Tracking             │          │ │
│  │  │  - Cost Management (Ads, Labor, Ops)     │          │ │
│  │  │  - KPI Dashboard (Margin, CAC, LTV)      │          │ │
│  │  │  - AI Assistant (Data Analysis)          │          │ │
│  │  │  - Conversational Queries (Claude API)   │          │ │
│  │  │                                           │          │ │
│  │  │  PostgreSQL Schema: accounting_shrimp    │          │ │
│  │  │  - sales_records                         │          │ │
│  │  │  - inventory_logs                        │          │ │
│  │  │  - expense_records                       │          │ │
│  │  │  - kpi_snapshots                         │          │ │
│  │  └──────────────────────────────────────────┘          │ │
│  │                                                          │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Shared PostgreSQL Database (Port 5432)                 │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │  ├─ public (Platform)                                   │ │
│  │  ├─ n8n_shrimp_shells (n8n workflows)                   │ │
│  │  ├─ ec_shrimp_shells (Solidus EC)                       │ │
│  │  └─ accounting_shrimp_shells (Management Accounting)    │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
└───────────────────────────────────────────────────────────────┘
                         ↕
    ┌──────────────────────────────────────────┐
    │  External Services                        │
    ├──────────────────────────────────────────┤
    │  - Stripe (Payment Gateway)              │
    │  - Instagram Graph API (SNS Auto-Post)   │
    │  - Claude API (AI Assistant)             │
    │  - SendGrid/AWS SES (Email Delivery)     │
    │  - Cloudflare CDN (Image Delivery)       │
    └──────────────────────────────────────────┘
```

---

## 3. データベース設計

### 3.1 PostgreSQL マルチスキーマ構成

#### スキーマ分離戦略

landbase_ai_suite の既存アーキテクチャに合わせて、PostgreSQL のスキーマ分離を採用します。

```sql
-- Platform Schema
public
  └─ client_configurations (クライアント設定マスター)

-- Shrimp Shells Schemas
n8n_shrimp_shells
  ├─ executions (n8n workflow executions)
  ├─ workflow_entity (n8n workflows)
  └─ ... (n8n standard tables)

ec_shrimp_shells
  ├─ spree_orders (注文)
  ├─ spree_products (商品)
  ├─ spree_variants (商品バリアント)
  ├─ spree_line_items (注文明細)
  ├─ spree_stock_items (在庫)
  ├─ spree_payments (決済)
  ├─ spree_shipments (配送)
  ├─ frozen_products (冷凍食品拡張)
  ├─ temperature_zones (温度帯マスター)
  └─ ... (Solidus standard tables)

accounting_shrimp_shells
  ├─ sales_records (売上記録)
  ├─ inventory_logs (在庫ログ)
  ├─ expense_records (経費記録)
  ├─ kpi_snapshots (KPI スナップショット)
  └─ ai_insights (AI 洞察記録)
```

#### マルチテナンシー実装

**使用Gem**: `ros-apartment` v3.2.0 (Rails 8.0 対応)

```ruby
# Gemfile
gem 'ros-apartment', '~> 3.2.0'

# config/initializers/apartment.rb
Apartment.configure do |config|
  config.excluded_models = ["ClientConfiguration"]
  config.tenant_names = -> { ClientConfiguration.pluck(:code) }
  config.use_schemas = true
  config.tenant_presence_check = true
end
```

**注意**: ros-apartment の Rails 8.0 サポートは実験的段階のため、本番環境デプロイ前の十分なテストが必要。

---

### 3.2 冷凍食品特化テーブル設計

```sql
-- ec_shrimp_shells.frozen_products
CREATE TABLE frozen_products (
  id BIGSERIAL PRIMARY KEY,
  spree_product_id BIGINT NOT NULL REFERENCES spree_products(id),
  storage_temperature_min INTEGER NOT NULL, -- 保存温度下限（-18℃など）
  storage_temperature_max INTEGER NOT NULL, -- 保存温度上限（-15℃など）
  expiration_months INTEGER NOT NULL,       -- 賞味期限（月数）
  defrost_method TEXT,                      -- 解凍方法
  defrost_time_hours INTEGER,               -- 解凍時間（時間）
  cooking_instructions TEXT,                -- 調理方法
  allergens TEXT[],                         -- アレルゲン（配列）
  nutritional_info JSONB,                   -- 栄養成分表示（JSON）
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ec_shrimp_shells.temperature_zones
CREATE TABLE temperature_zones (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,               -- 温度帯名（冷凍、冷蔵、常温）
  code VARCHAR(20) NOT NULL UNIQUE,         -- 温度帯コード（frozen, chilled, ambient）
  temperature_min INTEGER,                  -- 温度範囲下限
  temperature_max INTEGER,                  -- 温度範囲上限
  shipping_fee_multiplier DECIMAL(5,2),     -- 配送料倍率
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ec_shrimp_shells.shipments に温度帯カラム追加
ALTER TABLE spree_shipments
  ADD COLUMN temperature_zone_id BIGINT REFERENCES temperature_zones(id);
```

---

### 3.3 管理会計データモデル

```sql
-- accounting_shrimp_shells.sales_records
CREATE TABLE sales_records (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL,                 -- EC注文ID（ec_shrimp_shells.spree_orders.id）
  order_number VARCHAR(50) NOT NULL,        -- 注文番号
  ordered_at TIMESTAMP NOT NULL,            -- 注文日時
  customer_id BIGINT,                       -- 顧客ID
  product_id BIGINT NOT NULL,               -- 商品ID
  variant_id BIGINT NOT NULL,               -- バリアントID
  quantity INTEGER NOT NULL,                -- 数量
  unit_price DECIMAL(10,2) NOT NULL,        -- 単価
  total_amount DECIMAL(10,2) NOT NULL,      -- 売上合計
  cost_of_goods DECIMAL(10,2),              -- 原価
  gross_profit DECIMAL(10,2),               -- 粗利
  gross_margin_rate DECIMAL(5,2),           -- 粗利率
  payment_method VARCHAR(50),               -- 決済方法
  channel VARCHAR(50),                      -- 販売チャネル
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  INDEX idx_ordered_at (ordered_at),
  INDEX idx_product_id (product_id),
  INDEX idx_customer_id (customer_id)
);

-- accounting_shrimp_shells.inventory_logs
CREATE TABLE inventory_logs (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT NOT NULL,
  variant_id BIGINT NOT NULL,
  action_type VARCHAR(20) NOT NULL,         -- purchase, sale, adjustment, loss
  quantity_change INTEGER NOT NULL,         -- 増減数（+ or -）
  stock_after INTEGER NOT NULL,             -- 処理後在庫数
  unit_cost DECIMAL(10,2),                  -- 仕入単価
  total_cost DECIMAL(10,2),                 -- 仕入合計
  related_order_id BIGINT,                  -- 関連注文ID
  note TEXT,                                -- 備考
  recorded_at TIMESTAMP NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),

  INDEX idx_product_variant (product_id, variant_id),
  INDEX idx_recorded_at (recorded_at)
);

-- accounting_shrimp_shells.expense_records
CREATE TABLE expense_records (
  id BIGSERIAL PRIMARY KEY,
  category VARCHAR(50) NOT NULL,            -- ads, labor, shipping, ops, other
  subcategory VARCHAR(100),                 -- 詳細カテゴリ（Google Ads, Facebook Ads等）
  amount DECIMAL(10,2) NOT NULL,            -- 金額
  expense_date DATE NOT NULL,               -- 経費日
  vendor VARCHAR(200),                      -- 支払先
  description TEXT,                         -- 説明
  receipt_url TEXT,                         -- 領収書URL
  payment_method VARCHAR(50),               -- 支払方法
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  INDEX idx_category (category),
  INDEX idx_expense_date (expense_date)
);

-- accounting_shrimp_shells.kpi_snapshots
CREATE TABLE kpi_snapshots (
  id BIGSERIAL PRIMARY KEY,
  snapshot_date DATE NOT NULL,              -- スナップショット日
  period_type VARCHAR(20) NOT NULL,         -- daily, weekly, monthly

  -- 売上KPI
  total_revenue DECIMAL(12,2),              -- 総売上
  total_orders INTEGER,                     -- 総注文数
  avg_order_value DECIMAL(10,2),            -- 平均注文額

  -- 利益KPI
  total_cogs DECIMAL(12,2),                 -- 総売上原価
  gross_profit DECIMAL(12,2),               -- 粗利益
  gross_margin_rate DECIMAL(5,2),           -- 粗利率

  -- 経費KPI
  total_expenses DECIMAL(12,2),             -- 総経費
  ad_spend DECIMAL(10,2),                   -- 広告費
  labor_cost DECIMAL(10,2),                 -- 人件費
  shipping_cost DECIMAL(10,2),              -- 配送費
  ops_cost DECIMAL(10,2),                   -- 運営費

  -- 顧客KPI
  new_customers INTEGER,                    -- 新規顧客数
  repeat_customers INTEGER,                 -- リピート顧客数
  customer_acquisition_cost DECIMAL(10,2),  -- CAC
  customer_lifetime_value DECIMAL(10,2),    -- LTV

  -- 在庫KPI
  stock_value DECIMAL(12,2),                -- 在庫評価額
  stock_turnover_rate DECIMAL(5,2),         -- 在庫回転率

  created_at TIMESTAMP NOT NULL DEFAULT NOW(),

  UNIQUE (snapshot_date, period_type),
  INDEX idx_snapshot_date (snapshot_date),
  INDEX idx_period_type (period_type)
);

-- accounting_shrimp_shells.ai_insights
CREATE TABLE ai_insights (
  id BIGSERIAL PRIMARY KEY,
  insight_type VARCHAR(50) NOT NULL,        -- trend_analysis, anomaly_detection, recommendation
  title VARCHAR(200) NOT NULL,              -- 洞察タイトル
  content TEXT NOT NULL,                    -- AI生成コンテンツ
  priority VARCHAR(20),                     -- low, medium, high, critical
  related_metrics JSONB,                    -- 関連メトリクス（JSON）
  generated_by VARCHAR(50),                 -- claude-3-5-sonnet-20250514 等
  generated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  reviewed_by_user BOOLEAN DEFAULT false,   -- ユーザー確認済みフラグ
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),

  INDEX idx_insight_type (insight_type),
  INDEX idx_generated_at (generated_at)
);
```

---

## 4. アプリケーション設計

### 4.1 Rails アプリケーション構成

```
rails/
├── app/
│   ├── models/
│   │   ├── spree/                    # Solidus標準モデル
│   │   │   ├── order.rb
│   │   │   ├── product.rb
│   │   │   └── ...
│   │   ├── frozen_product.rb         # 冷凍食品モデル
│   │   ├── temperature_zone.rb       # 温度帯モデル
│   │   └── accounting/               # 管理会計モデル
│   │       ├── sales_record.rb
│   │       ├── inventory_log.rb
│   │       ├── expense_record.rb
│   │       ├── kpi_snapshot.rb
│   │       └── ai_insight.rb
│   │
│   ├── controllers/
│   │   ├── spree/                    # Solidus標準コントローラー
│   │   ├── webhooks/                 # Webhook エンドポイント
│   │   │   └── orders_controller.rb
│   │   └── admin/                    # 管理画面
│   │       ├── accounting/
│   │       │   ├── dashboard_controller.rb
│   │       │   ├── sales_controller.rb
│   │       │   ├── inventory_controller.rb
│   │       │   ├── expenses_controller.rb
│   │       │   └── ai_assistant_controller.rb
│   │       └── frozen_products_controller.rb
│   │
│   ├── services/
│   │   ├── webhook_publisher_service.rb    # Webhook送信
│   │   ├── ai_assistant_service.rb         # Claude API連携
│   │   ├── accounting_sync_service.rb      # EC→管理会計データ同期
│   │   └── kpi_calculator_service.rb       # KPI計算
│   │
│   ├── jobs/
│   │   ├── publish_order_webhook_job.rb    # 注文Webhook非同期送信
│   │   ├── sync_accounting_data_job.rb     # 管理会計同期
│   │   ├── generate_daily_kpi_job.rb       # 日次KPI生成
│   │   └── ai_insights_generator_job.rb    # AI洞察生成
│   │
│   └── views/
│       ├── spree/                          # Solidus標準ビュー
│       └── admin/
│           ├── accounting/                 # 管理会計UI
│           │   ├── dashboard.html.erb
│           │   ├── sales/
│           │   ├── inventory/
│           │   ├── expenses/
│           │   └── ai_assistant/
│           └── frozen_products/
│
├── config/
│   ├── initializers/
│   │   ├── apartment.rb                    # マルチテナンシー設定
│   │   ├── solidus.rb                      # Solidus設定
│   │   ├── stripe.rb                       # Stripe設定
│   │   └── claude_ai.rb                    # Claude API設定
│   └── routes.rb
│
├── db/
│   ├── migrate/                            # マイグレーション
│   └── seeds.rb                            # 初期データ
│
├── lib/
│   └── spree_shrimp_shells/                # カスタムSolidus拡張
│       ├── engine.rb
│       └── frozen_food_extension.rb
│
└── spec/                                   # テスト
```

---

### 4.2 Solidus カスタマイズ戦略

#### 4.2.1 Solidus Engine としての実装

Solidus はモジュラー設計のため、必要な機能のみを選択可能：

```ruby
# Gemfile
gem 'solidus', '~> 4.5'
gem 'solidus_auth_devise'
gem 'solidus_paypal_commerce_platform'
gem 'solidus_webhooks', github: 'solidusio-contrib/solidus_webhooks'

# カスタムエンジン
gem 'spree_shrimp_shells', path: 'lib/spree_shrimp_shells'
```

#### 4.2.2 冷凍食品拡張の実装

```ruby
# lib/spree_shrimp_shells/frozen_food_extension.rb
module SpreeShirmpShells
  class FrozenFoodExtension < Spree::Base
    # Spree::Product にアソシエーション追加
    Spree::Product.class_eval do
      has_one :frozen_product, dependent: :destroy
      accepts_nested_attributes_for :frozen_product

      def frozen?
        frozen_product.present?
      end

      def temperature_zone
        frozen_product&.temperature_zone
      end
    end

    # Spree::Shipment に温度帯制約追加
    Spree::Shipment.class_eval do
      belongs_to :temperature_zone, optional: true

      before_validation :assign_temperature_zone
      validate :validate_temperature_compatibility

      private

      def assign_temperature_zone
        # 注文内の全商品から最も厳しい温度帯を自動選択
        zones = order.line_items.map { |li| li.variant.product.temperature_zone }.compact
        self.temperature_zone = zones.min_by(&:temperature_min) if zones.any?
      end

      def validate_temperature_compatibility
        # 異なる温度帯の商品が混在していないかチェック
        zones = order.line_items.map { |li| li.variant.product.temperature_zone }.compact.uniq
        if zones.size > 1
          errors.add(:base, "異なる温度帯の商品を同時に配送できません")
        end
      end
    end
  end
end
```

#### 4.2.3 Webhook パブリッシャー実装

```ruby
# app/services/webhook_publisher_service.rb
class WebhookPublisherService
  def initialize(event_type, payload)
    @event_type = event_type
    @payload = payload
    @n8n_webhook_url = ENV['N8N_WEBHOOK_URL'] || "http://n8n:5679/webhook"
  end

  def publish
    PublishOrderWebhookJob.perform_later(@event_type, @payload)
  end
end

# app/jobs/publish_order_webhook_job.rb
class PublishOrderWebhookJob < ApplicationJob
  queue_as :webhooks

  def perform(event_type, payload)
    webhook_url = "#{ENV['N8N_WEBHOOK_URL']}/#{event_type}"

    response = HTTParty.post(
      webhook_url,
      body: {
        event: event_type,
        timestamp: Time.current.iso8601,
        data: payload
      }.to_json,
      headers: {
        'Content-Type' => 'application/json',
        'X-Webhook-Signature' => generate_signature(payload)
      }
    )

    Rails.logger.info "Webhook published: #{event_type} -> #{response.code}"
  rescue => e
    Rails.logger.error "Webhook failed: #{e.message}"
    raise # リトライ可能にする
  end

  private

  def generate_signature(payload)
    OpenSSL::HMAC.hexdigest('SHA256', ENV['WEBHOOK_SECRET'], payload.to_json)
  end
end

# config/initializers/solidus_webhooks.rb
Spree::Order.state_machine.after_transition to: :complete do |order|
  WebhookPublisherService.new('order.created', order.as_json).publish
end

Spree::Shipment.state_machine.after_transition to: :shipped do |shipment|
  WebhookPublisherService.new('shipment.shipped', {
    order_id: shipment.order.id,
    tracking_number: shipment.tracking,
    temperature_zone: shipment.temperature_zone&.code
  }).publish
end
```

---

## 5. n8n 連携アーキテクチャ

### 5.1 Webhook フロー設計

```
Rails EC (Port 3000)                  n8n (Port 5679)
─────────────────────                 ───────────────
│                                     │
│  Order Created                      │
│    ↓                                │
│  WebhookPublisherService            │
│    ↓                                │
│  POST /webhook/order.created   ────→│  Webhook Trigger
│    {                                │    ↓
│      event: "order.created",        │  Branch (Switch Node)
│      timestamp: "...",               │    │
│      data: {                         │    ├─→ Send Mattermost Notification
│        order_id: 123,                │    │     "新規注文: #R123456789"
│        order_number: "R123...",      │    │
│        customer_email: "...",        │    ├─→ Send Order Confirmation Email
│        total: 3980,                  │    │     SendGrid / AWS SES
│        items: [...]                  │    │
│      }                               │    ├─→ Sync to Accounting System
│    }                                 │    │     HTTP Request → Rails API
│                                      │    │     POST /api/accounting/sales
│                                      │    │
│                                      │    └─→ Generate SNS Post Content
│                                      │          Claude API
│                                      │          "本日、ガーリックシュリンプの
│                                      │           ご注文をいただきました..."
│                                      │          ↓
│                                      │          Save to Draft (PostgreSQL)
│                                      │
│  Shipment Shipped                    │
│    ↓                                │
│  POST /webhook/shipment.shipped ───→│  Webhook Trigger
│    {                                │    ↓
│      event: "shipment.shipped",     │  Send Shipping Notification
│      data: {                         │    Email with Tracking Number
│        order_id: 123,                │    "お荷物が発送されました"
│        tracking_number: "..."        │
│      }                               │    ↓
│    }                                │  Schedule Follow-up Email
│                                      │    Delay: 7 days
│                                      │    "商品はいかがでしたか？"
│                                      │    レビュー依頼
```

### 5.2 n8n ワークフロー実装例

#### ワークフロー1: 受注通知 + 管理会計同期

```json
{
  "name": "Order Created - Notification & Accounting Sync",
  "nodes": [
    {
      "name": "Webhook - Order Created",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "order.created",
        "responseMode": "responseNode",
        "authentication": "headerAuth"
      }
    },
    {
      "name": "Validate Signature",
      "type": "n8n-nodes-base.function",
      "parameters": {
        "functionCode": "// HMAC署名検証\nconst crypto = require('crypto');\nconst signature = $node['Webhook - Order Created'].json.headers['x-webhook-signature'];\nconst payload = JSON.stringify($node['Webhook - Order Created'].json.body);\nconst secret = $env.WEBHOOK_SECRET;\nconst computed = crypto.createHmac('sha256', secret).update(payload).digest('hex');\nif (signature !== computed) throw new Error('Invalid signature');\nreturn $input.all();"
      }
    },
    {
      "name": "Send Mattermost Notification",
      "type": "n8n-nodes-base.mattermost",
      "parameters": {
        "channel": "shrimp-shells-orders",
        "message": "🎉 新規注文: #{{ $json.data.order_number }}\n💰 金額: ¥{{ $json.data.total }}\n📧 顧客: {{ $json.data.customer_email }}"
      }
    },
    {
      "name": "Send Order Confirmation Email",
      "type": "n8n-nodes-base.sendGrid",
      "parameters": {
        "to": "{{ $json.data.customer_email }}",
        "from": "noreply@shrimp-shells.com",
        "subject": "ご注文ありがとうございます - 注文番号 {{ $json.data.order_number }}",
        "templateId": "d-xxxxx"
      }
    },
    {
      "name": "Sync to Accounting System",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "method": "POST",
        "url": "http://rails:3000/api/accounting/sales",
        "authentication": "genericCredentialType",
        "bodyParameters": {
          "order_id": "={{ $json.data.order_id }}",
          "order_number": "={{ $json.data.order_number }}",
          "total_amount": "={{ $json.data.total }}",
          "items": "={{ $json.data.items }}"
        }
      }
    },
    {
      "name": "Generate SNS Post Draft",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "method": "POST",
        "url": "https://api.anthropic.com/v1/messages",
        "authentication": "genericCredentialType",
        "bodyParameters": {
          "model": "claude-3-5-sonnet-20250514",
          "max_tokens": 300,
          "messages": [{
            "role": "user",
            "content": "以下の注文情報から、Instagramに投稿する魅力的な文章を生成してください。\n\n注文商品: {{ $json.data.items }}\n\n要件:\n- 親しみやすいトーン\n- 商品の魅力を強調\n- ハッシュタグ3-5個\n- 100文字以内"
          }]
        }
      }
    },
    {
      "name": "Save SNS Draft to DB",
      "type": "n8n-nodes-base.postgres",
      "parameters": {
        "operation": "insert",
        "schema": "n8n_shrimp_shells",
        "table": "sns_post_drafts",
        "columns": "content,related_order_id,status",
        "values": "={{ $json.content[0].text }},={{ $node['Webhook - Order Created'].json.data.order_id }},draft"
      }
    }
  ]
}
```

#### ワークフロー2: SNS 自動投稿（週次スケジュール）

```json
{
  "name": "Weekly SNS Auto-Post - Instagram",
  "nodes": [
    {
      "name": "Schedule Trigger",
      "type": "n8n-nodes-base.cron",
      "parameters": {
        "cronExpression": "0 10 * * 3"
      }
    },
    {
      "name": "Fetch Weekly Stats from Accounting",
      "type": "n8n-nodes-base.postgres",
      "parameters": {
        "operation": "select",
        "schema": "accounting_shrimp_shells",
        "table": "kpi_snapshots",
        "where": "period_type = 'weekly' AND snapshot_date = CURRENT_DATE - INTERVAL '1 week'"
      }
    },
    {
      "name": "Generate Instagram Post with Claude",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "method": "POST",
        "url": "https://api.anthropic.com/v1/messages",
        "bodyParameters": {
          "model": "claude-3-5-sonnet-20250514",
          "messages": [{
            "role": "user",
            "content": "今週の売上データ:\n総注文数: {{ $json.total_orders }}\n新規顧客: {{ $json.new_customers }}\n\nこのデータを元に、顧客に感謝を伝えるInstagram投稿を作成してください。\n\n要件:\n- 温かみのあるトーン\n- 商品の品質へのこだわりを強調\n- 次回購入を促す\n- 絵文字使用OK\n- ハッシュタグ5個\n- 150文字以内"
          }]
        }
      }
    },
    {
      "name": "Human Approval Required",
      "type": "n8n-nodes-base.waitForWebhook",
      "parameters": {
        "path": "approve-sns-post",
        "responseData": "allEntries"
      }
    },
    {
      "name": "Post to Instagram",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "method": "POST",
        "url": "https://graph.facebook.com/v18.0/{{ $env.INSTAGRAM_ACCOUNT_ID }}/media",
        "bodyParameters": {
          "image_url": "={{ $json.image_url }}",
          "caption": "={{ $node['Generate Instagram Post with Claude'].json.content[0].text }}",
          "access_token": "={{ $env.INSTAGRAM_ACCESS_TOKEN }}"
        }
      }
    }
  ]
}
```

---

## 6. AI アシスタント統合

### 6.1 Claude API 連携設計

#### 6.1.1 AIアシスタントサービス

```ruby
# app/services/ai_assistant_service.rb
class AiAssistantService
  def initialize(user_query, context = {})
    @user_query = user_query
    @context = context
    @api_key = ENV['ANTHROPIC_API_KEY']
    @model = 'claude-3-5-sonnet-20250514'
  end

  def generate_response
    response = HTTParty.post(
      'https://api.anthropic.com/v1/messages',
      headers: {
        'x-api-key' => @api_key,
        'anthropic-version' => '2023-06-01',
        'content-type' => 'application/json'
      },
      body: {
        model: @model,
        max_tokens: 1024,
        messages: build_messages
      }.to_json
    )

    parse_response(response)
  end

  def generate_insights
    # データ分析・洞察生成
    recent_kpis = Accounting::KpiSnapshot.where(period_type: 'daily').last(30)

    response = HTTParty.post(
      'https://api.anthropic.com/v1/messages',
      headers: {
        'x-api-key' => @api_key,
        'anthropic-version' => '2023-06-01',
        'content-type' => 'application/json'
      },
      body: {
        model: @model,
        max_tokens: 2048,
        messages: [
          {
            role: 'user',
            content: <<~PROMPT
              以下は過去30日間のECサイトのKPIデータです。

              データ:
              #{recent_kpis.map(&:attributes).to_json}

              このデータを分析して、以下を提供してください:
              1. 主要なトレンド（売上、顧客数、粗利率など）
              2. 異常値や注目すべき変化
              3. 具体的な改善提案（3つ）

              形式: JSON
              {
                "trends": [],
                "anomalies": [],
                "recommendations": []
              }
            PROMPT
          }
        ]
      }.to_json
    )

    insights_json = JSON.parse(response['content'][0]['text'])

    # DB に保存
    Accounting::AiInsight.create!(
      insight_type: 'trend_analysis',
      title: '過去30日間の販売動向分析',
      content: insights_json.to_json,
      priority: 'medium',
      related_metrics: { kpi_ids: recent_kpis.pluck(:id) },
      generated_by: @model,
      generated_at: Time.current
    )

    insights_json
  end

  private

  def build_messages
    system_context = <<~CONTEXT
      あなたは Shrimp Shells EC サイトの管理会計AIアシスタントです。

      利用可能なデータ:
      - 売上データ: #{Accounting::SalesRecord.count} 件
      - 在庫ログ: #{Accounting::InventoryLog.count} 件
      - 経費記録: #{Accounting::ExpenseRecord.count} 件
      - KPI スナップショット: #{Accounting::KpiSnapshot.count} 件

      現在のコンテキスト:
      #{@context.to_json}

      ユーザーの質問に対して、データに基づいた正確で実用的な回答を提供してください。
    CONTEXT

    [
      {
        role: 'user',
        content: "#{system_context}\n\n質問: #{@user_query}"
      }
    ]
  end

  def parse_response(response)
    response['content'][0]['text']
  rescue => e
    "エラーが発生しました: #{e.message}"
  end
end
```

#### 6.1.2 会話型クエリ実装

```ruby
# app/controllers/admin/accounting/ai_assistant_controller.rb
class Admin::Accounting::AiAssistantController < Spree::Admin::BaseController
  def ask
    query = params[:query]
    context = build_context

    assistant = AiAssistantService.new(query, context)
    response = assistant.generate_response

    render json: {
      query: query,
      response: response,
      timestamp: Time.current.iso8601
    }
  end

  def generate_insights
    assistant = AiAssistantService.new(nil)
    insights = assistant.generate_insights

    render json: insights
  end

  private

  def build_context
    {
      current_date: Date.current,
      latest_kpi: Accounting::KpiSnapshot.where(period_type: 'daily').last,
      monthly_revenue: Accounting::SalesRecord.where('ordered_at >= ?', 1.month.ago).sum(:total_amount),
      top_products: Accounting::SalesRecord
        .where('ordered_at >= ?', 1.month.ago)
        .group(:product_id)
        .order('SUM(quantity) DESC')
        .limit(5)
        .pluck(:product_id, 'SUM(quantity)')
    }
  end
end
```

#### 6.1.3 管理画面UI（会話型インターフェース）

```erb
<!-- app/views/admin/accounting/ai_assistant/index.html.erb -->
<div class="ai-assistant-container">
  <div class="ai-chat-header">
    <h2>AI 管理会計アシスタント</h2>
    <p>データ分析、レポート生成、質問への回答をサポートします</p>
  </div>

  <div class="ai-chat-messages" id="chat-messages">
    <!-- メッセージがここに表示される -->
  </div>

  <div class="ai-chat-input">
    <input
      type="text"
      id="user-query"
      placeholder="質問を入力してください（例: 先月の売上は？）"
      autocomplete="off"
    />
    <button id="send-query">送信</button>
  </div>

  <div class="ai-quick-actions">
    <h3>クイックアクション</h3>
    <button class="quick-action" data-query="今月の売上合計は？">今月の売上</button>
    <button class="quick-action" data-query="粗利率の推移を教えて">粗利率推移</button>
    <button class="quick-action" data-query="在庫回転率が低い商品は？">在庫分析</button>
    <button class="quick-action" data-query="広告費対効果を分析して">広告効果分析</button>
    <button id="generate-insights">AI洞察生成</button>
  </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', () => {
  const chatMessages = document.getElementById('chat-messages');
  const userQueryInput = document.getElementById('user-query');
  const sendButton = document.getElementById('send-query');

  // 質問送信
  sendButton.addEventListener('click', () => {
    const query = userQueryInput.value.trim();
    if (!query) return;

    // ユーザーメッセージを表示
    appendMessage('user', query);
    userQueryInput.value = '';

    // AI応答を取得
    fetch('/admin/accounting/ai_assistant/ask', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ query })
    })
    .then(res => res.json())
    .then(data => {
      appendMessage('assistant', data.response);
    });
  });

  // クイックアクション
  document.querySelectorAll('.quick-action').forEach(btn => {
    btn.addEventListener('click', (e) => {
      userQueryInput.value = e.target.dataset.query;
      sendButton.click();
    });
  });

  // AI洞察生成
  document.getElementById('generate-insights').addEventListener('click', () => {
    fetch('/admin/accounting/ai_assistant/generate_insights', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(res => res.json())
    .then(insights => {
      const markdown = `
## AI 洞察レポート

### トレンド
${insights.trends.map(t => `- ${t}`).join('\n')}

### 異常値
${insights.anomalies.map(a => `- ${a}`).join('\n')}

### 改善提案
${insights.recommendations.map((r, i) => `${i+1}. ${r}`).join('\n')}
      `;
      appendMessage('assistant', markdown);
    });
  });

  function appendMessage(role, content) {
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${role}`;
    messageDiv.innerHTML = `
      <div class="message-avatar">${role === 'user' ? '👤' : '🤖'}</div>
      <div class="message-content">${content}</div>
    `;
    chatMessages.appendChild(messageDiv);
    chatMessages.scrollTop = chatMessages.scrollHeight;
  }
});
</script>
```

---

## 7. インフラ構成

### 7.1 Docker Compose 設定

```yaml
# compose.shrimp-shells.yaml
version: '3.8'

services:
  # EC Rails Application
  rails-ec:
    build:
      context: ./rails
      dockerfile: Dockerfile
    container_name: shrimp-shells-ec
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/landbase_ai_suite?schema=ec_shrimp_shells
      - RAILS_ENV=development
      - REDIS_URL=redis://redis:6379/1
      - N8N_WEBHOOK_URL=http://n8n-shrimp-shells:5679/webhook
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - STRIPE_PUBLISHABLE_KEY=${STRIPE_PUBLISHABLE_KEY}
      - STRIPE_SECRET_KEY=${STRIPE_SECRET_KEY}
    volumes:
      - ./rails:/app
      - bundle_cache:/usr/local/bundle
    depends_on:
      - postgres
      - redis
      - n8n-shrimp-shells
    networks:
      - landbase_network
    command: bundle exec rails server -b 0.0.0.0

  # n8n Client (既存)
  n8n-shrimp-shells:
    image: n8nio/n8n:latest
    container_name: n8n-shrimp-shells
    ports:
      - "5679:5678"
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=landbase_ai_suite
      - DB_POSTGRESDB_SCHEMA=n8n_shrimp_shells
      - DB_POSTGRESDB_USER=postgres
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - n8n_shrimp_shells_data:/home/node/.n8n
    depends_on:
      - postgres
    networks:
      - landbase_network

  # Redis (Job Queue)
  redis:
    image: redis:7-alpine
    container_name: redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - landbase_network

  # Sidekiq (Background Jobs)
  sidekiq:
    build:
      context: ./rails
      dockerfile: Dockerfile
    container_name: sidekiq-shrimp-shells
    environment:
      - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/landbase_ai_suite?schema=ec_shrimp_shells
      - REDIS_URL=redis://redis:6379/1
      - RAILS_ENV=development
    volumes:
      - ./rails:/app
    depends_on:
      - postgres
      - redis
    networks:
      - landbase_network
    command: bundle exec sidekiq -C config/sidekiq.yml

networks:
  landbase_network:
    external: true

volumes:
  bundle_cache:
  n8n_shrimp_shells_data:
  redis_data:
```

---

### 7.2 Makefile 拡張

```makefile
# Makefile (追加部分)

# ===== Shrimp Shells EC Commands =====

.PHONY: ec-setup
ec-setup: ## Shrimp Shells EC 初期セットアップ
	@echo "$(GREEN)Setting up Shrimp Shells EC...$(NC)"
	docker-compose -f compose.shrimp-shells.yaml build
	docker-compose -f compose.shrimp-shells.yaml run --rm rails-ec bundle install
	docker-compose -f compose.shrimp-shells.yaml run --rm rails-ec bundle exec rails db:create
	docker-compose -f compose.shrimp-shells.yaml run --rm rails-ec bundle exec rails db:migrate
	docker-compose -f compose.shrimp-shells.yaml run --rm rails-ec bundle exec rails db:seed
	@echo "$(GREEN)✅ Shrimp Shells EC setup complete!$(NC)"

.PHONY: ec-up
ec-up: ## Shrimp Shells EC 起動
	@echo "$(GREEN)Starting Shrimp Shells EC...$(NC)"
	docker-compose -f compose.shrimp-shells.yaml up -d
	@echo "$(GREEN)✅ Shrimp Shells EC is running at http://localhost:3000$(NC)"

.PHONY: ec-down
ec-down: ## Shrimp Shells EC 停止
	docker-compose -f compose.shrimp-shells.yaml down

.PHONY: ec-logs
ec-logs: ## Shrimp Shells EC ログ表示
	docker-compose -f compose.shrimp-shells.yaml logs -f rails-ec

.PHONY: ec-console
ec-console: ## Rails コンソール起動
	docker-compose -f compose.shrimp-shells.yaml run --rm rails-ec bundle exec rails console

.PHONY: ec-migrate
ec-migrate: ## マイグレーション実行
	docker-compose -f compose.shrimp-shells.yaml run --rm rails-ec bundle exec rails db:migrate

.PHONY: ec-seed
ec-seed: ## シードデータ投入
	docker-compose -f compose.shrimp-shells.yaml run --rm rails-ec bundle exec rails db:seed

.PHONY: ec-test
ec-test: ## テスト実行
	docker-compose -f compose.shrimp-shells.yaml run --rm rails-ec bundle exec rspec
```

---

## 8. 実装計画（12週間）

### Week 1-2: Solidus セットアップ

- [ ] Rails 8.0 プロジェクト作成
- [ ] Solidus v4.5 インストール
- [ ] Apartment gem (ros-apartment 3.2.0) セットアップ
- [ ] PostgreSQL マルチスキーマ設定（ec_shrimp_shells）
- [ ] Docker 環境構築（compose.shrimp-shells.yaml）
- [ ] 基本的な商品・カート・決済フロー確認

**成果物**:
- 動作するSolidus EC（商品閲覧、カート追加、チェックアウト）
- マルチテナンシー動作確認

---

### Week 3-4: 冷凍食品カスタマイズ

- [ ] FrozenProduct モデル・マイグレーション作成
- [ ] TemperatureZone マスターテーブル作成
- [ ] Spree::Product 拡張（冷凍食品アソシエーション）
- [ ] Spree::Shipment 拡張（温度帯制約）
- [ ] 管理画面での冷凍食品情報入力UI
- [ ] 配送料金計算ロジック（温度帯別）

**成果物**:
- 冷凍食品特化機能が動作するEC
- 温度帯別配送料自動計算

---

### Week 5-6: n8n 連携

- [ ] Webhook パブリッシャーサービス実装
- [ ] PublishOrderWebhookJob 実装
- [ ] Solidus イベントフック（order.created, shipment.shipped 等）
- [ ] n8n ワークフロー作成（受注通知）
- [ ] Mattermost 通知連携
- [ ] 注文確認メール送信（SendGrid/AWS SES）

**成果物**:
- 受注時の自動通知（Mattermost + Email）
- n8n Webhook 連携動作確認

---

### Week 7-8: 管理会計統合

- [ ] accounting_shrimp_shells スキーマ作成
- [ ] 管理会計テーブル作成（sales_records, inventory_logs, expense_records, kpi_snapshots）
- [ ] AccountingSyncService 実装（EC → 管理会計データ同期）
- [ ] SyncAccountingDataJob 実装
- [ ] KpiCalculatorService 実装
- [ ] GenerateDailyKpiJob 実装（日次バッチ）

**成果物**:
- EC注文が管理会計に自動同期
- 日次KPI自動計算

---

### Week 9-10: AIアシスタント実装

- [ ] AiAssistantService 実装（Claude API 連携）
- [ ] AIアシスタント管理画面UI（会話型インターフェース）
- [ ] 会話型クエリ実装
- [ ] AI洞察生成機能（トレンド分析、異常検知）
- [ ] AiInsightsGeneratorJob 実装（週次バッチ）
- [ ] レポート自動生成機能

**成果物**:
- 会話型管理会計ダッシュボード
- AI洞察の週次自動生成

---

### Week 11: SNS自動投稿

- [ ] Instagram Graph API 連携準備
- [ ] Claude API による投稿文生成
- [ ] n8n ワークフロー（週次SNS投稿）
- [ ] 人間承認フロー実装
- [ ] 投稿下書き保存機能
- [ ] Instagram 自動投稿テスト

**成果物**:
- 週1回のSNS自動投稿（半自動、承認フロー付き）

---

### Week 12: テスト・ドキュメント・デプロイ

- [ ] RSpec テスト実装（モデル、サービス、コントローラー）
- [ ] 負荷テスト（Apache Bench / k6）
- [ ] セキュリティ監査（Brakeman）
- [ ] 運用マニュアル作成
- [ ] トラブルシューティングガイド
- [ ] 経営者向けトレーニング資料
- [ ] デプロイメント自動化（CI/CD）

**成果物**:
- 本番環境対応の完全なECシステム
- 運用ドキュメント一式

---

## 9. 技術スタック詳細

### 9.1 バックエンド

| 技術 | バージョン | 用途 |
|------|-----------|------|
| Ruby | 3.4.6 | プログラミング言語 |
| Rails | 8.0.2.1 | Webフレームワーク |
| Solidus | 4.5+ | ECエンジン |
| PostgreSQL | 16-alpine | データベース |
| Redis | 7-alpine | Job Queue / Cache |
| Sidekiq | 最新 | バックグラウンドジョブ |
| ros-apartment | 3.2.0 | マルチテナンシー |

### 9.2 フロントエンド

| 技術 | 用途 |
|------|------|
| Hotwire (Turbo + Stimulus) | Rails 8 標準のフロントエンド |
| Tailwind CSS | スタイリング |
| ViewComponent | コンポーネント化 |

### 9.3 外部サービス

| サービス | 用途 |
|---------|------|
| Stripe | 決済処理 |
| SendGrid / AWS SES | メール配信 |
| Claude API | AI アシスタント |
| Instagram Graph API | SNS 自動投稿 |
| Cloudflare CDN | 画像配信 |

---

## 10. セキュリティ考慮事項

### 10.1 データ保護

- PostgreSQL スキーマ分離による完全なデータ隔離
- Webhook 署名検証（HMAC-SHA256）
- 環境変数による秘密情報管理（.env.local）
- SSL/TLS 通信の強制

### 10.2 認証・認可

- Solidus 標準の Devise ベース認証
- 管理画面への IP 制限（オプション）
- API トークンによる n8n 認証

### 10.3 PCI DSS 準拠

- Stripe による PCI DSS 準拠決済
- カード情報の非保持

---

## 11. 監視・ロギング

### 11.1 アプリケーション監視

- Rails ログ（development.log, production.log）
- Sidekiq Web UI（バックグラウンドジョブ監視）
- n8n Execution ログ

### 11.2 エラー追跡

- Sentry / Rollbar（オプション）
- Slack 通知（Critical エラー）

---

## 12. スケーラビリティ戦略

### 12.1 Phase 1（~50件/月）

現在の構成で十分対応可能：
- Single Rails server
- Single PostgreSQL instance
- Sidekiq workers: 2-5

### 12.2 Phase 2（50-200件/月）

- Rails サーバー冗長化（Load Balancer）
- PostgreSQL Read Replica 追加
- CDN 導入（画像配信）

### 12.3 Phase 3（200件/月以上）

- Kubernetes 移行
- PostgreSQL クラスタリング
- Redis Cluster
- Auto-scaling

---

## 13. 次のアクション

1. **技術検証（Week 0）**
   - [ ] Solidus v4.5 + Rails 8.0 の動作確認
   - [ ] ros-apartment v3.2.0 のマルチスキーマ動作確認
   - [ ] Claude API の管理会計ユースケース検証

2. **開発環境構築（Week 1）**
   - [ ] compose.shrimp-shells.yaml 作成
   - [ ] Rails プロジェクト初期化
   - [ ] Solidus インストール

3. **設計レビュー**
   - [ ] 本設計書のレビュー
   - [ ] 不明点・追加要件の洗い出し
   - [ ] スケジュール調整

---

## 付録A: 参考リソース

- [Solidus 公式ドキュメント](https://guides.solidus.io/)
- [Solidus GitHub](https://github.com/solidusio/solidus)
- [ros-apartment GitHub](https://github.com/rails-on-services/apartment)
- [Claude API ドキュメント](https://docs.anthropic.com/)
- [Instagram Graph API](https://developers.facebook.com/docs/instagram-api/)

---

**Document Version**: 1.0
**Last Updated**: 2025-01-14
**Author**: Claude (AI Assistant)
**Status**: Draft - Awaiting Review
