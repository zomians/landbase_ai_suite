# ADR 0004: Solidus拡張にDecoratorパターン採用

## ステータス

採用（Accepted）

## 日付

2025-11-22

## コンテキスト（背景・課題）

ADR 0003 で Solidus を restaurant ECサイトのフレームワークとして採用したが、冷凍食品の特殊性（保管温度、賞味期限、エビサイズなど）に対応するため、**Solidusの標準モデル（Product, Order, StockItem等）にカスタムフィールドを追加**する必要があった。

### 技術要件

1. **非侵襲的な拡張**:
   - Solidus gem のソースコードを直接変更しない
   - バージョンアップ時に変更が消えない
   - Solidusのコア機能を壊さない

2. **メソッド追加・上書き**:
   - 既存メソッドの振る舞いを変更できる
   - 新しいメソッドを追加できる
   - バリデーション、スコープ、コールバックを追加できる

3. **保守性**:
   - コードが明確で理解しやすい
   - テストが書きやすい
   - チーム開発に適している

### カスタマイズの具体例

**冷凍食品フィールド追加**:
```ruby
# Products
- shrimp_origin: エビの原産地
- shrimp_size: エビのサイズ（XL/L/M/S）
- storage_temperature: 保管温度（℃）

# Orders
- preferred_delivery_date: 希望配送日
- packing_temperature: 梱包時温度

# StockItems
- lot_number: ロット番号
- expiry_date: 賞味期限
```

## 検討した選択肢

### 選択肢1: Decorator パターン（`prepend`）（採用）

**実装方法**:
```ruby
# app/models/spree/product_decorator.rb
module Spree
  module ProductDecorator
    def self.prepended(base)
      # クラスレベルの定義
      base.const_set(:SHRIMP_SIZES, {
        xl: '特大（XL）', l: '大（L）', m: '中（M）', s: '小（S）'
      })

      # バリデーション追加
      base.validates :shrimp_size,
        inclusion: { in: SHRIMP_SIZES.keys.map(&:to_s), allow_blank: true }

      # スコープ追加
      base.scope :by_shrimp_size, ->(size) { where(shrimp_size: size) }
      base.scope :frozen_products, -> { where('storage_temperature < ?', 0) }
    end

    # インスタンスメソッド追加
    def frozen_product?
      storage_temperature.present? && storage_temperature < 0
    end

    # 既存メソッド上書き（superで元のメソッド呼び出し可能）
    def requires_special_shipping?
      super || frozen_product?
    end
  end
end

# prepend で適用
Spree::Product.prepend(Spree::ProductDecorator)
```

**メリット**:
- ✅ **非侵襲的**: Gemのソースコードを変更しない
- ✅ **バージョンアップ安全**: Solidusアップデート時も変更が維持される
- ✅ **メソッド上書き可能**: `prepend`でメソッドチェーンの先頭に追加されるため、元のメソッドを上書き可能
- ✅ **superでオリジナル呼び出し可能**: 元の振る舞いを残しつつ拡張できる
- ✅ **明確な分離**: ビジネスロジック（Decorator）とコア機能（Solidus）が分離
- ✅ **テスト可能**: Decoratorのみをテストできる
- ✅ **Solidusベストプラクティス**: 公式推奨パターン

**デメリット**:
- ⚠️ 学習コスト: `prepend`と`include`の違いを理解する必要がある
- ⚠️ ファイル命名規則: `*_decorator.rb` パターンを統一する必要

### 選択肢2: Concerns（`include`）（不採用）

**実装方法**:
```ruby
# app/models/concerns/frozen_product.rb
module FrozenProduct
  extend ActiveSupport::Concern

  included do
    validates :storage_temperature, presence: true
  end

  def frozen_product?
    storage_temperature < 0
  end
end

# Spree::Product.include(FrozenProduct)
```

**メリット**:
- ✅ シンプル
- ✅ Railsの標準パターン

**デメリット**:
- ❌ **メソッド上書き不可**: `include`はメソッドチェーンの末尾に追加されるため、既存メソッドを上書きできない
- ❌ Solidus特有のパターンではない

**不採用の理由**:
- 既存メソッドの振る舞いを変更できない

### 選択肢3: Direct Modification（直接編集）（不採用）

**実装方法**:
```ruby
# vendor/bundle/gems/solidus_core-X.X.X/app/models/spree/product.rb
class Spree::Product < Spree::Base
  # 直接編集（危険！）
  validates :shrimp_size, ...
end
```

**メリット**:
- ✅ 直感的

**デメリット**:
- ❌ **バージョンアップ時に消える**: `bundle update`で変更が失われる
- ❌ **侵襲的**: Gemのソースコードを汚染
- ❌ **チーム開発困難**: 変更が追跡できない
- ❌ **メンテナンス不可能**: 面倒すぎる

**不採用の理由**:
- 実装中に面倒だと判断
- 持続可能性ゼロ

### 選択肢4: Fork（不採用）

**実装方法**:
```ruby
# Gemfile
gem 'solidus', github: 'your-org/solidus', branch: 'custom'
```

**メリット**:
- ✅ 完全な自由度

