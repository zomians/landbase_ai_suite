# ADR 0005: マルチテナント実装戦略

## ステータス

採用（Accepted）

## 日付

2025-11-25

## コンテキスト（背景・課題）

ADR 0001 で LandBase AI Suite をマルチテナント SaaS として開発することが決定され、**複数の観光業事業者（100+クライアント想定）を1つのプラットフォームで管理**する必要があった。

### ビジネス要件

1. **テナント（クライアント）分離**:
   - クライアント間のデータ完全分離
   - セキュリティ・プライバシー確保
   - クライアント毎の独立性

2. **運用効率**:
   - 管理コストの最小化
   - スケーラビリティ
   - デプロイメントの簡素化

3. **将来の拡張性**:
   - クライアント数の増加に対応
   - 必要に応じた分離戦略の変更

### 技術的課題

各サービス（n8n、Mattermost、PostgreSQL、Rails）で、どのようにテナント分離を実現するか？

**選択肢**:
1. **物理分離**: サービス・DB毎にインスタンス分離
2. **論理分離**: 単一インスタンス内でテナントIDによる分離

## 検討した選択肢

### n8n のテナント分離

#### 選択肢A: Projects機能（採用）

**実装方法**:
```
単一 n8n インスタンス
  ├── Project: Ikigai Stay（クライアント1）
  ├── Project: Hotel Example（クライアント2）
  └── Project: Tour Company（クライアント3）
```

**メリット**:
- ✅ 単一インスタンスで複数テナント管理
- ✅ Project単位でワークフロー・クレデンシャル分離
- ✅ 運用コスト低い（1インスタンスのみ）
- ✅ n8n標準機能（追加開発不要）

**デメリット**:
- ⚠️ 実装中に判断（事前検証なし）

#### 選択肢B: 物理分離（複数n8nインスタンス）（不採用）

**実装方法**:
```
n8n インスタンス1（Ikigai Stay専用）
n8n インスタンス2（Hotel Example専用）
n8n インスタンス3（Tour Company専用）
```

**メリット**:
- ✅ 完全な独立性

**デメリット**:
- ❌ 運用コスト増大（インスタンス数×クライアント数）
- ❌ 管理が複雑
- ❌ リソース効率が悪い

**不採用の理由**:
- 管理を複雑にする明確な理由がない

---

### Mattermost のテナント分離

#### 選択肢A: Teams機能（採用）

**実装方法**:
```
単一 Mattermost インスタンス
  ├── Team: Ikigai Stay Team（クライアント1）
  ├── Team: Hotel Example Team（クライアント2）
  └── Team: Tour Company Team（クライアント3）
```

**メリット**:
- ✅ 単一インスタンスで複数テナント管理
- ✅ Team単位でチャンネル・メンバー完全分離
- ✅ 運用コスト低い
- ✅ Mattermost標準機能

**デメリット**:
- ⚠️ 実装中に判断（事前検証なし）

#### 選択肢B: 物理分離（複数Mattermostインスタンス）（不採用）

**実装方法**:
```
Mattermost インスタンス1（Ikigai Stay専用）
Mattermost インスタンス2（Hotel Example専用）
Mattermost インスタンス3（Tour Company専用）
```

**メリット**:
- ✅ 完全な独立性

**デメリット**:
- ❌ 運用コスト増大
- ❌ 管理が複雑

**不採用の理由**:
- 管理を複雑にする明確な理由がない

---

### PostgreSQL のテナント分離

#### 選択肢A: 論理分離（client_code）（採用）

**実装方法**:
```sql
-- 単一データベース、client_code で分離
CREATE TABLE clients (
  id SERIAL PRIMARY KEY,
  code VARCHAR UNIQUE NOT NULL,  -- 'ikigai_stay'
  name VARCHAR NOT NULL
);

CREATE TABLE spree_products (
  id SERIAL PRIMARY KEY,
  client_code VARCHAR,  -- テナント識別子
  name VARCHAR,
  -- ...
  FOREIGN KEY (client_code) REFERENCES clients(code)
);

-- クエリ時にテナント分離
SELECT * FROM spree_products WHERE client_code = 'ikigai_stay';
```

