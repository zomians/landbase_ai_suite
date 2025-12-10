# frozen_string_literal: true

Rails.application.config.to_prepare do
  Spree::Order.class_eval do
    # 配送率のバリデーションをスキップ
    def ensure_available_shipping_rates
      # 何もしない - delivery画面で手動処理
      true
    end
  end
end