**デメリット**:
- ❌ **メンテナンスコスト膨大**: Solidusのアップデートを手動でマージ
- ❌ **面倒**: 実装中に却下
- ❌ セキュリティパッチの適用が遅れる

**不採用の理由**:
- メンテナンスコストが現実的でない

### 選択肢5: Event Subscribers（不採用）

**実装方法**:
```ruby
# Solidusのイベントシステムを使用
Spree::Event.subscribe 'order_finalized' do |event|
  order = event.payload[:order]
  # カスタム処理
end
```

**メリット**:
- ✅ 疎結合
- ✅ イベント駆動

**デメリット**:
- ❌ **モデル拡張に不向き**: フィールド追加やメソッド追加には使えない
- ❌ 限定的なカスタマイズのみ

**不採用の理由**:
- カスタムフィールド追加という要件に合わない

## 決定

**Decorator パターン（`prepend`）を Solidus拡張の標準方法として採用する**

### 決定の根拠

1. **チームメンバーの採用実績**:
   - 実装中にチームメンバーがDecoratorパターンを採用
   - 実装がスムーズに進んだ

2. **Solidusベストプラクティス**:
   - Solidus公式が推奨するパターン
   - 他のSolidusプロジェクトでも広く採用

3. **非侵襲的・安全**:
   - Solidusのバージョンアップに強い
   - Gemのソースコード変更不要

4. **他の選択肢の問題**:
   - Direct Modification: 面倒、バージョンアップで消える
   - Fork: 面倒、メンテナンスコスト膨大
   - Concerns: メソッド上書き不可
   - Event Subscribers: モデル拡張に不向き

### Decorator パターンの実装ルール

#### 1. ファイル配置

```
app/
├── models/
│   └── spree/
│       ├── product_decorator.rb
│       ├── order_decorator.rb
│       ├── user_decorator.rb
│       └── stock_item_decorator.rb
└── controllers/
    └── spree/admin/
        ├── products_controller_decorator.rb
        └── orders_controller_decorator.rb
```

#### 2. 命名規則

- **ファイル名**: `{original_class_name}_decorator.rb`
- **モジュール名**: `{OriginalClassName}Decorator`

#### 3. 基本構造

```ruby
module Spree
  module ProductDecorator
    def self.prepended(base)
      # クラスレベルの定義（バリデーション、スコープ、定数など）
    end

    # インスタンスメソッド
    def custom_method
      # ...
    end

    # 既存メソッド上書き
    def existing_method
      super # 元のメソッド呼び出し
      # 追加処理
    end
  end
end

Spree::Product.prepend(Spree::ProductDecorator)
```

#### 4. テスト

```ruby
# spec/models/spree/product_decorator_spec.rb
require 'rails_helper'

RSpec.describe Spree::Product, type: :model do
  describe 'Decorator拡張' do
    describe '#frozen_product?' do
      it '保管温度が0℃未満の場合trueを返す' do
        product = build(:product, storage_temperature: -18)
        expect(product.frozen_product?).to be true
      end
    end
  end
end
```

## 結果

### 実現したDecoratorパターン

```
Solidus Core Models
     ↑ prepend（メソッドチェーン先頭に追加）
Decorator Modules
     ↑ ビジネスロジック
Custom Fields & Methods
```

**実装例**:
- `spree/product_decorator.rb`: 冷凍食品フィールド（30+カスタムフィールド）
- `spree/order_decorator.rb`: 配送管理フィールド（15+カスタムフィールド）
- `spree/user_decorator.rb`: 顧客管理フィールド（12+カスタムフィールド）
- `spree/stock_item_decorator.rb`: 在庫管理フィールド（8+カスタムフィールド）

### 達成できたこと

1. **安全な拡張**:
   - Solidusのバージョンアップ時も変更が維持される
   - Gemのソースコード汚染なし

2. **柔軟性**:
   - メソッド追加、上書きが自由
   - バリデーション、スコープ、コールバック追加が容易

3. **保守性**:
   - ビジネスロジックとコア機能が明確に分離
   - テストが書きやすい

4. **チーム開発**:
   - パターンが統一され、理解しやすい
   - 新しいメンバーも学習しやすい

5. **再利用性**:
   - 他のrestaurant ECサイトでも同じパターンを適用可能

### トレードオフ

- ✅ 非侵襲的・安全性を優先
- ✅ Solidusベストプラクティスに準拠
- ⚠️ `prepend`の理解が必要（学習コスト）

### 実装実績

- **Products**: 30+カスタムフィールド追加
- **Orders**: 15+カスタムフィールド追加
- **Users**: 12+カスタムフィールド追加
- **StockItems**: 8+カスタムフィールド追加
- **Controllers**: 管理画面カスタマイズ（4+Decorator）

## 参考資料

- [Solidus Customization Guide](https://guides.solidus.io/customization)
- [Ruby prepend vs include](https://www.rubyguides.com/2017/03/prepend-method/)
- [ADR 0003: Solidus採用](./0003-solidus-for-restaurant-ec.md)

## 関連するADR

- ADR 0003: restaurant ECサイトに Solidus を採用（前提）
- ADR 0001: Rails採用（技術スタック）
