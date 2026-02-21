class CleaningManualsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def index
    @client_code = params[:client_code] || ""
    @manuals = if @client_code.present?
                 CleaningManual.for_client(@client_code).recent
               else
                 CleaningManual.none
               end
  end

  def show
    @client_code = params[:client_code]
    @manual = CleaningManual.for_client(@client_code).find(params[:id])
  end

  def new
  end

  private

  def record_not_found
    redirect_to cleaning_manuals_path, alert: "マニュアルが見つかりません"
  end
end
