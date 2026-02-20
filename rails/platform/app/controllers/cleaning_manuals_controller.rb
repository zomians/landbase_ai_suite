class CleaningManualsController < ApplicationController
  def index
    @client_code = params[:client_code] || ""
    @manuals = if @client_code.present?
                 CleaningManual.for_client(@client_code).recent
               else
                 CleaningManual.none
               end
  end

  def show
    @manual = CleaningManual.find(params[:id])
  end

  def new
  end
end
