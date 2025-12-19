# frozen_string_literal: true

class AddShippingManagementFieldsToSpreeShipments < ActiveRecord::Migration[8.0]
  def change
    add_column :spree_shipments, :carrier_code, :string, comment: '配送業者コード(yamato, sagawa, japan_post, seino)'
    add_column :spree_shipments, :tracking_url, :string, comment: '追跡URL'
    add_column :spree_shipments, :estimated_delivery_date, :date, comment: '配送予定日'
    add_column :spree_shipments, :delivered_at, :datetime, comment: '配送完了日時'
    add_column :spree_shipments, :delivery_attempts, :integer, default: 0, comment: '配送試行回数'
    add_column :spree_shipments, :delivery_notes, :text, comment: '配送メモ'
    add_column :spree_shipments, :recipient_name, :string, comment: '受取人名'
    add_column :spree_shipments, :recipient_phone, :string, comment: '受取人電話番号'
    add_column :spree_shipments, :delivery_status, :string, comment: '詳細配送ステータス(out_for_delivery, delivered, failed, returned)'
    
    add_index :spree_shipments, :carrier_code
    add_index :spree_shipments, :estimated_delivery_date
    add_index :spree_shipments, :delivered_at
    add_index :spree_shipments, :delivery_status
  end
end
