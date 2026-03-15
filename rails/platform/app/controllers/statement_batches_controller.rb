class StatementBatchesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def show
    @batch = StatementBatch.find(params[:id])
    @client = @batch.client || raise(ActiveRecord::RecordNotFound)
    @sidebar_client = @client
  end

  private

  def record_not_found
    redirect_to clients_path, alert: "処理バッチが見つかりません"
  end
end
