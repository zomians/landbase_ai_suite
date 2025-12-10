# frozen_string_literal: true

module Spree
  class Calculator::Shipping::FlatRate
    def compute_shipment(shipment)
      preferred_amount
    end

    def compute_package(_package)
      preferred_amount
    end
  end
end
