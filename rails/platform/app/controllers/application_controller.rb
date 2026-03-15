class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :set_sidebar_client

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  private

  def set_sidebar_client
    code = params[:client_code]
    code ||= params[:id] if controller_name == "clients" && params[:action].in?(%w[show edit update destroy])
    @sidebar_client = Client.find_by(code: code) if code.present?
  end
end
