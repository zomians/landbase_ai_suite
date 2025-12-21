class AddDeliveryStatusToSpreeShipments < ActiveRecord::Migration[8.0]
  def change
    add_column :spree_shipments, :delivery_status, :string, comment: '詳細配送ステータス(out_for_delivery, delivered, failed, returned)'
    add_index :spree_shipments, :delivery_status
  end
end
