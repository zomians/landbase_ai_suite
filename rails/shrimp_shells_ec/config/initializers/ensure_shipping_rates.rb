# frozen_string_literal: true

# Confirmステートに進む前に配送率が選択されていることを確認
Rails.application.config.to_prepare do
  CheckoutsController.class_eval do
    before_action :ensure_shipping_rate_selected, only: [:edit, :update]
    
    private
    
    def ensure_shipping_rate_selected
      return unless @order
      return unless @order.state.in?(%w[confirm complete])
      
      @order.shipments.each do |shipment|
        # 配送率がなければ作成
        if shipment.shipping_rates.empty?
          shipment.refresh_rates
        end
        
        # 選択されていなければ最初の配送率を選択
        unless shipment.shipping_rates.any?(&:selected)
          rate = shipment.shipping_rates.first
          if rate
            rate.update(selected: true)
            shipment.update(cost: rate.cost)
          end
        end
      end
      
      @order.recalculate if @order.shipments.any? { |s| s.previous_changes.key?(:cost) }
    end
  end
end
