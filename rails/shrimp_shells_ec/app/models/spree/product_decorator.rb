# frozen_string_literal: true

module Spree
  # ガーリックシュリンプ冷凍食品用の商品カスタムフィールドとバリデーション
  module ProductDecorator
    # エビのサイズ定数
    SHRIMP_SIZES = %w[XL L M S].freeze
    
    # 漁獲方法定数
    CATCH_METHODS = %w[養殖 天然 混合].freeze
    
    # バリデーションとスコープの設定
    def self.prepended(base)
      base.validates :shrimp_size, inclusion: { in: SHRIMP_SIZES, allow_blank: true }
      base.validates :catch_method, inclusion: { in: CATCH_METHODS, allow_blank: true }
      base.validates :storage_temperature, numericality: { less_than_or_equal_to: 0, allow_blank: true }, 
                     if: :frozen_product?
      base.validates :net_weight, :gross_weight, numericality: { greater_than: 0, allow_blank: true }
      base.validates :expiry_days, :best_before_months, numericality: { greater_than: 0, allow_blank: true }
      
      # スコープの追加
      base.scope :by_shrimp_origin, ->(origin) { where(shrimp_origin: origin) }
      base.scope :by_shrimp_size, ->(size) { where(shrimp_size: size) }
      base.scope :halal_certified, -> { where(halal_certified: true) }
      base.scope :organic_certified, -> { where(organic_certified: true) }
      base.scope :with_certifications, -> { where('halal_certified = ? OR organic_certified = ?', true, true) }
    end
    
    # 冷凍商品かどうかを判定
    def frozen_product?
      storage_temperature.present? && storage_temperature < 0
    end
    
    # 賞味期限を計算（製造日/加工日から）
    def calculate_best_before_date(from_date = processing_date || Date.current)
      return nil unless best_before_months.present?
      from_date + best_before_months.months
    end
    
    # 栄養成分情報を取得
    def calories
      nutritional_info&.dig('calories')
    end
    
    def protein
      nutritional_info&.dig('protein')
    end
    
    def fat
      nutritional_info&.dig('fat')
    end
    
    def carbohydrates
      nutritional_info&.dig('carbohydrates')
    end
    
    def sodium
      nutritional_info&.dig('sodium')
    end
    
    # アレルゲン一覧を配列で取得
    def allergen_list
      return [] if allergens.blank?
      allergens.split(',').map(&:strip)
    end
    
    # 認証バッジの表示用
    def certification_badges
      badges = []
      badges << 'ハラール認証' if halal_certified?
      badges << 'オーガニック認証' if organic_certified?
      badges
    end
    
    # パッケージ寸法を構造化して取得
    def parsed_package_dimensions
      return {} if package_dimensions.blank?
      
      # "20cm x 15cm x 5cm" のような形式を想定
      dimensions = package_dimensions.scan(/[\d.]+/)
      return {} if dimensions.size < 3
      
      {
        length: dimensions[0].to_f,
        width: dimensions[1].to_f,
        height: dimensions[2].to_f,
        unit: 'cm'
      }
    end
    
    # 商品の詳細情報を表示用にフォーマット
    def formatted_product_info
      {
        origin: shrimp_origin,
        size: shrimp_size,
        catch_method: catch_method,
        net_weight: "#{net_weight}g",
        storage_temp: "#{storage_temperature}℃",
        certifications: certification_badges
      }.compact
    end
    
    # 類似商品を取得（同じカテゴリーまたは産地の商品）
    def similar_products(limit = 4)
      similar = Spree::Product.available
        .where.not(id: id)
        .limit(limit)
      
      # 同じ産地の商品を優先
      if shrimp_origin.present?
        similar = similar.by_shrimp_origin(shrimp_origin)
      end
      
      # 同じサイズの商品を優先
      if similar.count < limit && shrimp_size.present?
        additional = Spree::Product.available
          .where.not(id: id)
          .by_shrimp_size(shrimp_size)
          .limit(limit - similar.count)
        similar = similar.or(additional)
      end
      
      # それでも足りなければ他の商品を追加
      if similar.count < limit
        similar = Spree::Product.available
          .where.not(id: id)
          .limit(limit)
      end
      
      similar
    end
  end
end

Spree::Product.prepend(Spree::ProductDecorator)
