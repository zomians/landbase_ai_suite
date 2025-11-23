# frozen_string_literal: true

# ガーリックシュリンプ冷凍食品のサンプルデータ

puts "Creating Shrimp Shells products..."

# デフォルトストアとシッピングカテゴリを取得
store = Spree::Store.first
shipping_category = Spree::ShippingCategory.first || Spree::ShippingCategory.create!(name: "冷凍食品")
tax_category = Spree::TaxCategory.first || Spree::TaxCategory.create!(name: "標準税率")

# 商品データ
products_data = [
  {
    name: "ガーリックシュリンプ（Lサイズ）プレミアム",
    description: "厳選されたインドネシア産の大型エビを使用した、本格ハワイアンスタイルのガーリックシュリンプです。にんにくの風味が効いた特製ソースが絶品です。",
    price: 1980,
    shrimp_origin: "インドネシア",
    shrimp_size: "L",
    catch_method: "養殖",
    net_weight: 300,
    gross_weight: 350,
    storage_temperature: -18.0,
    expiry_days: 365,
    best_before_months: 12,
    allergens: "甲殻類、大豆、小麦",
    package_dimensions: "25cm x 18cm x 5cm",
    halal_certified: false,
    organic_certified: false,
    nutritional_info: {
      calories: 245,
      protein: 28.5,
      fat: 12.3,
      carbohydrates: 5.2,
      sodium: 850,
      serving_size: "100g"
    },
    cooking_instructions: <<~TEXT,
      【解凍方法】
      冷蔵庫で約6時間ゆっくり解凍してください。
      
      【調理方法】
      1. フライパンにオリーブオイルを熱します
      2. 解凍したガーリックシュリンプを入れて中火で3-4分炒めます
      3. 両面がこんがりと焼けたら完成です
      
      ※電子レンジでの解凍も可能です（500W で 3-4分）
    TEXT
    serving_suggestions: <<~TEXT,
      ・白いご飯の上に盛り付けてガーリックシュリンプ丼に
      ・レタスやトマトと一緒にサラダボウルに
      ・バゲットと一緒にワインのおつまみに
      ・パスタに絡めてシーフードパスタに
    TEXT
  },
  {
    name: "ガーリックシュリンプ（Mサイズ）スタンダード",
    description: "ベトナム産の中型エビを使用した、お手頃価格のガーリックシュリンプです。日常使いに最適なサイズと価格帯です。",
    price: 1280,
    shrimp_origin: "ベトナム",
    shrimp_size: "M",
    catch_method: "養殖",
    net_weight: 250,
    gross_weight: 290,
    storage_temperature: -18.0,
    expiry_days: 365,
    best_before_months: 12,
    allergens: "甲殻類、大豆、小麦",
    package_dimensions: "22cm x 16cm x 4cm",
    halal_certified: false,
    organic_certified: false,
    nutritional_info: {
      calories: 238,
      protein: 27.2,
      fat: 11.8,
      carbohydrates: 5.0,
      sodium: 820,
      serving_size: "100g"
    },
    cooking_instructions: <<~TEXT,
      【解凍方法】
      冷蔵庫で約5時間ゆっくり解凍してください。
      
      【調理方法】
      1. フライパンにオリーブオイルを熱します
      2. 解凍したガーリックシュリンプを入れて中火で3分炒めます
      3. 両面がこんがりと焼けたら完成です
    TEXT
    serving_suggestions: "白いご飯やパスタと一緒にお召し上がりください。サラダのトッピングにも最適です。"
  },
  {
    name: "ガーリックシュリンプ（XLサイズ）ハラール認証",
    description: "タイ産の特大エビを使用した、ハラール認証取得のプレミアムガーリックシュリンプです。厳格な基準のもとで加工されています。",
    price: 2480,
    shrimp_origin: "タイ",
    shrimp_size: "XL",
    catch_method: "養殖",
    net_weight: 350,
    gross_weight: 400,
    storage_temperature: -18.0,
    expiry_days: 365,
    best_before_months: 12,
    allergens: "甲殻類、大豆",
    package_dimensions: "28cm x 20cm x 6cm",
    halal_certified: true,
    organic_certified: false,
    nutritional_info: {
      calories: 252,
      protein: 29.8,
      fat: 13.1,
      carbohydrates: 4.8,
      sodium: 780,
      serving_size: "100g"
    },
    cooking_instructions: <<~TEXT,
      【解凍方法】
      冷蔵庫で約7時間ゆっくり解凍してください。
      
      【調理方法】
      1. フライパンにオリーブオイルまたはギー（澄ましバター）を熱します
      2. 解凍したガーリックシュリンプを入れて中火で4-5分炒めます
      3. 両面がこんがりと焼けたら完成です
      
      ※ハラール認証取得商品です
    TEXT
    serving_suggestions: <<~TEXT,
      ・バスマティライスと一緒に本格的な中東風に
      ・ナンやチャパティと一緒に
      ・野菜と一緒にケバブ風に
    TEXT
  },
  {
    name: "オーガニック・ガーリックシュリンプ（Lサイズ）",
    description: "オーガニック認証を取得したエクアドル産の天然エビを使用。化学調味料不使用、自然な味わいが特徴です。",
    price: 2980,
    shrimp_origin: "エクアドル",
    shrimp_size: "L",
    catch_method: "天然",
    net_weight: 280,
    gross_weight: 320,
    storage_temperature: -18.0,
    expiry_days: 365,
    best_before_months: 12,
    allergens: "甲殻類",
    package_dimensions: "24cm x 18cm x 5cm",
    halal_certified: false,
    organic_certified: true,
    nutritional_info: {
      calories: 228,
      protein: 30.2,
      fat: 10.5,
      carbohydrates: 3.2,
      sodium: 620,
      serving_size: "100g"
    },
    cooking_instructions: <<~TEXT,
      【解凍方法】
      冷蔵庫で約6時間ゆっくり解凍してください。
      
      【調理方法】
      1. フライパンにオーガニックオリーブオイルを熱します
      2. 解凍したガーリックシュリンプを入れて中火で3-4分炒めます
      3. 両面がこんがりと焼けたら完成です
      
      ※化学調味料不使用、オーガニック認証取得商品です
    TEXT
    serving_suggestions: "オーガニック野菜のサラダと一緒に、健康志向の方におすすめです。玄米ご飯との相性も抜群です。"
  }
]

