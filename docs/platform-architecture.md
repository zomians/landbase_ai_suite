# LandBase AI Suite - 統合プラットフォームアーキテクチャ

## 1. プロジェクト概要

### 1.1 ビジョン

LandBase AI Suite は、小規模事業者（観光業、飲食業、EC等）向けの統合型ビジネスプラットフォームです。

```
┌─────────────────────────────────────────────────────────────┐
│           LandBase AI Suite Platform                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   EC Engine  │  │ AI Accounting│  │  n8n Auto-   │      │
│  │   (Solidus)  │  │   Dashboard  │  │  mation      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                           │                                  │
│                  ┌────────┴────────┐                         │
│                  │  Multi-Tenancy  │                         │
│                  │  (Schema-based) │                         │
│                  └─────────────────┘                         │
│                                                              │
│  ┌───────────────────────────────────────────────────┐      │
│  │  AI Brand Asset Builder (Optional)                │      │
│  │  - ブランドストーリー自動生成                      │      │
│  │  - SNS戦略自動生成                                 │      │
│  │  - コンテンツカレンダー自動生成                    │      │
│  └───────────────────────────────────────────────────┘      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 主要機能

1. **マルチテナント EC（Solidus）**
   - 業種別プラグイン対応（冷凍食品、レストラン予約、宿泊予約等）
   - カスタマイズ可能なチェックアウトフロー
   - 在庫管理、配送管理

2. **AIドリブン管理会計**
   - 会話型AIアシスタント（Claude API）
   - リアルタイムKPIダッシュボード
   - 異常検知＆アラート
   - 月次レポート自動生成

3. **n8n ワークフロー自動化**
   - EC注文→Mattermost通知
   - 在庫切れ→自動発注
   - 月次レポート→メール配信
   - Instagram自動投稿

4. **AI Brand Asset Builder（オプション機能）**
   - AIガイド付きインタビュー（6問）
   - Claude APIによる自動生成：
     - ブランドストーリー（4章構成）
     - SNS戦略（コンテンツピラー、ハッシュタグ戦略）
     - 月間投稿カレンダー
     - 初回投稿案（5投稿分）
   - 生成結果の永続化＆編集可能
   - クライアント専用ダッシュボードで閲覧

### 1.3 設計方針

- **完全なスキーマ分離**：クライアントごとに独立したPostgreSQLスキーマ
- **プラグインアーキテクチャ**：業種別機能をモジュール化
- **AI-First**：ブランド構築から経営分析まで、AIが支援
- **段階的展開**：Shrimp Shells を PoC として、学習を抽出

---

## 2. アーキテクチャ決定事項

### 2.1 マルチテナント方式

**採用：Option A - スキーマ完全分離**

#### 理由

1. **セキュリティ**：クライアントAのデータが、クライアントBのクエリで誤って取得される可能性がゼロ
2. **パフォーマンス**：各クライアントのインデックスが独立、大規模データでも影響なし
3. **カスタマイズ性**：クライアントごとにスキーマ拡張可能（例：frozen_food_variants テーブル追加）
4. **既存システムとの整合性**：n8nも既にスキーマ分離を採用

#### 実装方法

- **Apartment gem** (v3.2.0) - Rails 8.0対応
- スキーマ命名規則：
  - `ec_{client_code}` - EC（Solidus）
  - `accounting_{client_code}` - 管理会計
  - `n8n_{client_code}` - n8nワークフロー（既存）
  - `public` - プラットフォーム共通（clients, brand_configurations, plugins等）

```ruby
# config/initializers/apartment.rb
Apartment.configure do |config|
  config.excluded_models = ["Client", "BrandConfiguration", "SnsStrategy", "Plugin"]
  config.tenant_names = -> { Client.pluck(:code) }
  config.use_schemas = true
  config.persistent_schemas = true
end
```

### 2.2 カスタマイズ方式

**採用：複合的アプローチ（プラグイン + 設定）**

#### プラグインシステム

業種特化型の機能を、プラグインとして実装：

```ruby
# lib/landbase/plugins/frozen_food_plugin.rb
module Landbase
  module Plugins
    class FrozenFoodPlugin < BasePlugin
      def name
        "Frozen Food EC"
      end

      def migrations
        [
          "add_temperature_zone_to_variants",
          "add_expiration_date_to_inventory",
          "create_cold_chain_logs"
        ]
      end

      def checkout_customizations
        {
          require_delivery_date: true,
          require_time_slot: true,
          temperature_zones: ["冷蔵", "冷凍"]
        }
      end

      def admin_menu_items
        [
          { label: "冷凍在庫管理", path: "/admin/frozen_inventory" },
          { label: "温度帯別配送", path: "/admin/cold_chain_delivery" }
        ]
      end
    end
  end
end
```

#### 設定ベースカスタマイズ

軽微な調整は、設定ファイルで対応：

```yaml
# config/clients/shrimp_shells.yml
client_code: shrimp_shells
plugins:
  - frozen_food
  - sns_marketing
branding:
  primary_color: "#FF6B35"
  logo_url: "/assets/clients/shrimp_shells/logo.png"
checkout:
  require_delivery_date: true
  delivery_lead_days: 3