**メリット**:
- ✅ **管理がシンプル**: 単一DBインスタンス
- ✅ **横断分析が容易**: 全クライアントデータを統合分析可能
- ✅ **リソース効率**: コネクションプール共有
- ✅ **バックアップ容易**: 1回のバックアップで全テナント保護
- ✅ **スケール容易**: 垂直スケール（スペックアップ）で対応

**デメリット**:
- ⚠️ クエリに`WHERE client_code = ?`が必須（漏れるとデータ漏洩リスク）
- ⚠️ 大規模化時のパフォーマンス懸念

#### 選択肢B: 物理分離（DB毎に分離）（不採用）

**実装方法**:
```
PostgreSQL インスタンス
  ├── DB: ikigai_stay_production
  ├── DB: hotel_example_production
  └── DB: tour_company_production
```

**メリット**:
- ✅ 完全なデータ分離
- ✅ セキュリティ強化
- ✅ テナント毎の個別最適化

**デメリット**:
- ❌ **管理が複雑**: DB数×クライアント数のバックアップ・メンテナンス
- ❌ **横断分析困難**: 複数DBをまたぐクエリが必要
- ❌ **リソース効率悪い**: コネクションプール分散
- ❌ **マイグレーション複雑**: 各DBに個別実行

**検討したが不採用の理由**:
- **管理を複雑にする明確な理由がない**
- 当面は論理分離で十分

#### 選択肢C: スキーマ分離（PostgreSQL Schema）（不採用）

**実装方法**:
```sql
-- 単一DB、スキーマ毎に分離
CREATE SCHEMA ikigai_stay;
CREATE SCHEMA hotel_example;

CREATE TABLE ikigai_stay.products (...);
CREATE TABLE hotel_example.products (...);
```

**メリット**:
- ✅ 論理分離より強固
- ✅ 単一DBインスタンス

**デメリット**:
- ❌ Railsとの相性が悪い
- ❌ マイグレーション複雑

**不採用の理由**:
- Railsの標準的なパターンではない

---

### Rails のテナント分離

#### 選択肢A: client_code スコープ（採用）

**実装方法**:
```ruby
# app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  scope :for_client, ->(code) { where(client_code: code) }
end

# コントローラー
class Api::V1::ProductsController < ApplicationController
  before_action :set_current_client

  def index
    @products = Spree::Product.for_client(@current_client.code)
  end

  private

  def set_current_client
    @current_client = Client.find_by!(code: params[:client_code])
  end
end
```

**メリット**:
- ✅ シンプル
- ✅ PostgreSQL論理分離と一貫性

**デメリット**:
- ⚠️ スコープ漏れのリスク

#### 選択肢B: Apartment gem（不採用）

**概要**:
- マルチテナント専用gem
- スキーマ分離を自動化

**デメリット**:
- ❌ PostgreSQLスキーマ分離が前提
- ❌ 追加の複雑性

**不採用の理由**:
- シンプルなclient_codeスコープで十分

## 決定

**各サービスで論理分離を採用する**

### 実装戦略

| サービス | 分離方法 | 実装 |
|---------|---------|------|
| **n8n** | Projects機能 | 単一インスタンス、Project単位で分離 |
| **Mattermost** | Teams機能 | 単一インスタンス、Team単位で分離 |
| **PostgreSQL** | client_code論理分離 | 単一DB、WHERE句で分離 |
| **Rails** | client_codeスコープ | スコープ・before_actionで分離 |

### 決定の根拠

1. **管理のシンプルさ優先**:
   - 物理分離する明確な理由がない現時点では、論理分離で十分
   - 運用コスト・複雑性を最小化

2. **実装中の判断**:
   - n8n、Mattermostともに実装中にProjects/Teams機能を発見
   - 標準機能で実現可能と判断

3. **将来の拡張性**:
   - 論理分離→物理分離への移行は可能
   - 当面は論理分離で運用

4. **YAGNI原則**:
   - 必要になってから物理分離を検討
   - 過剰な設計を避ける

### テナント分離の実装ガイドライン

#### 1. PostgreSQL

