class AddShrimpShellsFieldsToSpreeStockItems < ActiveRecord::Migration[8.0]
  def change
    # ロット管理
    add_column :spree_stock_items, :lot_number, :string, comment: 'ロット番号（製造バッチ識別）'
    add_column :spree_stock_items, :manufacturing_date, :date, comment: '製造日'
    add_column :spree_stock_items, :expiry_date, :date, comment: '賞味期限'
    
    # 温度管理
    add_column :spree_stock_items, :storage_temperature_actual, :decimal, precision: 5, scale: 2, comment: '実際の保管温度（℃）'
    add_column :spree_stock_items, :temperature_check_at, :datetime, comment: '最終温度チェック日時'
    
    # 入荷管理
    add_column :spree_stock_items, :received_date, :date, comment: '入荷日'
    add_column :spree_stock_items, :supplier_name, :string, comment: '仕入先名'
    add_column :spree_stock_items, :purchase_price, :decimal, precision: 10, scale: 2, comment: '仕入価格（原価）'
    
    # 品質管理
    add_column :spree_stock_items, :quality_status, :string, default: 'good', null: false, comment: '品質ステータス（good/warning/discard）'
    add_column :spree_stock_items, :inspection_date, :date, comment: '品質検査日'
    add_column :spree_stock_items, :inventory_notes, :text, comment: '在庫メモ（特記事項）'
    
    # FIFO管理用
    add_column :spree_stock_items, :priority_order, :integer, comment: '出荷優先順位'
    
    # インデックスの追加
    add_index :spree_stock_items, :lot_number
    add_index :spree_stock_items, :expiry_date
    add_index :spree_stock_items, :quality_status
    add_index :spree_stock_items, :priority_order
  end
end
