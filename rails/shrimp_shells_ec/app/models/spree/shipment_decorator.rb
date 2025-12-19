# frozen_string_literal: true

module Spree
  module ShipmentDecorator
    def self.prepended(base)
      # 配送業者の定数
      base.const_set(:CARRIER_CODES, {
        yamato: "ヤマト運輸",
        sagawa: "佐川急便",
        japan_post: "日本郵便",
        seino: "西濃運輸"
      }.freeze)

      # 配送ステータスの定数（delivery_statusカラム用）
      base.const_set(:DELIVERY_STATUSES, {
        out_for_delivery: "配達中",
        delivered: "配達完了",
        failed: "配達失敗",
        returned: "返送"
      }.freeze)

      # バリデーション
      base.validates :carrier_code, inclusion: { in: base::CARRIER_CODES.keys.map(&:to_s), allow_blank: true }
      base.validates :delivery_status, inclusion: { in: base::DELIVERY_STATUSES.keys.map(&:to_s), allow_blank: true }
      base.validates :delivery_attempts, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
      base.validates :tracking_url, format: { with: /\Ahttps?:\/\/.+\z/i }, allow_blank: true
      base.validate :estimated_delivery_date_not_in_past, if: -> { estimated_delivery_date.present? }

      # コールバック
      base.after_update :notify_delivery_status_change, if: -> { saved_change_to_delivery_status? }
      base.before_save :set_delivered_at, if: -> { delivery_status_changed_to_delivered? }
      base.after_save :generate_tracking_url, if: -> { carrier_code.present? && tracking.present? && tracking_url.blank? }

      # スコープ
      base.scope :by_carrier, ->(code) { where(carrier_code: code.to_s) }
      base.scope :out_for_delivery, -> { where(delivery_status: 'out_for_delivery') }
      base.scope :delivered, -> { where(delivery_status: 'delivered') }
      base.scope :delivery_failed, -> { where(delivery_status: 'failed') }
      base.scope :delivery_today, -> { where(estimated_delivery_date: Date.today) }
      base.scope :delivery_overdue, -> { where('estimated_delivery_date < ? AND (delivery_status IS NULL OR delivery_status != ?)', Date.today, 'delivered') }
      base.scope :requires_redelivery, -> { where('delivery_attempts > 0 AND delivery_status != ?', 'delivered') }
    end

    def refresh_rates
      # 既存のratesをクリア
      shipping_rates.delete_all
      
      # 利用可能なshipping methodsを取得
      available_methods = Spree::ShippingMethod.where(available_to_users: true).select do |sm|
        # Zoneチェック
        zone_match = sm.zones.any? { |z| z.include?(order.ship_address) }
        next false unless zone_match
        
        # Categoryチェック
        cats_match = order.line_items.all? do |li|
          cat = li.product.shipping_category || Spree::ShippingCategory.first
          sm.shipping_categories.include?(cat)
        end
        
        zone_match && cats_match
      end
      
      # 各methodの配送率を作成
      available_methods.each do |sm|
        begin
          cost = sm.calculator.compute(self)
          shipping_rates.create!(
            shipping_method: sm,
            cost: cost
          )
        rescue => e
          Rails.logger.error "Failed to create shipping rate for #{sm.name}: #{e.message}"
        end
      end
      
      shipping_rates
    end

    # 配送業者名を取得
    def carrier_name
      return nil unless carrier_code
      self.class::CARRIER_CODES[carrier_code.to_sym] || carrier_code
    end

    # 配送ステータス名を取得
    def delivery_status_name
      return nil unless delivery_status
      self.class::DELIVERY_STATUSES[delivery_status.to_sym] || delivery_status
    end

    # 配達完了をマーク
    def mark_as_delivered!
      update!(
        delivery_status: 'delivered',
        delivered_at: Time.current
      )
    end

    # 配達失敗を記録
    def mark_as_failed!(reason: nil)
      update!(
        delivery_status: 'failed',
        delivery_attempts: (delivery_attempts || 0) + 1,
        delivery_notes: [delivery_notes, "配達失敗: #{reason}"].compact.join("\n")
      )
    end

    # 再配達準備
    def prepare_redelivery!
      update!(
        delivery_status: nil,
        delivery_notes: [delivery_notes, "再配達準備: #{Time.current}"].compact.join("\n")
      )
    end

    # 配達中にマーク
    def mark_out_for_delivery!
      update!(delivery_status: 'out_for_delivery')
    end

    # 追跡URLを生成
    def generate_tracking_url
      return unless tracking.present? && carrier_code.present?

      url = case carrier_code.to_sym
      when :yamato
        "https://toi.kuronekoyamato.co.jp/cgi-bin/tneko?number=#{tracking}"
      when :sagawa
        "https://k2k.sagawa-exp.co.jp/p/web/okurijosearch.do?okurijoNo=#{tracking}"
      when :japan_post
        "https://trackings.post.japanpost.jp/services/srv/search/?requestNo1=#{tracking}"
      when :seino
        "https://track.seino.co.jp/kamotsu/GempyoNoSearch.do?gempyoNo=#{tracking}"
      else
        nil
      end
      
      if url
        update_column(:tracking_url, url)
        self.tracking_url = url  # インスタンス変数も更新
      end
      
      url
    end

    # 配送予定日までの日数
    def days_until_delivery
      return nil unless estimated_delivery_date
      (estimated_delivery_date - Date.today).to_i
    end

    # 配送遅延かどうか
    def delivery_overdue?
      estimated_delivery_date.present? &&
        estimated_delivery_date < Date.today &&
        delivery_status != 'delivered'
    end

    # 配送ステータスのバッジ表示
    def status_badge
      # delivery_statusがある場合はそちらを優先
      if delivery_status.present?
        case delivery_status.to_sym
        when :out_for_delivery
          "🚛 配達中"
        when :delivered
          "✅ 配達完了"
        when :failed
          "❌ 配達失敗"
        when :returned
          "↩️ 返送"
        else
          "❓ #{delivery_status}"
        end
      else
        # Solidus標準のstateを表示
        case state.to_sym
        when :pending
          "⏳ 準備中"
        when :ready
          "📦 出荷可能"
        when :shipped
          "🚚 配送中"
        when :canceled
          "🚫 キャンセル"
        else
          "❓ #{state}"
        end
      end
    end

    # 配送情報のサマリー
    def shipping_summary
      summary = []
      summary << "配送業者: #{carrier_name}" if carrier_name
      summary << "追跡番号: #{tracking}" if tracking
      summary << "配送予定: #{estimated_delivery_date&.strftime('%Y/%m/%d')}" if estimated_delivery_date
      summary << "配達完了: #{delivered_at&.strftime('%Y/%m/%d %H:%M')}" if delivered_at
      summary << "再配達: #{delivery_attempts}回" if delivery_attempts && delivery_attempts > 0
      summary.join(" | ")
    end

    private

    def estimated_delivery_date_not_in_past
      return unless estimated_delivery_date && estimated_delivery_date < Date.today
      return if delivery_status == 'delivered'
      
      errors.add(:estimated_delivery_date, "は過去の日付にできません")
    end

    def delivery_status_changed_to_delivered?
      delivery_status_changed? && delivery_status == 'delivered'
    end

    def notify_delivery_status_change
      # 将来的にMattermost通知やメール送信を実装
      Rails.logger.info "配送ステータス変更: Shipment ##{number} - #{delivery_status}"
    end

    def set_delivered_at
      self.delivered_at = Time.current if delivered_at.nil?
    end
  end
end

Spree::Shipment.prepend(Spree::ShipmentDecorator)
