class AddShrimpShellsFieldsToSpreeUsers < ActiveRecord::Migration[8.0]
  def change
    # 基本情報
    add_column :spree_users, :company_name, :string, comment: '会社名/屋号'
    add_column :spree_users, :birth_date, :date, comment: '生年月日'
    add_column :spree_users, :gender, :string, comment: '性別'
    
    # 連絡先情報
    add_column :spree_users, :emergency_contact, :string, comment: '緊急連絡先'
    add_column :spree_users, :line_id, :string, comment: 'LINE ID'
    
    # 購買情報
    add_column :spree_users, :customer_rank, :string, default: 'bronze', comment: '顧客ランク'
    add_column :spree_users, :total_purchase_amount, :decimal, precision: 12, scale: 2, default: 0, comment: '累計購入金額'
    add_column :spree_users, :total_purchase_count, :integer, default: 0, comment: '累計購入回数'
    add_column :spree_users, :last_purchase_date, :date, comment: '最終購入日'
    
    # マーケティング
    add_column :spree_users, :dm_allowed, :boolean, default: true, comment: 'DM送付可否'
    add_column :spree_users, :newsletter_subscribed, :boolean, default: false, comment: 'メルマガ購読'
    
    # 管理情報
    add_column :spree_users, :staff_memo, :text, comment: '担当者メモ'
    add_column :spree_users, :attention_flag, :boolean, default: false, comment: '要注意フラグ'
    add_column :spree_users, :vip_flag, :boolean, default: false, comment: 'VIPフラグ'
    
    # インデックス追加
    add_index :spree_users, :customer_rank
    add_index :spree_users, :last_purchase_date
    add_index :spree_users, :attention_flag
    add_index :spree_users, :vip_flag
    add_index :spree_users, :company_name
  end
end
