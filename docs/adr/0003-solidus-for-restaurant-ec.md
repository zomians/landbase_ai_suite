# ADR 0003: restaurant ECサイトに Solidus を採用

## ステータス

採用（Accepted）

## 日付

2025-11-20

## コンテキスト（背景・課題）

ADR 0002 でフロント/バックオフィス分離アーキテクチャを採用し、クライアント業種別のフロントサービスを実装することが決定された。最初のフロントサービスとして、**restaurant向けECサイト（Shrimp Shells EC）** を実装する必要があった。

### ビジネス要件

1. **冷凍&食品ECの特殊性**:
   - 冷凍食品の取り扱い（保管温度管理、配送時温度維持）
   - 食品固有の情報（賞味期限、原産地、アレルゲン、栄養成分）
   - エビ専門ECとしての特殊フィールド（エビサイズ、漁獲方法、認証情報）

2. **複数ECサイト立ち上げの可能性**:
   - 今後、他のrestaurantクライアント向けにもECサイトを立ち上げる可能性
   - **80%の機能を自動生成**できるフレームワークが必要
   - クライアント毎のカスタマイズは最小限に抑える

3. **開発速度とコスト**:
   - 自前実装する部分を最小限に
   - 標準的なEC機能（商品管理、注文管理、決済、在庫管理）は既製品を活用
   - Rails との親和性

### 技術要件

- Rails 8 との統合
- 管理画面の充実
- 拡張性（カスタムフィールド追加）
- マルチテナント対応（将来）
- OSS（コスト効率）

## 検討した選択肢

### 選択肢1: Solidus（採用）

**概要**:
- Spree Commerce から fork されたエンタープライズ向けECフレームワーク
- Rails専用、完全なOSS
- モジュラー設計、拡張性が高い

**メリット**:
- ✅ **Rails & Solidus で自前実装が最小限**
- ✅ **80%の機能が標準装備**:
  - 商品管理（Product, Variant, Option）
  - 注文管理（Order, LineItem, Payment）
  - 在庫管理（StockItem, StockLocation）
  - 顧客管理（User, Address）
  - 決済統合（PayPal, Stripe等）
  - 配送管理（Shipment, ShippingMethod）
  - 税金計算（Tax）
  - クーポン・プロモーション（Promotion, Adjustment）
- ✅ **Solidus Backend**: 強力な管理画面が標準搭載
- ✅ **拡張性**: Decoratorパターンでカスタマイズ可能
- ✅ **Rails 8 対応**: 最新Railsとの互換性
- ✅ **ViewComponent サポート**: モダンなUI開発
- ✅ **エンタープライズ実績**: 大規模EC事例が豊富

**デメリット**:
- ⚠️ 学習曲線（Solidusのアーキテクチャ理解が必要）
- ⚠️ カスタマイズにはDecoratorパターンの理解が必要

### 選択肢2: Shopify（不採用）

**概要**:
- SaaS型ECプラットフォーム
- ノーコード/ローコードでEC構築

**メリット**:
- ✅ 即座に構築可能
- ✅ 管理画面が洗練
- ✅ 決済・配送統合が容易

**デメリット**:
- ❌ **OSSではない**（月額費用 + 手数料）
- ❌ カスタマイズ性が限定的（冷凍食品特有フィールド追加が困難）
- ❌ 複数サイト立ち上げ時のコスト増
- ❌ バックオフィス（Platform Rails）との統合が複雑

**不採用の理由**:
- OSS要件を満たさない
- 冷凍食品の特殊性に対応困難

### 選択肢3: WooCommerce（不採用）

**概要**:
- WordPress用ECプラグイン
- OSS、無料

**メリット**:
- ✅ OSS
- ✅ 導入が容易
- ✅ プラグインエコシステムが豊富

**デメリット**:
- ❌ **Rails との統合が困難**
- ❌ PHP/WordPressスタックが必要（技術スタック分散）
- ❌ API統合が複雑（Platform RailsとのMarketingAI連携）

**不採用の理由**:
- Rails技術スタックと統合できない

### 選択肢4: 自前実装（Rails scaffold）（不採用）

**概要**:
- Rails scaffoldで一から実装

**メリット**:
- ✅ 完全なカスタマイズ自由度
- ✅ 軽量（不要な機能なし）

**デメリット**:
- ❌ **開発コストが膨大**（商品、注文、決済、在庫すべて実装）
- ❌ 決済統合、配送統合を一から実装
- ❌ 管理画面を一から構築
- ❌ 80%自動生成という要件を満たさない

**不採用の理由**:
- 開発コスト・時間が現実的でない

### 選択肢5: Spree Commerce（不採用）

**概要**:
- Solidusの元となったOSS ECフレームワーク

**メリット**:
- ✅ OSS
- ✅ Rails統合

