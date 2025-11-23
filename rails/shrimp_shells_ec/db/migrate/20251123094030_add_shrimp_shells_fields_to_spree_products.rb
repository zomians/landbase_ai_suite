class AddShrimpShellsFieldsToSpreeProducts < ActiveRecord::Migration[8.0]
  def change
    # エビの原産地情報
    add_column :spree_products, :shrimp_origin, :string, comment: 'エビの原産地（例：インドネシア、ベトナム、タイ）'
    
    # エビのサイズ（L、M、Sなど）
    add_column :spree_products, :shrimp_size, :string, comment: 'エビのサイズ区分'
    
    # 賞味期限情報
    add_column :spree_products, :expiry_days, :integer, comment: '製造日からの賞味期限（日数）'
    add_column :spree_products, :best_before_months, :integer, comment: '製造日からの賞味期限（月数）'
    
    # 保管温度（摂氏）
    add_column :spree_products, :storage_temperature, :decimal, precision: 5, scale: 2, comment: '推奨保管温度（℃）'
    
    # アレルゲン情報
    add_column :spree_products, :allergens, :text, comment: 'アレルゲン情報（甲殻類、調味料など）'
    
    # 栄養成分情報（JSON形式で詳細な栄養成分を保存）
    add_column :spree_products, :nutritional_info, :jsonb, default: {}, comment: '栄養成分情報（カロリー、タンパク質、脂質など）'
    
    # 調理方法と提供方法
    add_column :spree_products, :cooking_instructions, :text, comment: '調理方法・解凍方法'
    add_column :spree_products, :serving_suggestions, :text, comment: '提供・盛り付けの提案'
    
    # 重量情報（グラム）
    add_column :spree_products, :net_weight, :decimal, precision: 10, scale: 2, comment: '内容量（g）'
    add_column :spree_products, :gross_weight, :decimal, precision: 10, scale: 2, comment: '総重量（g）'
    
    # パッケージ寸法（例：20cm x 15cm x 5cm）
    add_column :spree_products, :package_dimensions, :string, comment: 'パッケージ寸法'
    
    # 漁獲・養殖方法
    add_column :spree_products, :catch_method, :string, comment: '漁獲方法（養殖、天然など）'
    
    # 加工日
    add_column :spree_products, :processing_date, :date, comment: '加工日'
    
    # 認証情報
    add_column :spree_products, :halal_certified, :boolean, default: false, null: false, comment: 'ハラール認証の有無'
    add_column :spree_products, :organic_certified, :boolean, default: false, null: false, comment: 'オーガニック認証の有無'
    
    # インデックスの追加
    add_index :spree_products, :shrimp_origin
    add_index :spree_products, :shrimp_size
    add_index :spree_products, :processing_date
  end
end
