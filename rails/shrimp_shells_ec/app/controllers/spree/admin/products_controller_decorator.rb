# frozen_string_literal: true

module Spree
  module Admin
    module ProductsControllerDecorator
      def self.prepended(base)
        base.class_eval do
          # カスタムフィールドを許可パラメータに追加
          private

          def permitted_product_attributes
            super + [
              :shrimp_origin,
              :shrimp_size,
              :expiry_days,
              :best_before_months,
              :storage_temperature,
              :allergens,
              :nutritional_info,
              :cooking_instructions,
              :serving_suggestions,
              :net_weight,
              :gross_weight,
              :package_dimensions,
              :catch_method,
              :processing_date,
              :halal_certified,
              :organic_certified,
              :calories,
              :protein,
              :fat,
              :carbohydrate,
              :sodium
            ]
          end
        end
      end
    end
  end
end

if defined?(Spree::Admin::ProductsController)
  Spree::Admin::ProductsController.prepend(Spree::Admin::ProductsControllerDecorator)
end
