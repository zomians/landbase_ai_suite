class AddShrimpShellsFieldsToSpreeOrders < ActiveRecord::Migration[8.0]
  def change
    # 配送関連フィールド
    add_column :spree_orders, :preferred_delivery_date, :date, comment: '希望配送日'
    add_column :spree_orders, :preferred_delivery_time, :string, comment: '希望配送時間帯'
    add_column :spree_orders, :redelivery_count, :integer, default: 0, comment: '再配達回数'
    
    # 冷凍食品管理フィールド
    add_column :spree_orders, :packing_temperature, :decimal, precision: 5, scale: 2, comment: '梱包時温度(℃)'
    add_column :spree_orders, :ice_pack_count, :integer, default: 0, comment: '保冷剤数量'
    add_column :spree_orders, :temperature_alert, :boolean, default: false, comment: '温度異常フラグ'
    add_column :spree_orders, :temperature_recorded_at, :datetime, comment: '温度記録日時'
    
    # 出荷・ピッキング管理
    add_column :spree_orders, :scheduled_ship_date, :date, comment: '出荷予定日'
    add_column :spree_orders, :picking_completed_at, :datetime, comment: 'ピッキング完了日時'
    add_column :spree_orders, :inspector_name, :string, comment: '検品担当者名'
    add_column :spree_orders, :carrier_code, :string, comment: '配送業者コード'
    add_column :spree_orders, :tracking_number, :string, comment: '追跡番号'
    
    # 受注メモ・備考
    add_column :spree_orders, :order_notes, :text, comment: '受注メモ'
    add_column :spree_orders, :internal_memo, :text, comment: '社内メモ'
    
    # インデックス追加
    add_index :spree_orders, :preferred_delivery_date
    add_index :spree_orders, :scheduled_ship_date
    add_index :spree_orders, :picking_completed_at
    add_index :spree_orders, :temperature_alert
    add_index :spree_orders, :tracking_number
  end
end