**デメリット**:
- ❌ メンテナンスが停滞
- ❌ エンタープライズサポートが弱い
- ❌ Solidusの方が活発に開発されている

**不採用の理由**:
- Solidusの方が優れている

## 決定

**Solidus を restaurant ECサイトのフレームワークとして採用する**

### 決定の根拠

1. **Rails & Solidus で自前実装を最小化**:
   - 80%の標準EC機能がすぐに使える
   - 商品、注文、在庫、決済、配送すべてが標準装備

2. **冷凍食品特有フィールドの追加**:
   - Decoratorパターンで既存モデルを拡張（後述：ADR 0004）
   - カスタムフィールド（保管温度、賞味期限、エビサイズ等）を追加
   - **現時点ではPoC（Proof of Concept）レベル**で対応

3. **複数ECサイト展開に対応**:
   - 他のrestaurantクライアントにも同じ構成を展開可能
   - Solidus標準機能 + Decoratorカスタマイズのパターンを確立

4. **管理画面の充実**:
   - Solidus Backend で商品、注文、顧客、在庫を一元管理
   - 管理画面開発コストがゼロ

5. **Rails 8 との統合**:
   - 同じRailsエコシステム内で完結
   - Platform Rails API との連携が容易

### 冷凍食品対応（PoCレベル）

**カスタムフィールド追加例**:
```ruby
# Products
- shrimp_origin: エビの原産地
- shrimp_size: エビのサイズ（XL/L/M/S）
- catch_method: 漁獲方法（養殖/天然/混合）
- storage_temperature: 保管温度（℃）
- halal_certified: ハラール認証
- organic_certified: オーガニック認証
- allergens: アレルゲン情報
- nutritional_info: 栄養成分（JSON）

# Orders
- preferred_delivery_date: 希望配送日
- carrier_code: 配送業者（ヤマト/佐川/日本郵便）
- packing_temperature: 梱包時温度
- ice_pack_count: 保冷剤数量

# StockItems
- lot_number: ロット番号
- expiry_date: 賞味期限
- quality_status: 品質ステータス
```

**実装方針**:
- Decoratorパターンでモデル拡張（ADR 0004で詳述）
- マイグレーションでカラム追加
- 管理画面はSolidus Backendをそのまま活用

## 結果

### 実現したアーキテクチャ

```
Shrimp Shells EC (Rails 8 + Solidus)
├── Solidus標準機能（80%）
│   ├── 商品管理（Product, Variant）
│   ├── 注文管理（Order, LineItem）
│   ├── 在庫管理（StockItem）
│   ├── 顧客管理（User, Address）
│   ├── 決済統合（PayPal Commerce Platform）
│   ├── 配送管理（Shipment）
│   └── 管理画面（Solidus Backend）
│
└── カスタマイズ（20%）
    ├── 冷凍食品フィールド（Decorator）
    ├── ストアフロントUI（ViewComponent + Tailwind）
    └── Platform Rails API連携
```

### 達成できたこと

1. **開発速度**:
   - Solidus標準機能で80%完成
   - 自前実装は冷凍食品特有部分のみ

2. **EC機能の充実**:
   - 商品、注文、在庫、決済、配送すべて標準搭載
   - 管理画面も標準で利用可能

3. **拡張性**:
   - Decoratorパターンで冷凍食品フィールドを追加
   - Solidusのアップデートに影響されにくい

4. **再利用性**:
   - 他のrestaurantクライアントにも展開可能
   - パターンが確立

5. **MarketingAI 連携**:
   - Platform Rails API経由でアクセス解析データ送信
   - 価格最適化、レコメンドを反映

### トレードオフ

- ✅ 開発速度・コスト削減を優先
- ✅ 80%自動生成という要件を達成
- ⚠️ Solidusのアーキテクチャ学習コスト（許容範囲）
- ⚠️ 冷凍食品対応はPoCレベル（今後改善予定）

### 今後の課題

1. **冷凍食品機能の本格実装**:
   - PoCから本番レベルへ
   - 配送時温度管理の自動化
   - 賞味期限アラート機能

2. **他クライアントへの展開**:
   - restaurant クライアント向けEC立ち上げ
   - Solidus + Decoratorパターンの再利用

3. **MarketingAI 連携の強化**:
   - リアルタイム価格最適化
   - AIレコメンデーション統合

## 参考資料

- [Solidus公式サイト](https://solidus.io/)
- [Solidus GitHub](https://github.com/solidusio/solidus)
- [Solidus Guides](https://guides.solidus.io/)
- [ADR 0002: フロント/バックオフィス分離](./0002-frontend-backend-separation.md)

## 関連するADR

- ADR 0002: フロント/バックオフィス分離アーキテクチャ（前提）
- ADR 0004: Solidus拡張にDecoratorパターン採用（カスタマイズ方法）
