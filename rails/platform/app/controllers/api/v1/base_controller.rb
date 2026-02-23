module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_token!
      before_action :set_current_client

      private

      def authenticate_api_token!
        token = extract_bearer_token
        api_token = ApiToken.find_by_raw_token(token)

        if api_token.nil? || !api_token.active?
          render json: { error: "Unauthorized" }, status: :unauthorized
          return
        end

        api_token.touch_last_used!
      end

      def extract_bearer_token
        header = request.headers["Authorization"]
        header&.match(/\ABearer\s+(.+)\z/)&.captures&.first
      end

      def set_current_client
        client_code = params[:client_code]
        return render_error("client_code は必須です", :bad_request) if client_code.blank?

        @current_client = Client.find_by(code: client_code)
        render_error("クライアントが見つかりません", :not_found) unless @current_client
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
