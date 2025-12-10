# frozen_string_literal: true

Rails.application.config.to_prepare do
  CheckoutsController.class_eval do
    private

    def update_params
      case params[:state].to_sym
      when :address
        massaged_params.require(:order).permit(
          permitted_checkout_address_attributes
        )
      when :delivery
        # deliveryステートではorderパラメータがない場合がある
        if massaged_params[:order].present?
          massaged_params.require(:order).permit(
            permitted_checkout_delivery_attributes
          )
        else
          ActionController::Parameters.new({})
        end
      when :payment
        if @order.covered_by_store_credit? || massaged_params[:order].blank?
          massaged_params.fetch(:order, {})
        else
          massaged_params.require(:order)
        end.permit(
          permitted_checkout_payment_attributes
        )
      else
        massaged_params.fetch(:order, {}).permit(
          permitted_checkout_confirm_attributes
        )
      end
    end
  end
end
