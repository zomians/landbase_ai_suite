# frozen_string_literal: true

puts "Creating sample orders with frozen food shipping details..."

# 既存のユーザーと商品を取得
user = Spree::User.first
return unless user

products = Spree::Product.limit(3)
return if products.empty?

store = Spree::Store.first
stock_location = Spree::StockLocation.first

# 住所データ
addresses = [
  {
    name: '山田太郎',
    address1: '東京都渋谷区道玄坂1-2-3',
    address2: 'マンション101',
    city: '渋谷区',
    zipcode: '150-0043',
    phone: '03-1234-5678',
    state_name: '東京都',
    country: Spree::Country.find_by(iso: 'JP')
  },
  {
    name: '佐藤花子',
    address1: '大阪府大阪市北区梅田1-1-1',
    address2: 'ビル5F',
    city: '大阪市北区',
    zipcode: '530-0001',
    phone: '06-9876-5432',
    state_name: '大阪府',
    country: Spree::Country.find_by(iso: 'JP')
  },
  {
    name: '鈴木次郎',
    address1: '神奈川県横浜市中区本町1-1',
    address2: '',
    city: '横浜市中区',
    zipcode: '231-0005',
    phone: '045-123-4567',
    state_name: '神奈川県',
    country: Spree::Country.find_by(iso: 'JP')
  }
]

delivery_time_slots = [
  '午前中(8-12時)',
  '12-14時',
  '14-16時',
  '16-18時',
  '18-20時',
  '19-21時'
]

# 5件の注文を作成
5.times do |i|
  address_data = addresses[i % addresses.length]
  
  # 注文を作成
  order = Spree::Order.create!(
    user: user,
    email: user.email,
    store: store,
    currency: 'JPY',
    state: 'complete',
    completed_at: i.days.ago,
    
    # 配送関連
    preferred_delivery_date: (i + 3).days.from_now.to_date,
    preferred_delivery_time: delivery_time_slots[i % 6],
    redelivery_count: [0, 0, 0, 1, 0][i], # 1件のみ再配達あり
    
    # 冷凍食品管理
    packing_temperature: [-18.0, -20.0, -16.0, -19.0, -18.5][i],
    ice_pack_count: [3, 4, 3, 5, 4][i],
    temperature_alert: [false, false, true, false, false][i], # 1件のみ温度異常
    temperature_recorded_at: i.days.ago,
    
    # 出荷管理
    scheduled_ship_date: (i + 2).days.from_now.to_date,
    picking_completed_at: [nil, 1.hour.ago, 2.hours.ago, nil, 30.minutes.ago][i],
    inspector_name: [nil, '田中', '山本', nil, '佐々木'][i],
    carrier_code: [:yamato, :sagawa, :yamato, :japan_post, :yamato][i].to_s,
    tracking_number: ["123456789012", "234567890123", nil, "345678901234", "456789012345"][i],
    
    # メモ
    order_notes: ["お届け時間厳守でお願いします", nil, "不在時は宅配ボックスへ", "冷凍庫がいっぱいなので分けて配送", nil][i],
    internal_memo: [nil, "優良顧客", "初回購入", nil, "リピーター"][i]
  )

  # 請求先・配送先住所を作成
  bill_address = Spree::Address.create!(address_data)
  ship_address = Spree::Address.create!(address_data)
  
  order.update!(
    bill_address: bill_address,
    ship_address: ship_address
  )

  # 注文明細を追加
  product_count = (i % 2) + 1
  products.sample(product_count).each do |product|
    variant = product.master
    quantity = [1, 2, 3].sample

    line_item = order.line_items.create!(
      variant: variant,
      quantity: quantity,
      price: variant.price
    )

    # 在庫から引き落とし
    stock_item = stock_location.stock_item(variant)
    if stock_item && stock_item.count_on_hand >= quantity
      stock_item.set_count_on_hand(stock_item.count_on_hand - quantity)
    end
  end

  # 金額を再計算
  order.recalculate

  puts "Created order ##{order.number} (#{order.delivery_status_badge}) - ¥#{order.total.to_i}"
end

puts "\nOrder summary:"
puts "Total orders: #{Spree::Order.count}"
puts "Delivery scheduled: #{Spree::Order.delivery_scheduled.count}"
puts "Requires shipping: #{Spree::Order.requires_shipping.count}"
puts "Picking completed: #{Spree::Order.picking_completed.count}"
puts "Temperature alerts: #{Spree::Order.temperature_alerts.count}"
puts "Redelivery orders: #{Spree::Order.redelivery_orders.count}"