products_data.each do |data|
  # 商品作成（価格を含む）
  product = Spree::Product.create!(
    name: data[:name],
    description: data[:description],
    price: data[:price],
    available_on: Time.current,
    shipping_category: shipping_category,
    tax_category: tax_category,
    shrimp_origin: data[:shrimp_origin],
    shrimp_size: data[:shrimp_size],
    catch_method: data[:catch_method],
    net_weight: data[:net_weight],
    gross_weight: data[:gross_weight],
    storage_temperature: data[:storage_temperature],
    expiry_days: data[:expiry_days],
    best_before_months: data[:best_before_months],
    allergens: data[:allergens],
    package_dimensions: data[:package_dimensions],
    halal_certified: data[:halal_certified],
    organic_certified: data[:organic_certified],
    nutritional_info: data[:nutritional_info],
    cooking_instructions: data[:cooking_instructions],
    serving_suggestions: data[:serving_suggestions],
    processing_date: 1.month.ago
  )

  # マスターバリアント（在庫管理用）
  product.master.update!(
    sku: "SHRIMP-#{data[:shrimp_size]}-#{SecureRandom.hex(4).upcase}",
    cost_price: (data[:price] * 0.6).round,
    weight: data[:net_weight] / 1000.0, # kgに変換
    height: 5,
    width: 18,
    depth: 25
  )

  # 在庫設定
  stock_location = Spree::StockLocation.first
  if stock_location
    stock_item = product.master.stock_items.find_by(stock_location: stock_location)
    stock_item.set_count_on_hand(100) if stock_item
  end

  puts "Created product: #{product.name}"
end

puts "Successfully created #{products_data.size} Shrimp Shells products!"
