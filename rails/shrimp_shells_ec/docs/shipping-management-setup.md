# 配送管理機能セットアップガイド

## 概要

Shrimp Shells ECの配送管理機能は、Solidusの標準配送機能を拡張し、以下の機能を提供します：

- 配送ステータス管理（準備中 → 出荷可能 → 配送中 → 配達中 → 配達完了）
- 配送業者コード管理（ヤマト運輸、佐川急便、日本郵便、西濃運輸）
- 追跡番号の自動URL生成
- 配送予定日管理
- 配達失敗・再配達管理
- 配送遅延アラート

## 技術実装

### データベース設計

#### 追加フィールド（spree_shipments テーブル）

| カラム名 | 型 | 説明 |
|---------|-----|------|
| `carrier_code` | string | 配送業者コード（yamato, sagawa, japan_post, seino） |
| `tracking_url` | string | 追跡URL（自動生成） |
| `estimated_delivery_date` | date | 配送予定日 |
| `delivered_at` | datetime | 配送完了日時 |
| `delivery_attempts` | integer | 配送試行回数（デフォルト: 0） |
| `delivery_notes` | text | 配送メモ |
| `recipient_name` | string | 受取人名 |
| `recipient_phone` | string | 受取人電話番号 |

#### インデックス

- `carrier_code`
- `estimated_delivery_date`
- `delivered_at`

### Decorator パターンによる拡張

#### app/models/spree/shipment_decorator.rb

Solidusの`Spree::Shipment`モデルを非侵襲的に拡張しています。

**主要メソッド**:

- `carrier_name`: 配送業者名を取得
- `delivery_state_name`: 配送ステータス名を取得
- `mark_as_delivered!`: 配達完了をマーク
- `mark_as_failed!(reason:)`: 配達失敗を記録
- `prepare_redelivery!`: 再配達準備
- `mark_out_for_delivery!`: 配達中にマーク
- `generate_tracking_url`: 追跡URLを自動生成
- `days_until_delivery`: 配送予定日までの日数
- `delivery_overdue?`: 配送遅延かどうか
- `status_badge`: 配送ステータスのバッジ表示
- `shipping_summary`: 配送情報のサマリー

**スコープ**:

- `by_carrier(code)`: 配送業者で絞り込み
- `out_for_delivery`: 配達中の配送
- `delivered`: 配達完了の配送
- `delivery_failed`: 配達失敗の配送
- `delivery_today`: 本日配送予定
- `delivery_overdue`: 配送遅延
- `requires_redelivery`: 再配達が必要

## 使用方法

### 1. マイグレーション実行

```bash
cd /Users/hirakuboyusuke/workspace/landbase_ai_suite
make shrimpshells-migrate
```

### 2. 配送業者の設定

```ruby
# Railsコンソール
shipment = Spree::Shipment.first
shipment.carrier_code = 'yamato'
shipment.tracking = '1234567890'
shipment.estimated_delivery_date = 3.days.from_now
shipment.save!

# 追跡URLが自動生成される
shipment.tracking_url
# => "https://toi.kuronekoyamato.co.jp/cgi-bin/tneko?number=1234567890"
```

### 3. 配送ステータスの更新

```ruby
# 出荷可能状態に
shipment.update!(state: 'ready')

# 配送中に
shipment.ship!

# 配達中に
shipment.mark_out_for_delivery!

# 配達完了
shipment.mark_as_delivered!

# 配達失敗を記録
shipment.mark_as_failed!(reason: '不在')

# 再配達準備
shipment.prepare_redelivery!
```

### 4. 配送情報の取得

```ruby
# 配送業者名
shipment.carrier_name
# => "ヤマト運輸"

# 配送ステータス名
shipment.delivery_state_name
# => "配達完了"

# ステータスバッジ
shipment.status_badge
# => "✅ 配達完了"

# 配送情報サマリー
shipment.shipping_summary
# => "配送業者: ヤマト運輸 | 追跡番号: 1234567890 | 配送予定: 2025/12/22"

# 配送予定日までの日数
shipment.days_until_delivery
# => 3

# 配送遅延チェック
shipment.delivery_overdue?
# => false
```

### 5. スコープを使った検索

```ruby
# ヤマト運輸の配送のみ
Spree::Shipment.by_carrier('yamato')

# 本日配送予定
Spree::Shipment.delivery_today

# 配送遅延
Spree::Shipment.delivery_overdue

# 再配達が必要
Spree::Shipment.requires_redelivery

# 配達完了
Spree::Shipment.delivered
```

## 配送業者コード一覧

