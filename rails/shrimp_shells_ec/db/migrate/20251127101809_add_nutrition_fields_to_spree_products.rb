class AddNutritionFieldsToSpreeProducts < ActiveRecord::Migration[8.0]
  def change
    # 栄養成分表示（100gあたり）
    add_column :spree_products, :calories, :decimal, precision: 6, scale: 2, comment: 'エネルギー(kcal)'
    add_column :spree_products, :protein, :decimal, precision: 5, scale: 2, comment: 'たんぱく質(g)'
    add_column :spree_products, :fat, :decimal, precision: 5, scale: 2, comment: '脂質(g)'
    add_column :spree_products, :carbohydrate, :decimal, precision: 5, scale: 2, comment: '炭水化物(g)'
    add_column :spree_products, :sodium, :decimal, precision: 6, scale: 2, comment: '食塩相当量(g)'
    
    # インデックス
    add_index :spree_products, :calories
  end
end
