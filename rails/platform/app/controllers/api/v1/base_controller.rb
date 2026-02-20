module Api
  module V1
    class BaseController < ActionController::API
      before_action :set_client_code

      private

      def set_client_code
        @client_code = params[:client_code]
        render_error("client_code は必須です", :bad_request) if @client_code.blank?
      end

      def render_error(message, status = :unprocessable_entity)
        render json: { error: message }, status: status
      end

      def render_not_found
        render json: { error: "リソースが見つかりません" }, status: :not_found
      end
    end
  end
end
