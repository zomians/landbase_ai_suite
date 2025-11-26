# frozen_string_literal: true

# ガーリックシュリンプ在庫のサンプルデータ

puts "Creating stock items with lot numbers and expiry dates..."

# 既存の在庫データをクリア
Spree::StockItem.destroy_all

# デフォルトの在庫保管場所を取得または作成
stock_location = Spree::StockLocation.first || Spree::StockLocation.create!(
  name: "横浜倉庫",
  default: true,
  address1: "横浜市中区本町1-1-1",
  city: "横浜市",
  zipcode: "231-0005",
  country: Spree::Country.find_by(iso: 'JP'),
  active: true
)

# 商品を取得
products = Spree::Product.where("name LIKE ?", "%ガーリックシュリンプ%")

if products.empty?
  puts "⚠️  商品が見つかりません。先にshrimp_products.rbを実行してください。"
  exit
end

# 各商品に対して在庫を作成（1つのバリアントに1つのstockアイテム）
products.each_with_index do |product, index|
  product.variants_including_master.each do |variant|
    # 賞味期限が近い在庫ロット
    stock_item = Spree::StockItem.find_or_create_by!(
      stock_location: stock_location,
      variant: variant
    )
    
    stock_item.assign_attributes(
      lot_number: "LOT-2024-#{(index + 1).to_s.rjust(3, '0')}-Z",
      manufacturing_date: 300.days.ago.to_date,
      expiry_date: 45.days.from_now.to_date,
      received_date: 280.days.ago.to_date,
      supplier_name: ["インドネシア水産", "ベトナムシーフード", "タイ・エビ商社", "横浜貿易"][index % 4],
      purchase_price: (variant.price * 0.55).round(2),
      storage_temperature_actual: -18.2,
      temperature_check_at: 6.hours.ago,
      quality_status: 'warning',
      inspection_date: 30.days.ago.to_date,
      inventory_notes: "賞味期限が近い。優先出荷推奨。"
    )
    stock_item.set_count_on_hand(100 + (index * 20))
    stock_item.save!
    
    puts "✅ #{product.name}: ロット#{stock_item.lot_number} (#{stock_item.count_on_hand}個) - 賞味期限: #{stock_item.expiry_date}"
  end
end

# 在庫統計を表示
puts ""
puts "=== 在庫統計 ==="
puts "総在庫アイテム数: #{Spree::StockItem.count}"
puts "総在庫数: #{Spree::StockItem.sum(:count_on_hand)}個"
puts "良好品質: #{Spree::StockItem.good_quality.count}"
puts "要確認: #{Spree::StockItem.warning_quality.count}"
puts "30日以内に期限切れ: #{Spree::StockItem.expiring_soon(30).count}"
puts "期限切れ: #{Spree::StockItem.expired.count}"
puts ""
total_value = Spree::StockItem.sum('count_on_hand * purchase_price').round(2)
puts "在庫総額（原価ベース）: ¥#{total_value.to_s(:delimited)}"
