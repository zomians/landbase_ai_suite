class ClientsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def index
    @clients = Client.visible.search(params[:query]).order(:code)
  end

  def show
    @client = Client.find_by!(code: params[:id])
  end

  private

  def record_not_found
    redirect_to clients_path, alert: "クライアントが見つかりません"
  end
end
