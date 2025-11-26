# frozen_string_literal: true

module Spree
  module OrderDecorator
    def self.prepended(base)
      # 配送時間帯の定数
      base.const_set(:DELIVERY_TIME_SLOTS, [
        '午前中(8-12時)',
        '12-14時',
        '14-16時',
        '16-18時',
        '18-20時',
        '19-21時'
      ].freeze)

      # 配送業者コードの定数
      base.const_set(:CARRIER_CODES, {
        yamato: 'ヤマト運輸',
        sagawa: '佐川急便',
        japan_post: '日本郵便',
        seino: '西濃運輸'
      }.freeze)

      # バリデーション
      base.validates :preferred_delivery_time, inclusion: { in: base::DELIVERY_TIME_SLOTS, allow_blank: true }
      base.validates :redelivery_count, numericality: { greater_than_or_equal_to: 0 }
      base.validates :ice_pack_count, numericality: { greater_than_or_equal_to: 0 }
      base.validates :packing_temperature, numericality: { less_than_or_equal_to: 0, allow_blank: true }, 
                if: -> { packing_temperature.present? }

      # コールバック
      base.before_save :calculate_ice_pack_count, if: -> { state == 'complete' && ice_pack_count.zero? }
      base.after_update :alert_temperature_issue, if: -> { saved_change_to_temperature_alert? && temperature_alert? }

      # スコープ
      base.scope :delivery_scheduled, -> { where.not(preferred_delivery_date: nil) }
      base.scope :delivery_today, -> { where(preferred_delivery_date: Date.today) }
      base.scope :delivery_tomorrow, -> { where(preferred_delivery_date: Date.tomorrow) }
      base.scope :requires_shipping, -> { where(state: 'complete').where(picking_completed_at: nil) }
      base.scope :picking_completed, -> { where.not(picking_completed_at: nil) }
      base.scope :temperature_alerts, -> { where(temperature_alert: true) }
      base.scope :by_carrier, ->(code) { where(carrier_code: code.to_s) }
      base.scope :redelivery_orders, -> { where('redelivery_count > 0') }
      base.scope :by_scheduled_ship_date, ->(date) { where(scheduled_ship_date: date) }
    end

    # 出荷準備が完了しているか
    def ready_to_ship?
      state == 'complete' && 
        picking_completed_at.present? && 
        scheduled_ship_date.present? &&
        !temperature_alert?
    end

    # ピッキング完了をマーク
    def mark_picking_completed!(inspector)
      update!(
        picking_completed_at: Time.current,
        inspector_name: inspector
      )
    end

    # 温度異常を記録
    def record_temperature!(temp)
      update!(
        packing_temperature: temp,
        temperature_recorded_at: Time.current,
        temperature_alert: temp > -15.0 # -15℃以上で警告
      )
    end

    # 配送業者名を取得
    def carrier_name
      self.class::CARRIER_CODES[carrier_code&.to_sym] || carrier_code
    end

    # 配送希望日までの日数
    def days_until_delivery
      return nil unless preferred_delivery_date
      (preferred_delivery_date - Date.today).to_i
    end

    # 配送ステータスのバッジ
    def delivery_status_badge
      return '⏳ 配送待ち' if completed? && !picking_completed_at
      return '📦 ピッキング完了' if picking_completed_at && !shipped?
      return '🚚 出荷済み' if shipped?
      return '✅ 配送完了' if delivered?
      '📝 受注中'
    end

    # 冷凍品の総重量を計算（保冷剤数量の目安）
    def total_frozen_weight
      line_items.joins(:variant).sum('spree_variants.weight')
    end

    # 必要な保冷剤数を計算
    def calculate_required_ice_packs
      weight = total_frozen_weight
      return 0 if weight.zero?
      
      # 1kgあたり1個、最低2個
      [(weight / 1000.0).ceil, 2].max
    end

    # 配送可能日をチェック
    def delivery_date_valid?
      return true unless preferred_delivery_date
      preferred_delivery_date >= Date.today + 2.days # 最低2日後から配送可能
    end

    # 再配達をインクリメント
    def increment_redelivery!
      increment!(:redelivery_count)
    end

    # 追跡URLを生成
    def tracking_url
      return nil unless tracking_number && carrier_code
      
      case carrier_code.to_sym
      when :yamato
        "https://toi.kuronekoyamato.co.jp/cgi-bin/tneko?number=#{tracking_number}"
      when :sagawa
        "https://k2k.sagawa-exp.co.jp/p/sagawa/web/okurijoinput.jsp?okurijoNo=#{tracking_number}"
      when :japan_post
        "https://trackings.post.japanpost.jp/services/srv/search/direct?locale=ja&reqCodeNo1=#{tracking_number}"
      else
        nil
      end
    end

    private

    def calculate_ice_pack_count
      self.ice_pack_count = calculate_required_ice_packs if ice_pack_count.zero?
    end

    def alert_temperature_issue
      # ここで管理者への通知処理を実装
      Rails.logger.warn("Temperature alert for Order ##{number}: #{packing_temperature}℃")
    end
  end
end

Spree::Order.prepend(Spree::OrderDecorator)