| コード | 配送業者名 | 追跡URL |
|--------|-----------|---------|
| `yamato` | ヤマト運輸 | https://toi.kuronekoyamato.co.jp/ |
| `sagawa` | 佐川急便 | https://k2k.sagawa-exp.co.jp/ |
| `japan_post` | 日本郵便 | https://trackings.post.japanpost.jp/ |
| `seino` | 西濃運輸 | https://track.seino.co.jp/ |

## 配送ステータス一覧

| State | 日本語名 | 説明 |
|-------|---------|------|
| `pending` | 準備中 | 配送準備前 |
| `ready` | 出荷可能 | 出荷準備完了 |
| `shipped` | 配送中 | 出荷済み、配送中 |
| `out_for_delivery` | 配達中 | 配達員が配達中 |
| `delivered` | 配達完了 | 配達完了 |
| `failed` | 配達失敗 | 配達失敗（不在等） |
| `returned` | 返送 | 返送処理中 |
| `canceled` | キャンセル | キャンセル済み |

## 管理画面での使用

### Solidus管理画面

1. http://localhost:3002/admin にアクセス
2. **Orders** → 注文を選択
3. **Shipments** タブを開く
4. 配送情報を入力：
   - Carrier Code: 配送業者コード（yamato, sagawa, etc.）
   - Tracking: 追跡番号
   - Estimated Delivery Date: 配送予定日
5. **Save** をクリック

### 追跡URLの自動生成

追跡番号と配送業者コードを入力すると、保存時に自動的に追跡URLが生成されます。

### 配送ステータスの変更

- **Ship** ボタン: 配送中に変更
- **Mark as Delivered** ボタン: 配達完了に変更（カスタムボタンを管理画面に追加することで利用可能）

## テスト

### RSpecテストの実行

```bash
# 全テスト実行
make shrimpshells-test

# 配送管理機能のテストのみ
docker compose exec shrimpshells-ec rspec spec/models/spree/shipment_decorator_spec.rb
```

### テストカバレッジ

- モデルバリデーション
- 配送ステータス変更
- 追跡URL生成
- 配送遅延検出
- スコープフィルタリング

## 将来の拡張

### 配送業者API連携

現在の実装は手動入力ベースですが、将来的に以下のAPI連携を追加予定：

- **ヤマト運輸 B2 Cloud API**: 配送状況の自動取得
- **佐川急便 飛伝Ⅱ Web API**: 追跡情報の自動更新
- **日本郵便 郵便追跡サービスAPI**: ステータス自動更新

### 自動通知

- 配送ステータス変更時のMattermost通知
- 配送遅延時のアラート通知
- 配達完了時の顧客メール送信

### ダッシュボード

- 配送状況の可視化
- 配送遅延のレポート
- 配送業者別のパフォーマンス分析

## トラブルシューティング

### マイグレーションエラー

```bash
# マイグレーションをロールバック
docker compose exec shrimpshells-ec bin/rails db:rollback

# 再度マイグレーション
make shrimpshells-migrate
```

### 追跡URLが生成されない

追跡URLは以下の条件で自動生成されます：

1. `tracking`（追跡番号）が入力されている
2. `carrier_code`（配送業者コード）が入力されている
3. 保存時に`generate_tracking_url`メソッドが呼ばれる

手動で生成する場合：

```ruby
shipment.generate_tracking_url
shipment.save!
```

### バリデーションエラー

```ruby
# 無効な配送業者コード
shipment.carrier_code = 'invalid'
shipment.valid?
# => false
shipment.errors[:carrier_code]
# => ["is not included in the list"]

# 過去の配送予定日
shipment.estimated_delivery_date = 1.day.ago
shipment.valid?
# => false
shipment.errors[:estimated_delivery_date]
# => ["は過去の日付にできません"]
```

## 関連ファイル

- **モデル**: `app/models/spree/shipment_decorator.rb`
- **マイグレーション**: `db/migrate/20251219000001_add_shipping_management_fields_to_spree_shipments.rb`
- **テスト**: `spec/models/spree/shipment_decorator_spec.rb`

## 参考資料

- [Solidus Guides - Shipments](https://guides.solidus.io/)
- [ADR 0004: Decorator パターン](../../../docs/adr/0004-decorator-pattern-for-solidus-extension.md)
- [ARCHITECTURE.md](../../../ARCHITECTURE.md)

---

**作成日**: 2025-12-19
**バージョン**: 1.0
**関連Issue**: [#44 配送管理機能の実装](https://github.com/zomians/landbase_ai_suite/issues/44)
