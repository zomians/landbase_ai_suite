# frozen_string_literal: true

module Spree
  module ShipmentDecorator
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
  end
end

Spree::Shipment.prepend(Spree::ShipmentDecorator)
