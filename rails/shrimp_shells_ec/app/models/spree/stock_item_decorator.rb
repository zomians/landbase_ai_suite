# frozen_string_literal: true

module Spree
  # ガーリックシュリンプ冷凍食品用の在庫カスタムフィールドとバリデーション
  module StockItemDecorator
    # 品質ステータス定数
    QUALITY_STATUSES = %w[good warning discard].freeze
    
    # バリデーションとスコープの設定
    def self.prepended(base)
      base.validates :quality_status, inclusion: { in: QUALITY_STATUSES, allow_blank: true }
      base.validates :storage_temperature_actual, 
                     numericality: { less_than_or_equal_to: 0 }, 
                     allow_blank: true,
                     if: :frozen_product?
      base.validates :purchase_price, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
      base.validates :expiry_date, presence: true, if: :requires_expiry_date?
      
      # 賞味期限チェック
      base.validate :expiry_date_must_be_future, if: :new_record?
      
      # コールバック
      base.before_save :calculate_priority_order
      base.after_create :check_temperature_alert
      
      # スコープの追加
      base.scope :by_lot_number, ->(lot_number) { where(lot_number: lot_number) }
      base.scope :expiring_soon, ->(days = 30) { where('expiry_date <= ?', Date.current + days.days).where('expiry_date > ?', Date.current) }
      base.scope :expired, -> { where('expiry_date < ?', Date.current) }
      base.scope :good_quality, -> { where(quality_status: 'good') }
      base.scope :warning_quality, -> { where(quality_status: 'warning') }
      base.scope :by_priority, -> { order(priority_order: :asc, expiry_date: :asc) }
      base.scope :requires_inspection, -> { where('inspection_date IS NULL OR inspection_date < ?', 30.days.ago) }
      
      # インスタンスメソッドとして expiring_soon? を定義
      base.define_method(:expiring_soon?) do
        return false unless expiry_date.present?
        days_left = (expiry_date - Date.current).to_i
        days_left >= 0 && days_left <= 30
      end
    end
    
    # 冷凍商品かどうかを判定
    def frozen_product?
      variant&.product&.storage_temperature.present? && 
      variant.product.storage_temperature < 0
    end
    
    # 賞味期限が必要かどうか
    def requires_expiry_date?
      frozen_product?
    end
    
    # 賞味期限切れチェック
    def expired?
      expiry_date.present? && expiry_date < Date.current
    end
    
    # エイリアス（ビューで使用）
    alias_method :is_expired?, :expired?
    
    # 賞味期限まで残り日数
    def days_until_expiry
      return nil unless expiry_date.present?
      (expiry_date - Date.current).to_i
    end
    
    # 賞味期限アラート
    def expiry_alert_level
      return nil unless days_until_expiry
      
      case days_until_expiry
      when ..0
        :expired
      when 1..7
        :critical
      when 8..30
        :warning
      else
        :safe
      end
    end
    
    # 温度異常チェック
    def temperature_alert?
      return false unless storage_temperature_actual.present?
      return false unless frozen_product?
      
      # 推奨温度より高い場合は警告
      storage_temperature_actual > variant.product.storage_temperature
    end
    
    # 利益率計算
    def profit_margin
      return nil unless purchase_price.present? && variant.price.present?
      return nil if purchase_price.zero?
      
      ((variant.price - purchase_price) / purchase_price * 100).round(2)
    end
    
    # 粗利益
    def gross_profit
      return nil unless purchase_price.present? && variant.price.present?
      
      (variant.price - purchase_price).round(2)
    end
    
    # 在庫金額（原価ベース）
    def inventory_value
      return 0 unless purchase_price.present?
      
      (count_on_hand * purchase_price).round(2)
    end
    
    # 品質ステータスのバッジ表示用
    def quality_badge
      case quality_status
      when 'good'
        '✅ 良好'
      when 'warning'
        '⚠️ 要確認'
      when 'discard'
        '❌ 廃棄対象'
      else
        '－'
      end
    end
    
    private
    
    # 出荷優先順位を自動計算（賞味期限が近い順）
    def calculate_priority_order
      return unless expiry_date.present?
      
      self.priority_order = days_until_expiry
    end
    
    # 賞味期限は未来日でなければならない
    def expiry_date_must_be_future
      return unless expiry_date.present?
      
      if expiry_date <= Date.current
        errors.add(:expiry_date, 'は未来の日付である必要があります')
      end
    end
    
    # 温度アラートチェック
    def check_temperature_alert
      return unless temperature_alert?
      
      # ここで通知処理などを実装可能
      Rails.logger.warn("Temperature alert for StockItem #{id}: #{storage_temperature_actual}℃")
    end
  end
  
  StockItem.prepend(StockItemDecorator)
end
