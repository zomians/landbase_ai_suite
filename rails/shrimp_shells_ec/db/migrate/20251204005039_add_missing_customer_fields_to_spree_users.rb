class AddMissingCustomerFieldsToSpreeUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :spree_users, :allergies, :text, comment: 'アレルギー食材'
    add_column :spree_users, :dietary_restrictions, :text, comment: '食事制限'
    add_column :spree_users, :customer_memo, :text, comment: '顧客メモ'
    add_column :spree_users, :instagram_handle, :string, comment: 'Instagram ID'
    add_column :spree_users, :line_user_id, :string, comment: 'LINE ユーザーID'
    add_column :spree_users, :preferred_carrier, :string, comment: '希望配送業者'
    add_column :spree_users, :preferred_delivery_time, :string, comment: '希望配送時間帯'
    add_column :spree_users, :delivery_memo, :text, comment: '配送メモ'
    
    add_index :spree_users, :instagram_handle
    add_index :spree_users, :line_user_id
  end
end
