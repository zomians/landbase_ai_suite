module Api
  module V1
    class BaseController < ActionController::API
      before_action :set_current_client

      private

      def set_current_client
        client_code = params[:client_code]
        return render_error("client_code は必須です", :bad_request) if client_code.blank?

        @current_client = Client.find_by(code: client_code)
        return render_error("クライアントが見つかりません", :not_found) unless @current_client
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