```

### 2.3 Shrimp Shells の位置づけ

**PoC（Proof of Concept）**

- **目的**：FrozenFoodPlugin の実装と検証
- **学習内容**：
  - 温度帯別配送の実装方法
  - SNS自動投稿の効果測定
  - AIブランドビルダーの精度評価
- **抽出作業**：
  - Shrimp Shells 固有コード → `feature/shrimp-shells` ブランチ
  - 汎用化可能コード → `main` ブランチの FrozenFoodPlugin へ

### 2.4 AIブランド資産の扱い

**採用：テンプレート化 + クライアント固有に永続化**

#### 設計

1. **プロンプトテンプレート**：
   ```ruby
   # app/services/ai_brand_builder_service.rb
   def build_brand_generation_prompt(interview_answers)
     <<~PROMPT
       あなたは経験豊富なブランドストーリーテラー兼SNSマーケティング戦略家です。

       【クライアント情報】
       商品・サービス: #{interview_answers['product']}
       ターゲット顧客: #{interview_answers['target']}
       起源ストーリー: #{interview_answers['origin']}
       差別化要因: #{interview_answers['differentiation']}
       ビジョン: #{interview_answers['vision']}

       【生成してください】
       1. ブランドストーリー（4章構成、各章200-300字）
       2. コアバリュー（3-5個）
       3. ブランドボイス（トーン＆マナー）
       4. SNS戦略
          - コンテンツピラー（4つ、割合付き）
          - ハッシュタグ戦略（大・中・ニッチの3層）
          - 推奨投稿頻度
       5. 月間投稿カレンダー（テーマ付き）
       6. 初回投稿案（5投稿分、キャプション＆ハッシュタグ）

       【出力形式】JSON
     PROMPT
   end
   ```

2. **生成結果の永続化**：
   ```sql
   -- public.brand_configurations
   CREATE TABLE brand_configurations (
     id BIGSERIAL PRIMARY KEY,
     client_id BIGINT NOT NULL REFERENCES clients(id),
     brand_story JSONB NOT NULL,  -- { chapter1: "...", chapter2: "...", ... }
     core_values TEXT[],
     brand_voice JSONB,  -- { tone: "...", manner: "..." }
     created_by_ai BOOLEAN DEFAULT false,
     created_at TIMESTAMP NOT NULL DEFAULT NOW(),
     updated_at TIMESTAMP NOT NULL DEFAULT NOW()
   );

   -- public.sns_strategies
   CREATE TABLE sns_strategies (
     id BIGSERIAL PRIMARY KEY,
     client_id BIGINT NOT NULL REFERENCES clients(id),
     platform VARCHAR(20) NOT NULL,  -- 'instagram', 'tiktok', etc.
     content_pillars JSONB NOT NULL,  -- [{ name: "...", ratio: 40 }, ...]
     hashtag_strategy JSONB NOT NULL,
     posting_frequency VARCHAR(50),
     created_at TIMESTAMP NOT NULL DEFAULT NOW(),
     updated_at TIMESTAMP NOT NULL DEFAULT NOW()
   );

   -- public.content_templates
   CREATE TABLE content_templates (
     id BIGSERIAL PRIMARY KEY,
     sns_strategy_id BIGINT NOT NULL REFERENCES sns_strategies(id),
     post_type VARCHAR(50),  -- 'reel', 'carousel', 'story'
     caption TEXT NOT NULL,
     hashtags TEXT[],
     image_prompt TEXT,  -- AI画像生成用プロンプト（将来的に）
     scheduled_date DATE,
     created_at TIMESTAMP NOT NULL DEFAULT NOW()
   );
   ```

3. **クライアントダッシュボード**：
   - `/dashboard/brand` - ブランドストーリー閲覧＆編集
   - `/dashboard/sns-strategy` - SNS戦略閲覧＆編集
   - `/dashboard/content-calendar` - 投稿カレンダー閲覧＆スケジューリング

---

## 3. データベース設計

### 3.1 プラットフォーム共通（public スキーマ）

```sql
-- クライアント管理
CREATE TABLE clients (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,  -- 'shrimp_shells', 'restaurant_a'
  name VARCHAR(255) NOT NULL,
  industry VARCHAR(50),  -- 'frozen_food', 'restaurant', 'tourism'
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ブランド設定（AI Brand Asset Builder の出力）
CREATE TABLE brand_configurations (
  id BIGSERIAL PRIMARY KEY,
  client_id BIGINT NOT NULL REFERENCES clients(id),
  brand_story JSONB NOT NULL,
  core_values TEXT[],
  brand_voice JSONB,
  created_by_ai BOOLEAN DEFAULT false,
  ai_generation_prompt TEXT,  -- 再生成時のため
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- SNS戦略（AI Brand Asset Builder の出力）
CREATE TABLE sns_strategies (
  id BIGSERIAL PRIMARY KEY,
  client_id BIGINT NOT NULL REFERENCES clients(id),
  platform VARCHAR(20) NOT NULL,
  content_pillars JSONB NOT NULL,
  hashtag_strategy JSONB NOT NULL,
  posting_frequency VARCHAR(50),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- コンテンツテンプレート（AI Brand Asset Builder の出力）
CREATE TABLE content_templates (
  id BIGSERIAL PRIMARY KEY,
  sns_strategy_id BIGINT NOT NULL REFERENCES sns_strategies(id),
  post_type VARCHAR(50),
  caption TEXT NOT NULL,
  hashtags TEXT[],
  image_prompt TEXT,
  scheduled_date DATE,
  published BOOLEAN DEFAULT false,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- プラグイン管理
CREATE TABLE plugins (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,  -- 'frozen_food', 'restaurant_booking'
  display_name VARCHAR(255) NOT NULL,
  version VARCHAR(20) NOT NULL,
  enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- クライアント-プラグイン関連付け
CREATE TABLE client_plugins (
  id BIGSERIAL PRIMARY KEY,
  client_id BIGINT NOT NULL REFERENCES clients(id),
  plugin_id BIGINT NOT NULL REFERENCES plugins(id),
  config JSONB,  -- プラグイン固有の設定
  enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(client_id, plugin_id)
);
```

### 3.2 クライアント固有スキーマ

#### ec_{client_code} スキーマ（Solidus）

```sql
-- Solidus標準テーブル（抜粋）
CREATE TABLE spree_products (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  available_on TIMESTAMP,
  deleted_at TIMESTAMP,
  slug VARCHAR(255) UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE spree_variants (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT NOT NULL REFERENCES spree_products(id),
  sku VARCHAR(255) UNIQUE NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  cost_price DECIMAL(10,2),
  weight DECIMAL(8,2),
  height DECIMAL(8,2),
  width DECIMAL(8,2),
  depth DECIMAL(8,2),
  deleted_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE spree_orders (
  id BIGSERIAL PRIMARY KEY,
  number VARCHAR(32) UNIQUE,
  user_id BIGINT,
  email VARCHAR(255),
  state VARCHAR(255),  -- 'cart', 'address', 'delivery', 'payment', 'confirm', 'complete'
  item_total DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) DEFAULT 0,
  payment_state VARCHAR(255),
  shipment_state VARCHAR(255),
  completed_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- プラグイン拡張テーブル例（FrozenFoodPlugin）
CREATE TABLE frozen_food_variants (
  id BIGSERIAL PRIMARY KEY,
  variant_id BIGINT NOT NULL REFERENCES spree_variants(id),
  temperature_zone VARCHAR(20) NOT NULL,  -- '冷蔵', '冷凍'
  expiration_days INTEGER NOT NULL,
  storage_instructions TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE cold_chain_logs (
  id BIGSERIAL PRIMARY KEY,
  shipment_id BIGINT NOT NULL,
  checkpoint VARCHAR(100) NOT NULL,  -- '出荷', '配送中', '配達完了'
  temperature DECIMAL(4,1),
  recorded_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

#### accounting_{client_code} スキーマ

```sql
-- トランザクション（EC、手動入力、API連携）
CREATE TABLE transactions (
  id BIGSERIAL PRIMARY KEY,
  transaction_date DATE NOT NULL,
  type VARCHAR(20) NOT NULL,  -- 'income', 'expense'
  category VARCHAR(100) NOT NULL,  -- '売上', '仕入', '広告費', etc.
  amount DECIMAL(12,2) NOT NULL,
  description TEXT,
  source VARCHAR(50),  -- 'ec', 'manual', 'api'
  source_id VARCHAR(100),  -- EC注文番号等
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- KPI スナップショット（日次集計）
CREATE TABLE kpi_snapshots (
  id BIGSERIAL PRIMARY KEY,
  snapshot_date DATE NOT NULL UNIQUE,
  total_sales DECIMAL(12,2) NOT NULL,
  total_cost DECIMAL(12,2) NOT NULL,
  gross_margin DECIMAL(12,2) NOT NULL,
  gross_margin_rate DECIMAL(5,2) NOT NULL,
  order_count INTEGER NOT NULL,
  customer_count INTEGER NOT NULL,
  avg_order_value DECIMAL(10,2) NOT NULL,
  cac DECIMAL(10,2),  -- Customer Acquisition Cost
  ltv DECIMAL(10,2),  -- Lifetime Value
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 会話履歴（AIアシスタント）
CREATE TABLE conversation_history (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  session_id VARCHAR(100),
  user_message TEXT NOT NULL,
  ai_response TEXT NOT NULL,
  intent VARCHAR(50),  -- 'query_metric', 'compare_period', 'anomaly_check'
  query_context JSONB,  -- { metric: 'gross_margin', period: 'last_month' }
  execution_time_ms INTEGER,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 異常検知ログ
CREATE TABLE anomaly_logs (
  id BIGSERIAL PRIMARY KEY,
  metric VARCHAR(50) NOT NULL,  -- 'sales', 'gross_margin_rate', 'inventory_turnover'
  expected_value DECIMAL(12,2),
  actual_value DECIMAL(12,2),
  deviation_pct DECIMAL(5,2),
  severity VARCHAR(20),  -- 'info', 'warning', 'critical'
  notified BOOLEAN DEFAULT false,
  detected_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

---

## 4. AI Brand Asset Builder（オプション機能）

### 4.1 機能概要

**重要：この機能は全クライアントが使用する必須機能ではなく、希望するクライアント向けのオプション機能です。**

AI Brand Asset Builder は、ブランド構築経験の少ない事業者を支援するための革新的な機能です：

- **対象クライアント**：
  - ブランドストーリーを持っていない新規事業者
  - SNS戦略に自信がない事業者
  - プロのマーケターに依頼する予算がない小規模事業者

- **利用タイミング**：
  - クライアント登録時（オンボーディングの一部として）
  - 任意のタイミング（ダッシュボードから起動可能）
  - ブランドリニューアル時

- **スキップ可能**：
  - 既存ブランドを持つクライアントは使用不要
  - 手動でブランド資産を作成したいクライアントは使用不要

### 4.2 実装フロー

```
┌─────────────────────────────────────────────────────────────┐
│  クライアントダッシュボード                                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────┐               │
│  │  「AIブランド資産ビルダーを使用する」     │ ← 任意       │
│  └──────────────────────────────────────────┘               │
│                     ↓                                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Step 1: AIインタビュー（6問）                       │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  Q1: あなたの商品・サービスは何ですか？              │   │
│  │  Q2: ターゲット顧客は誰ですか？                      │   │
│  │  Q3: この商品・サービスの起源ストーリーを教えて      │   │
│  │      ください。                                      │   │
│  │  Q4: 競合と比べた差別化要因は何ですか？              │   │
│  │  Q5: 5年後のビジョンは？                             │   │
│  │  Q6: ブランドで大切にしたい価値観は？                │   │
│  └──────────────────────────────────────────────────────┘   │
│                     ↓                                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Step 2: AI生成中（Claude API）                      │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  ⏳ ブランドストーリーを生成中...                    │   │
│  │  ⏳ SNS戦略を策定中...                               │   │
│  │  ⏳ コンテンツカレンダーを作成中...                  │   │
│  └──────────────────────────────────────────────────────┘   │
│                     ↓                                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Step 3: 生成結果プレビュー                          │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  📖 ブランドストーリー（4章）                        │   │
│  │  🎯 SNS戦略（コンテンツピラー、ハッシュタグ）        │   │
│  │  📅 月間投稿カレンダー                               │   │
│  │  📱 初回投稿案（5投稿）                              │   │
│  │                                                      │   │
│  │  [編集する] [そのまま保存] [再生成]                  │   │
│  └──────────────────────────────────────────────────────┘   │
│                     ↓                                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Step 4: データベースに永続化                        │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  ✅ brand_configurations テーブル                    │   │
│  │  ✅ sns_strategies テーブル                          │   │
│  │  ✅ content_templates テーブル                       │   │
│  └──────────────────────────────────────────────────────┘   │
│                     ↓                                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  ダッシュボードで閲覧・編集可能                      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 4.3 コード実装例

```ruby
# app/services/ai_brand_builder_service.rb
class AiBrandBuilderService
  def initialize(client)
    @client = client
  end

  def generate_brand_assets(interview_answers)
    prompt = build_brand_generation_prompt(interview_answers)

    response = call_claude_api(
      prompt: prompt,
      max_tokens: 4096,
      model: "claude-3-5-sonnet-20250514"
    )

    brand_assets = JSON.parse(response)
    persist_brand_assets(brand_assets)

    brand_assets
  end

  private

  def build_brand_generation_prompt(answers)
    <<~PROMPT
      あなたは経験豊富なブランドストーリーテラー兼SNSマーケティング戦略家です。

      【クライアント情報】
      商品・サービス: #{answers['product']}
      ターゲット顧客: #{answers['target']}
      起源ストーリー: #{answers['origin']}
      差別化要因: #{answers['differentiation']}
      ビジョン: #{answers['vision']}
      大切にしたい価値観: #{answers['core_values']}

      【生成してください】
      1. ブランドストーリー（4章構成、各章200-300字）
         - Chapter 1: 起源（Origin）
         - Chapter 2: 進化（Evolution）
         - Chapter 3: 証明（Proof）- 顧客や専門家からの評価
         - Chapter 4: 未来（Vision）

      2. コアバリュー（3-5個、各50字以内）

      3. ブランドボイス
         - トーン（例：親しみやすい、プロフェッショナル、情熱的）
         - マナー（例：丁寧語、タメ口、敬語）

      4. SNS戦略（Instagram向け）
         - コンテンツピラー（4つ、割合付き、合計100%）
           例：{ "商品紹介": 40, "背景ストーリー": 30, "お客様の声": 20, "舞台裏": 10 }
         - ハッシュタグ戦略
           - 大タグ（100万投稿以上）: 3個
           - 中タグ（10万-100万投稿）: 5個
           - ニッチタグ（1万-10万投稿）: 7個
         - 推奨投稿頻度（例：週3-5回）

      5. 月間投稿カレンダー（30日分、各日のテーマのみ）
         例：{ "day1": "商品紹介", "day2": "起源ストーリー", ... }

      6. 初回投稿案（5投稿分）
         - 投稿タイプ（Reel/Carousel/Single）
         - キャプション（150-300字）
         - ハッシュタグ（15個）
         - 推奨画像・動画の内容説明

      【出力形式】
      必ず以下のJSON形式で出力してください：
      {
        "brand_story": {
          "chapter1": "...",
          "chapter2": "...",
          "chapter3": "...",
          "chapter4": "..."
        },
        "core_values": ["...", "...", "..."],
        "brand_voice": {
          "tone": "...",
          "manner": "..."
        },
        "sns_strategy": {
          "platform": "instagram",
          "content_pillars": [
            { "name": "...", "ratio": 40 },
            ...
          ],
          "hashtag_strategy": {
            "big": ["#...", "#...", "#..."],
            "medium": ["#...", ...],
            "niche": ["#...", ...]
          },
          "posting_frequency": "週3-5回"
        },
        "content_calendar": {
          "day1": "商品紹介",
          ...
        },
        "initial_posts": [
          {
            "type": "reel",
            "caption": "...",
            "hashtags": ["#...", ...],
            "visual_description": "..."
          },
          ...
        ]
      }
    PROMPT
  end

  def call_claude_api(prompt:, max_tokens:, model:)
    require 'anthropic'

    client = Anthropic::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])

    response = client.messages(
      parameters: {
        model: model,
        max_tokens: max_tokens,
        messages: [
          { role: "user", content: prompt }
        ]
      }
    )

    response.dig("content", 0, "text")
  rescue => e
    Rails.logger.error("Claude API Error: #{e.message}")
    raise
  end

  def persist_brand_assets(assets)
    ActiveRecord::Base.transaction do
      # 1. ブランド設定
      brand_config = BrandConfiguration.create!(
        client_id: @client.id,
        brand_story: assets['brand_story'],
        core_values: assets['core_values'],
        brand_voice: assets['brand_voice'],
        created_by_ai: true,
        ai_generation_prompt: "AIブランドビルダー v1.0"
      )

      # 2. SNS戦略
      sns_strategy = SnsStrategy.create!(
        client_id: @client.id,
        platform: 'instagram',
        content_pillars: assets['sns_strategy']['content_pillars'],
        hashtag_strategy: assets['sns_strategy']['hashtag_strategy'],
        posting_frequency: assets['sns_strategy']['posting_frequency']
      )

      # 3. 初回投稿テンプレート
      assets['initial_posts'].each_with_index do |post, index|
        ContentTemplate.create!(
          sns_strategy_id: sns_strategy.id,
          post_type: post['type'],
          caption: post['caption'],
          hashtags: post['hashtags'],
          image_prompt: post['visual_description'],
          scheduled_date: Date.today + index.days
        )
      end
    end
  end
end
```

---

## 5. プラグインシステム

### 5.1 プラグインインターフェース

```ruby
# lib/landbase/plugins/base_plugin.rb
module Landbase
  module Plugins
    class BasePlugin
      def name
        raise NotImplementedError
      end

      def version
        "1.0.0"
      end

      def migrations
        []
      end

      def routes
        []
      end

      def admin_menu_items
        []
      end

      def checkout_customizations
        {}
      end

      def install(client)
        # プラグイン固有のセットアップ処理
      end

      def uninstall(client)
        # プラグイン固有のクリーンアップ処理
      end
    end
  end
end
```

### 5.2 FrozenFoodPlugin 実装例

```ruby
# lib/landbase/plugins/frozen_food_plugin.rb
module Landbase
  module Plugins
    class FrozenFoodPlugin < BasePlugin
      def name
        "Frozen Food EC"
      end

      def migrations
        [
          "20250114000001_add_temperature_zone_to_variants.rb",
          "20250114000002_create_frozen_food_variants.rb",
          "20250114000003_create_cold_chain_logs.rb"
        ]
      end

      def routes
        [
          { path: "/admin/frozen-inventory", controller: "Admin::FrozenInventoryController" },
          { path: "/admin/cold-chain-logs", controller: "Admin::ColdChainLogsController" }
        ]
      end

      def admin_menu_items
        [
          { label: "冷凍在庫管理", path: "/admin/frozen-inventory", icon: "❄️" },
          { label: "温度帯別配送", path: "/admin/cold-chain-logs", icon: "🌡️" }
        ]
      end

      def checkout_customizations
        {
          require_delivery_date: true,
          require_time_slot: true,
          delivery_lead_days: 3,
          temperature_zones: ["冷蔵 (0-10℃)", "冷凍 (-18℃以下)"],
          custom_validations: [
            {
              field: "delivery_date",
              rule: "must_be_at_least_3_days_from_now",
              message: "冷凍商品は3営業日後以降の配送となります"
            }
          ]
        }
      end

      def install(client)
        # 1. クライアントスキーマでマイグレーション実行
        Apartment::Tenant.switch!("ec_#{client.code}") do
          migrations.each do |migration_file|
            require "db/plugins/frozen_food/#{migration_file}"
            migration_class_name = migration_file.split('_')[1..-1].join('_').camelize
            migration_class_name.constantize.new.up
          end
        end

        # 2. デフォルト温度帯設定を作成
        Apartment::Tenant.switch!("ec_#{client.code}") do
          TemperatureZone.create!(name: "冷蔵", min_temp: 0, max_temp: 10)
          TemperatureZone.create!(name: "冷凍", min_temp: -25, max_temp: -15)
        end

        Rails.logger.info("FrozenFoodPlugin installed for client #{client.code}")
      end

      def uninstall(client)
        Apartment::Tenant.switch!("ec_#{client.code}") do
          migrations.reverse.each do |migration_file|
            require "db/plugins/frozen_food/#{migration_file}"
            migration_class_name = migration_file.split('_')[1..-1].join('_').camelize
            migration_class_name.constantize.new.down
          end
        end

        Rails.logger.info("FrozenFoodPlugin uninstalled for client #{client.code}")
      end
    end
  end
end
```

### 5.3 プラグイン管理コマンド

```bash
# プラグイン一覧表示
$ rails landbase:plugins:list

Available Plugins:
- frozen_food (v1.0.0) - Frozen Food EC features
- restaurant_booking (v1.0.0) - Restaurant reservation system
- sns_marketing (v1.0.0) - SNS auto-posting and analytics

# クライアントにプラグインをインストール
$ rails landbase:plugins:install[shrimp_shells,frozen_food]

Installing 'frozen_food' plugin for client 'shrimp_shells'...
✅ Migrations applied
✅ Default settings created
✅ Plugin activated

# プラグイン無効化（データは保持）
$ rails landbase:plugins:disable[shrimp_shells,frozen_food]

# プラグイン完全削除（データも削除）
$ rails landbase:plugins:uninstall[shrimp_shells,frozen_food]
```

---

## 6. n8n 統合

### 6.1 ワークフロー例

#### Workflow 1: EC注文 → Mattermost通知

```json
{
  "name": "EC Order Notification",
  "nodes": [
    {
      "type": "n8n-nodes-base.webhook",
      "name": "Order Created Webhook",
      "parameters": {
        "path": "ec/order-created",
        "method": "POST"
      }
    },
    {
      "type": "n8n-nodes-base.function",
      "name": "Format Message",
      "parameters": {
        "functionCode": "const order = $json.order;\nreturn {\n  text: `🛒 新規注文: #${order.number}\\n👤 ${order.customer_name}\\n💰 ¥${order.total.toLocaleString()}\\n📦 ${order.items.length}点`\n};"
      }
    },
    {
      "type": "n8n-nodes-base.mattermost",
      "name": "Post to Channel",
      "parameters": {
        "channel": "ec-orders",
        "message": "={{$json.text}}"
      }
    }
  ]
}
```

#### Workflow 2: 在庫切れ → 自動発注

```json
{
  "name": "Auto Reorder Low Stock",
  "nodes": [
    {
      "type": "n8n-nodes-base.schedule",
      "name": "Daily Check",
      "parameters": {
        "rule": {
          "interval": [{"field": "hours", "hoursInterval": 24}]
        }
      }
    },
    {
      "type": "n8n-nodes-base.postgres",
      "name": "Check Low Stock",
      "parameters": {
        "query": "SELECT * FROM ec_shrimp_shells.spree_stock_items WHERE count_on_hand < reorder_point"
      }
    },
    {
      "type": "n8n-nodes-base.httpRequest",
      "name": "Create Purchase Order",
      "parameters": {
        "url": "https://api.supplier.com/orders",
        "method": "POST"
      }
    },
    {
      "type": "n8n-nodes-base.mattermost",
      "name": "Notify Admin",
      "parameters": {
        "channel": "inventory-alerts",
        "message": "自動発注しました: {{$json.product_name}}"
      }
    }
  ]
}
```

#### Workflow 3: Instagram自動投稿

```json
{
  "name": "Instagram Auto Post",
  "nodes": [
    {
      "type": "n8n-nodes-base.schedule",
      "name": "Posting Schedule",
      "parameters": {
        "rule": {
          "interval": [{"field": "days", "daysInterval": 1}],
          "time": "10:00"
        }
      }
    },
    {
      "type": "n8n-nodes-base.postgres",
      "name": "Get Scheduled Post",
      "parameters": {
        "query": "SELECT * FROM public.content_templates WHERE scheduled_date = CURRENT_DATE AND published = false LIMIT 1"
      }
    },
    {
      "type": "n8n-nodes-base.function",
      "name": "Format Caption",
      "parameters": {
        "functionCode": "const post = $json;\nreturn {\n  caption: post.caption + '\\n\\n' + post.hashtags.join(' ')\n};"
      }
    },
    {
      "type": "n8n-nodes-base.httpRequest",
      "name": "Post to Instagram",
      "parameters": {
        "url": "https://graph.facebook.com/v18.0/{{$env.INSTAGRAM_ACCOUNT_ID}}/media",
        "method": "POST",
        "body": {
          "caption": "={{$json.caption}}",
          "image_url": "={{$json.image_url}}"
        }
      }
    },
    {
      "type": "n8n-nodes-base.postgres",
      "name": "Mark as Published",
      "parameters": {
        "query": "UPDATE public.content_templates SET published = true WHERE id = {{$json.id}}"
      }
    }
  ]
}
```

### 6.2 Webhook エンドポイント（Rails側）

```ruby
# app/controllers/webhooks/ec_orders_controller.rb
module Webhooks
  class EcOrdersController < ApplicationController
    skip_before_action :verify_authenticity_token

    def created
      order = Spree::Order.find_by!(number: params[:order_number])

      # n8n Webhookにデータを送信
      n8n_webhook_url = "#{ENV['N8N_WEBHOOK_BASE_URL']}/webhook/ec/order-created"

      HTTParty.post(n8n_webhook_url, {
        body: {
          order: {
            number: order.number,
            customer_name: order.email,
            total: order.total.to_f,
            items: order.line_items.map { |item|
              {
                product_name: item.product.name,
                quantity: item.quantity,
                price: item.price.to_f
              }
            }
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      })

      head :ok
    end
  end
end
```

---

## 7. ブランチ戦略

### 7.1 ブランチ構成

```
main
├── feature/shrimp-shells  ← Shrimp Shells PoC
├── feature/restaurant-a   ← 将来の別クライアント
└── feature/tourism-b      ← 将来の別クライアント
```

### 7.2 ファイル配置ルール

#### main ブランチ

- **プラットフォームコア**
  - `app/models/client.rb`
  - `app/models/brand_configuration.rb`
  - `app/models/sns_strategy.rb`
  - `app/models/plugin.rb`
  - `app/services/ai_brand_builder_service.rb`
  - `config/initializers/apartment.rb`

- **プラグイン**
  - `lib/landbase/plugins/base_plugin.rb`
  - `lib/landbase/plugins/frozen_food_plugin.rb`
  - `lib/landbase/plugins/restaurant_booking_plugin.rb`
  - `db/plugins/frozen_food/*`

- **共通ドキュメント**
  - `docs/platform-architecture.md`（本ドキュメント）
  - `docs/ai-accounting-solution-requirements.md`
  - `docs/plugin-development-guide.md`

#### feature/shrimp-shells ブランチ

- **Shrimp Shells 固有実装**
  - `config/clients/shrimp_shells.yml`
  - `app/controllers/shrimp_shells/*`（もしあれば）
  - `app/views/shrimp_shells/*`（カスタムビュー）

- **Shrimp Shells 固有ドキュメント**
  - `docs/solidus-ec-architecture.md`
  - `docs/sns-marketing-trends-2025.md`

### 7.3 マージ戦略

```bash
# Shrimp Shells で学んだ汎用的な改善を main へマージ
$ git checkout main
$ git merge feature/shrimp-shells --no-ff

# 衝突解決時は、Shrimp Shells 固有のファイルは main に含めない
# 例：docs/sns-marketing-trends-2025.md は feature/shrimp-shells 専用
```

---

## 8. セキュリティ設計

### 8.1 テナント分離

- **スキーマレベル分離**：クライアントAは `ec_shrimp_shells` スキーマにしかアクセスできない
- **認証**：Devise + JWT（管理者ロール、クライアントロール）
- **認可**：Pundit（スキーマ切り替え前にテナントIDを検証）

```ruby
# app/policies/application_policy.rb
class ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record
    ensure_tenant_access!
  end

  private

  def ensure_tenant_access!
    return if @user.admin?

    unless @user.client_id == current_tenant_id
      raise Pundit::NotAuthorizedError, "Tenant access denied"
    end
  end

  def current_tenant_id
    Apartment::Tenant.current.match(/\w+_(\d+)$/)[1].to_i
  end
end
```

### 8.2 環境変数管理

```bash
# .env.production
ANTHROPIC_API_KEY=sk-ant-...
DATABASE_URL=postgresql://...
N8N_WEBHOOK_BASE_URL=https://n8n.landbase.ai
MATTERMOST_WEBHOOK_URL=https://mattermost.landbase.ai/hooks/...
INSTAGRAM_CLIENT_ID=...
INSTAGRAM_CLIENT_SECRET=...
```

### 8.3 監査ログ

```sql
-- public.audit_logs
CREATE TABLE audit_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT,
  client_id BIGINT,
  action VARCHAR(100) NOT NULL,  -- 'create_order', 'update_product', 'delete_customer'
  resource_type VARCHAR(100),
  resource_id BIGINT,
  changes JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_client_id ON audit_logs(client_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
```

---

## 9. クライアントオンボーディング

### 9.1 オンボーディングパターン

**重要：全クライアントが同じオンボーディングフローを通るわけではありません。**

以下の3パターンから、クライアントの状況に応じて選択：

#### パターンA: AIブランド資産ビルダーを使用（推奨）

**対象**：
- ブランドストーリーを持っていない新規事業者
- SNS戦略に自信がない事業者
- プロのマーケターに依頼する予算がない小規模事業者

**フロー**：

```
┌────────────────────────────────────────────────────────┐
│  Step 1: 基本情報登録                                   │
├────────────────────────────────────────────────────────┤
│  - クライアントコード（例: shrimp_shells）             │
│  - 会社名（例: Shrimp Shells）                         │
│  - 業種（例: 冷凍食品EC）                              │
│  - 管理者メールアドレス                                │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│  Step 2: プラグイン選択                                 │
├────────────────────────────────────────────────────────┤
│  ☑ Frozen Food EC                                      │
│  ☐ Restaurant Booking                                  │
│  ☑ SNS Marketing                                       │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│  Step 3: AIブランド資産ビルダー                        │
├────────────────────────────────────────────────────────┤
│  AIガイド付きインタビュー（6問）                       │
│    → Claude APIで自動生成                              │
│    → ブランドストーリー、SNS戦略、投稿案               │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│  Step 4: スキーマ作成＆初期データ投入                   │
├────────────────────────────────────────────────────────┤
│  ✅ ec_shrimp_shells スキーマ作成                      │
│  ✅ accounting_shrimp_shells スキーマ作成              │
│  ✅ n8n_shrimp_shells スキーマ作成（既存）             │
│  ✅ プラグインマイグレーション実行                      │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│  Step 5: ダッシュボードへ                              │
├────────────────────────────────────────────────────────┤
│  🎉 セットアップ完了！                                 │
│  次のステップ：                                        │
│  - EC商品登録                                           │
│  - 決済設定（Stripe/PAY.JP）                           │
│  - Instagram連携                                        │
└────────────────────────────────────────────────────────┘
```

#### パターンB: 手動でブランド資産を作成

**対象**：
- 既存ブランドを持つ事業者
- 自社でマーケティング担当者がいる
- AIではなく自分で作りたい

**フロー**：

```
┌────────────────────────────────────────────────────────┐
│  Step 1: 基本情報登録                                   │
├────────────────────────────────────────────────────────┤
│  （パターンAと同じ）                                   │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│  Step 2: プラグイン選択                                 │
├────────────────────────────────────────────────────────┤
│  （パターンAと同じ）                                   │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│  Step 3: ブランド資産を手動入力                        │
├────────────────────────────────────────────────────────┤
│  - ブランドストーリー（テキストエリア）                │
│  - コアバリュー（カンマ区切り）                        │
│  - SNS戦略（フォーム入力）                             │
│  ※ 後からダッシュボードで編集可能                     │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│  Step 4: スキーマ作成＆初期データ投入                   │
│  Step 5: ダッシュボードへ                              │
│  （パターンAと同じ）                                   │
└────────────────────────────────────────────────────────┘
```

#### パターンC: ブランド資産なしでEC構築のみ

**対象**：
- とにかく早くECを立ち上げたい
- ブランディングは後回しでOK
- まずは機能検証したい

**フロー**：

```
┌────────────────────────────────────────────────────────┐
│  Step 1: 基本情報登録                                   │
├────────────────────────────────────────────────────────┤
│  （パターンAと同じ）                                   │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│  Step 2: プラグイン選択                                 │
├────────────────────────────────────────────────────────┤
│  ☑ Frozen Food EC                                      │
│  ☐ SNS Marketing  ← スキップ                           │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│  Step 3: スキーマ作成＆初期データ投入                   │
│  Step 4: ダッシュボードへ                              │
│  （ブランド資産なし）                                  │
└────────────────────────────────────────────────────────┘
```

**後から追加可能**：
- ダッシュボードから「AIブランドビルダーを使う」ボタンで、いつでもパターンAに移行可能

### 9.2 セットアップコマンド

```bash
# パターンA: AIブランドビルダー使用
$ rails landbase:setup_client[shrimp_shells,frozen_food+sns_marketing,use_ai_brand_builder]

# パターンB: 手動入力
$ rails landbase:setup_client[shrimp_shells,frozen_food+sns_marketing,manual_brand_assets]

# パターンC: ブランド資産なし
$ rails landbase:setup_client[shrimp_shells,frozen_food]
```

**実行内容**：

```ruby
# lib/tasks/landbase.rake
namespace :landbase do
  desc "Setup new client"
  task :setup_client, [:code, :plugins, :brand_mode] => :environment do |t, args|
    code = args[:code]
    plugins = args[:plugins].split('+')
    brand_mode = args[:brand_mode] || 'skip'  # 'use_ai_brand_builder', 'manual_brand_assets', 'skip'

    # 1. クライアント作成
    client = Client.create!(
      code: code,
      name: code.titleize,
      industry: plugins.first
    )

    # 2. スキーマ作成
    Apartment::Tenant.create("ec_#{code}")
    Apartment::Tenant.create("accounting_#{code}")

    # 3. プラグインインストール
    plugins.each do |plugin_name|
      plugin = Plugin.find_by!(name: plugin_name)
      plugin_class = "Landbase::Plugins::#{plugin_name.classify}Plugin".constantize
      plugin_instance = plugin_class.new
      plugin_instance.install(client)

      ClientPlugin.create!(client: client, plugin: plugin, enabled: true)
    end

    # 4. ブランド資産セットアップ
    case brand_mode
    when 'use_ai_brand_builder'
      puts "📝 AIブランドビルダーのインタビューを開始します..."
      # Interactive prompt for 6 questions
      # (実際は Web UI で実施)
    when 'manual_brand_assets'
      puts "✍️ ブランド資産を手動で入力してください（Web UIへ）"
    when 'skip'
      puts "⏩ ブランド資産の作成をスキップしました"
    end

    puts "✅ Client '#{code}' setup completed!"
  end
end
```

---

## 10. Shrimp Shells PoC の位置づけ

### 10.1 目的

Shrimp Shells は、LandBase AI Suite の**最初の実クライアント実装（PoC）**です。

**目標**：
1. FrozenFoodPlugin の実装と検証
2. AIブランドビルダーの精度評価
3. SNS自動投稿の効果測定
4. n8nとの統合パターン確立

### 10.2 学習内容の抽出

```bash
# Shrimp Shells 実装後、汎用化可能な部分を main へマージ

# 例1: 温度帯別配送ロジック
feature/shrimp-shells:
  app/services/shrimp_shells/cold_chain_delivery_service.rb
    ↓ 汎用化
main:
  lib/landbase/plugins/frozen_food_plugin/cold_chain_delivery_service.rb

# 例2: Instagram投稿頻度最適化の知見
feature/shrimp-shells:
  docs/sns-marketing-trends-2025.md
  - Reelsは週3-5回が最適
  - シェア率が最重要指標
    ↓ 抽出
main:
  docs/sns-best-practices.md（新規作成）

# 例3: AIブランドビルダーのプロンプト改善
feature/shrimp-shells で発見した問題:
  - 飲食業界の専門用語が不足
  - ハッシュタグが競合過多
    ↓ 改善
main:
  app/services/ai_brand_builder_service.rb
  - 業種別プロンプトテンプレート追加
```

### 10.3 実装ロードマップ

```
Week 1-2: プラットフォームコア構築（main ブランチ）
  ✅ Apartment gem セットアップ
  ✅ Client, BrandConfiguration, SnsStrategy モデル
  ✅ AIブランドビルダー基本実装

Week 3-4: FrozenFoodPlugin 実装（main ブランチ）
  - 温度帯管理
  - 賞味期限管理
  - 配送日指定UI

Week 5-6: Shrimp Shells PoC（feature/shrimp-shells ブランチ）
  - config/clients/shrimp_shells.yml
  - 商品データ投入
  - AIブランドビルダーで資産生成

Week 7-8: SNS自動投稿（feature/shrimp-shells → main）
  - n8n ワークフロー作成
  - Instagram Graph API 連携
  - 投稿スケジューラー

Week 9-10: 管理会計ダッシュボード（main ブランチ）
  - KPIスナップショット日次集計
  - 会話型AIアシスタント
  - 異常検知アラート

Week 11-12: 検証＆改善
  - Shrimp Shells でリアル運用
  - AIブランドビルダー精度評価
  - プラグインの汎用化抽出
```

---

## 11. 技術スタック

### 11.1 バックエンド

- **Ruby on Rails** 8.0
- **PostgreSQL** 14+
- **Apartment gem** v3.2.0（マルチテナント）
- **Solidus** v4.5（EC）
- **Devise** + **JWT**（認証）
- **Pundit**（認可）
- **HTTParty**（API連携）
- **anthropic-rb**（Claude API client）

### 11.2 フロントエンド

- **Next.js** 14（クライアントダッシュボード）
- **TypeScript**
- **TailwindCSS**
- **shadcn/ui**（UIコンポーネント）
- **Chart.js**（KPI可視化）

### 11.3 インフラ

- **Docker** + **Docker Compose**
- **Nginx**（リバースプロキシ）
- **n8n**（ワークフロー自動化）
- **Mattermost**（チームコミュニケーション）
- **Redis**（ジョブキュー）

### 11.4 外部サービス

- **Claude API** (claude-3-5-sonnet-20250514)
- **Instagram Graph API**
- **Stripe** / **PAY.JP**（決済）
- **SendGrid**（メール配信）

---

## 12. パフォーマンス最適化

### 12.1 データベース

- **スキーマごとのインデックス最適化**
  ```sql
  -- ec_shrimp_shells.spree_orders
  CREATE INDEX idx_orders_completed_at ON spree_orders(completed_at) WHERE completed_at IS NOT NULL;
  CREATE INDEX idx_orders_email ON spree_orders(email);

  -- accounting_shrimp_shells.transactions
  CREATE INDEX idx_transactions_date ON transactions(transaction_date);
  CREATE INDEX idx_transactions_category ON transactions(category);
  ```

- **接続プーリング**
  ```yaml
  # config/database.yml
  production:
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 25 } %>
    checkout_timeout: 5
  ```

### 12.2 キャッシュ戦略

- **KPIスナップショット**：日次で事前集計（リアルタイム計算不要）
- **ブランド資産**：生成後はDBに永続化（毎回API呼び出し不要）
- **商品一覧**：Fragment cache（1時間）

```ruby
# app/views/products/index.html.erb
<% cache("products-#{@client.code}", expires_in: 1.hour) do %>
  <%= render @products %>
<% end %>
```

### 12.3 非同期処理

- **Instagram投稿**：Sidekiq ジョブ化
- **月次レポート生成**：夜間バッチ処理
- **AI生成処理**：ジョブキュー（Solid Queue）

```ruby
# app/jobs/generate_brand_assets_job.rb
class GenerateBrandAssetsJob < ApplicationJob
  queue_as :default

  def perform(client_id, interview_answers)
    client = Client.find(client_id)
    AiBrandBuilderService.new(client).generate_brand_assets(interview_answers)
  end
end
```

---

## 13. モニタリング＆ロギング

### 13.1 ログ戦略

```ruby
# config/environments/production.rb
config.log_level = :info
config.log_tags = [:request_id, :subdomain]

# Apartment テナント情報をログに追加
config.log_tags << -> (request) {
  "tenant:#{Apartment::Tenant.current}"
}
```

### 13.2 メトリクス収集

- **APM**：New Relic / Datadog
- **エラートラッキング**：Sentry
- **監視対象**：
  - Claude API レスポンスタイム
  - n8n ワークフロー実行成功率
  - EC注文処理時間
  - DB接続プール使用率

### 13.3 アラート設定

```yaml
# config/alerts.yml
alerts:
  - name: "High Claude API Latency"
    condition: "avg(claude_api_response_time) > 5000ms"
    notification: mattermost

  - name: "Failed n8n Workflow"
    condition: "n8n_workflow_failed == true"
    notification: mattermost

  - name: "Low Inventory Alert"
    condition: "spree_stock_items.count_on_hand < reorder_point"
    notification: mattermost
```

---

## 14. 次のステップ

### 14.1 即座に着手

1. ✅ **本ドキュメント完成**
2. ⬜ **プラグイン開発ガイド作成**（`docs/plugin-development-guide.md`）
3. ⬜ **Apartment gem セットアップ**（`config/initializers/apartment.rb`）
4. ⬜ **基本モデル実装**（Client, BrandConfiguration, SnsStrategy）

### 14.2 Week 1-2（プラットフォームコア）

```bash
# 1. Apartment セットアップ
$ bundle add apartment -v "~> 3.2.0"
$ rails generate apartment:install

# 2. モデル生成
$ rails generate model Client code:string name:string industry:string active:boolean
$ rails generate model BrandConfiguration client:references brand_story:jsonb core_values:text[] brand_voice:jsonb created_by_ai:boolean
$ rails generate model SnsStrategy client:references platform:string content_pillars:jsonb hashtag_strategy:jsonb posting_frequency:string

# 3. マイグレーション実行
$ rails db:migrate
```

### 14.3 Week 3-4（FrozenFoodPlugin）

1. `lib/landbase/plugins/frozen_food_plugin.rb` 実装
2. プラグイン専用マイグレーション作成
3. 管理画面UI（温度帯管理、配送日指定）

### 14.4 Week 5-6（Shrimp Shells PoC）

```bash
# feature/shrimp-shells ブランチ作成
$ git checkout -b feature/shrimp-shells

# クライアントセットアップ
$ rails landbase:setup_client[shrimp_shells,frozen_food+sns_marketing,use_ai_brand_builder]
```

---

## 15. FAQ

### Q1: 新しいクライアントを追加する手順は？

```bash
$ rails landbase:setup_client[restaurant_a,restaurant_booking+sns_marketing,use_ai_brand_builder]
```

これで以下が自動実行されます：
- クライアントレコード作成
- スキーマ作成（ec_restaurant_a, accounting_restaurant_a）
- プラグインインストール
- AIブランドビルダー起動（オプション）

### Q2: プラグインを追加したい場合は？

```bash
# 1. プラグインクラス作成
$ touch lib/landbase/plugins/my_custom_plugin.rb

# 2. プラグイン実装（BasePlugin を継承）
# 3. プラグイン登録
$ rails console
> Plugin.create!(name: 'my_custom', display_name: 'My Custom Plugin', version: '1.0.0')

# 4. クライアントに適用
$ rails landbase:plugins:install[shrimp_shells,my_custom]
```

### Q3: AIブランドビルダーを後から使いたい場合は？

クライアントダッシュボードから「AIブランドビルダーを起動」ボタンをクリック。
いつでも再生成可能です。

### Q4: Shrimp Shells の実装を他クライアントで再利用したい場合は？

```bash
# 1. feature/shrimp-shells から汎用化可能なコードを特定
# 2. main ブランチでプラグイン化
$ git checkout main
$ git checkout feature/shrimp-shells -- lib/landbase/plugins/frozen_food_plugin.rb
$ git commit -m "Extract FrozenFoodPlugin from Shrimp Shells PoC"
```

---

## まとめ

本ドキュメントは、LandBase AI Suite の統合アーキテクチャを定義しました。

**重要な設計決定**：
1. ✅ スキーマ完全分離によるマルチテナント
2. ✅ プラグインアーキテクチャによる業種別カスタマイズ
3. ✅ AIブランドビルダーによる差別化（オプション機能として提供）
4. ✅ Shrimp Shells を PoC として実装、学習を抽出

**次のアクション**：
- [ ] Apartment gem セットアップ
- [ ] 基本モデル実装
- [ ] FrozenFoodPlugin 実装
- [ ] Shrimp Shells PoC 開始

このアーキテクチャにより、Shrimp Shells で得た学習を、将来のクライアント（レストラン、観光業等）に横展開できます。