**必須ルール**:
```ruby
# ✅ GOOD: client_code スコープを必ず使用
Spree::Product.for_client('ikigai_stay')

# ❌ BAD: スコープなしのクエリ（全テナントデータ取得）
Spree::Product.all  # 危険！
```

**マイグレーション**:
```ruby
# client_code カラム追加（既存テーブル）
add_column :spree_products, :client_code, :string
add_index :spree_products, :client_code

# 新規テーブル
create_table :cleaning_standards do |t|
  t.string :client_code, null: false, index: true
  # ...
end
```

#### 2. Rails コントローラー

**パターン**:
```ruby
class Api::V1::BaseController < ApplicationController
  before_action :set_current_client

  private

  def set_current_client
    @current_client = Client.find_by!(code: request.headers['X-Client-Code'])
  end
end

class Api::V1::ProductsController < Api::V1::BaseController
  def index
    @products = Spree::Product.for_client(@current_client.code)
    render json: @products
  end
end
```

#### 3. n8n Projects

**運用フロー**:
1. 新規クライアント登録
2. n8n で新規Project作成
3. ワークフロー・クレデンシャルをProject内に作成

#### 4. Mattermost Teams

**運用フロー**:
1. 新規クライアント登録
2. Mattermost で新規Team作成
3. クライアントメンバーを招待

## 結果

### 実現したマルチテナントアーキテクチャ

```
┌─────────────────────────────────────────────────────────┐
│              LandBase AI Suite Platform                 │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ n8n (単一インスタンス)                           │   │
│  │   ├── Project: Ikigai Stay                    │   │
│  │   ├── Project: Hotel Example                    │   │
│  │   └── Project: Tour Company                     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Mattermost (単一インスタンス)                    │   │
│  │   ├── Team: Ikigai Stay Team                  │   │
│  │   ├── Team: Hotel Example Team                  │   │
│  │   └── Team: Tour Company Team                   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ PostgreSQL (単一DB)                              │   │
│  │   └── client_code で論理分離                     │   │
│  │       ├── 'ikigai_stay'                       │   │
│  │       ├── 'hotel_example'                       │   │
│  │       └── 'tour_company'                        │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Rails Platform                                   │   │
│  │   └── client_code スコープで分離                 │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 達成できたこと

1. **シンプルな管理**:
   - 単一インスタンス×4サービスのみ
   - 複雑な運用不要

2. **コスト効率**:
   - リソース共有による効率化
   - 運用コスト最小化

3. **横断分析**:
   - 全クライアントデータの統合分析が容易
   - MarketingAI、AnalyticsAI で活用

4. **スケーラビリティ**:
   - 100+クライアント対応可能
   - 垂直スケール（スペックアップ）で対応

5. **将来の拡張性**:
   - 必要に応じて物理分離へ移行可能

### トレードオフ

- ✅ シンプルさ・管理コスト削減を優先
- ✅ YAGNI原則に基づく実装
- ⚠️ client_codeスコープ漏れのリスク（コードレビューで対応）
- ⚠️ 大規模化時のパフォーマンス懸念（当面は問題なし）

### 将来の移行戦略

**Phase 1** (現在): 論理分離
- 全サービス・DBは論理分離

**Phase 2** (将来): ハイブリッド
- 特定の大規模クライアントのみ物理分離
- 小規模クライアントは論理分離維持

**Phase 3** (大規模化): 完全物理分離
- クライアント毎に独立インフラ
- 必要に応じて実施（当面は想定なし）

## 参考資料

- [n8n Projects Documentation](https://docs.n8n.io/hosting/scaling/projects/)
- [Mattermost Teams Guide](https://docs.mattermost.com/guides/use-mattermost.html)
- [Multi-tenancy with Rails](https://guides.rubyonrails.org/active_record_postgresql.html)
- [ADR 0001: n8n + Mattermost + Rails 統合](./0001-n8n-mattermost-rails-integration.md)

## 関連するADR

- ADR 0001: n8n + Mattermost + Rails 統合アーキテクチャ（前提）
- ADR 0002: フロント/バックオフィス分離（クライアント毎の独立性）
- ADR 0006: Platform基幹アプリ分離（バックオフィス内のマルチテナント管理）
