# frozen_string_literal: true

puts "Creating sample customers with detailed profiles..."

# 既存のユーザー数を確認
existing_users = Spree::User.where.not(email: 'admin@example.com').count
puts "Existing users (excluding admin): #{existing_users}"

# 顧客データ
customers_data = [
  {
    email: 'yamada.taro@example.com',
    password: 'password123',
    company_name: '山田商店',
    birth_date: Date.new(1980, 5, 15),
    gender: 'male',
    emergency_contact: '090-1111-2222',
    line_id: 'yamada_taro',
    customer_rank: 'platinum',
    total_purchase_amount: 580000,
    total_purchase_count: 45,
    last_purchase_date: 5.days.ago.to_date,
    dm_allowed: true,
    newsletter_subscribed: true,
    vip_flag: true,
    staff_memo: '優良顧客。毎月定期購入あり。'
  },
  {
    email: 'sato.hanako@example.com',
    password: 'password123',
    company_name: nil,
    birth_date: Date.new(1992, 8, 22),
    gender: 'female',
    emergency_contact: '090-3333-4444',
    line_id: 'hanako_s',
    customer_rank: 'gold',
    total_purchase_amount: 285000,
    total_purchase_count: 28,
    last_purchase_date: 12.days.ago.to_date,
    dm_allowed: true,
    newsletter_subscribed: true,
    vip_flag: false,
    staff_memo: '冷凍エビを好んで購入。'
  },
  {
    email: 'suzuki.jiro@example.com',
    password: 'password123',
    company_name: '鈴木飲食店',
    birth_date: Date.new(1975, 3, 10),
    gender: 'male',
    emergency_contact: '090-5555-6666',
    line_id: nil,
    customer_rank: 'silver',
    total_purchase_amount: 125000,
    total_purchase_count: 15,
    last_purchase_date: 45.days.ago.to_date,
    dm_allowed: true,
    newsletter_subscribed: false,
    vip_flag: false,
    staff_memo: '業務用で大量購入。配送時間に注意。'
  },
  {
    email: 'tanaka.yuki@example.com',
    password: 'password123',
    company_name: nil,
    birth_date: Date.new(1998, 11, 5),
    gender: 'female',
    emergency_contact: '090-7777-8888',
    line_id: 'yuki_t',
    customer_rank: 'bronze',
    total_purchase_amount: 28000,
    total_purchase_count: 8,
    last_purchase_date: 120.days.ago.to_date,
    dm_allowed: false,
    newsletter_subscribed: false,
    vip_flag: false,
    staff_memo: '休眠顧客。再アプローチ検討。'
  },
  {
    email: 'watanabe.kenji@example.com',
    password: 'password123',
    company_name: '渡辺水産',
    birth_date: Date.new(1968, 7, 28),
    gender: 'male',
    emergency_contact: '090-9999-0000',
    line_id: 'watanabe_k',
    customer_rank: 'gold',
    total_purchase_amount: 320000,
    total_purchase_count: 32,
    last_purchase_date: 8.days.ago.to_date,
    dm_allowed: true,
    newsletter_subscribed: true,
    vip_flag: true,
    staff_memo: '業務用顧客。請求書払い希望。'
  },
  {
    email: 'kobayashi.mika@example.com',
    password: 'password123',
    company_name: nil,
    birth_date: Date.new(1985, 12, 18),
    gender: 'female',
    emergency_contact: '090-1234-5678',
    line_id: 'mika_k',
    customer_rank: 'bronze',
    total_purchase_amount: 15000,
    total_purchase_count: 3,
    last_purchase_date: 10.days.ago.to_date,
    dm_allowed: true,
    newsletter_subscribed: true,
    vip_flag: false,
    staff_memo: '新規顧客。初回割引適用済み。'
  },
  {
    email: 'ito.takeshi@example.com',
    password: 'password123',
    company_name: '伊藤食品',
    birth_date: Date.new(1972, 4, 3),
    gender: 'male',
    emergency_contact: '090-2345-6789',
    line_id: nil,
    customer_rank: 'silver',
    total_purchase_amount: 95000,
    total_purchase_count: 12,
    last_purchase_date: 30.days.ago.to_date,
    dm_allowed: false,
    newsletter_subscribed: false,
    attention_flag: true,
    staff_memo: '過去にクレームあり。慎重に対応。'
  }
]

customers_data.each do |data|
  # 既存ユーザーをスキップ
  next if Spree::User.exists?(email: data[:email])

  user = Spree::User.create!(data)
  puts "Created customer: #{user.email} (#{user.status_badge}) - LTV: ¥#{user.lifetime_value.to_i}"
end

puts "\nCustomer summary:"
puts "Total customers: #{Spree::User.where.not(email: 'admin@example.com').count}"
puts "Bronze: #{Spree::User.bronze_customers.count}"
puts "Silver: #{Spree::User.silver_customers.count}"
puts "Gold: #{Spree::User.gold_customers.count}"
puts "Platinum: #{Spree::User.platinum_customers.count}"
puts "VIP customers: #{Spree::User.vip_customers.count}"
puts "Attention customers: #{Spree::User.attention_customers.count}"
puts "Newsletter subscribers: #{Spree::User.newsletter_subscribers.count}"
puts "Active customers (30 days): #{Spree::User.recent_purchasers(30).count}"
puts "Dormant customers (90+ days): #{Spree::User.inactive_customers(90).count}"
puts "High value customers (100k+): #{Spree::User.high_value_customers.count}"

total_ltv = Spree::User.where.not(email: 'admin@example.com').sum(:total_purchase_amount)
puts "\nTotal LTV: ¥#{total_ltv.to_i}"
