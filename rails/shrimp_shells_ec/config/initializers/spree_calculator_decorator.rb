# frozen_string_literal: true

Rails.application.config.to_prepare do
  Spree::Calculator::Shipping::FlatRate.class_eval do
    def compute_shipment(shipment)
      preferred_amount
    end

    def compute_package(_package)
      preferred_amount
    end
  end
end
