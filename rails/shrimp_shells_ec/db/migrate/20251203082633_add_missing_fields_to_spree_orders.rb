class AddMissingFieldsToSpreeOrders < ActiveRecord::Migration[8.0]
  def change
    # ピッキング管理フィールド
    add_column :spree_orders, :picking_started_at, :datetime, comment: 'ピッキング開始日時'
    add_column :spree_orders, :picking_inspector_name, :string, comment: '検品担当者名'
    
    # 配送メモ
    add_column :spree_orders, :packing_note, :text, comment: '梱包メモ'
    add_column :spree_orders, :delivery_note, :text, comment: '配送メモ'
    
    # 管理フラグ
    add_column :spree_orders, :temperature_controlled, :boolean, default: true, comment: '温度管理必須フラグ'
    add_column :spree_orders, :subscription_order, :boolean, default: false, comment: '定期購入注文フラグ'
    
    # 外部連携
    add_column :spree_orders, :instagram_order_id, :string, comment: 'Instagram注文ID'
    add_column :spree_orders, :tracking_url, :string, comment: '配送追跡URL'
    
    # インデックス追加
    add_index :spree_orders, :picking_started_at
    add_index :spree_orders, :temperature_controlled
    add_index :spree_orders, :subscription_order
    add_index :spree_orders, :instagram_order_id
  end
end
