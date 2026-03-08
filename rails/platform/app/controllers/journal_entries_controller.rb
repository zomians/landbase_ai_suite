class JournalEntriesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  before_action :require_client_code
  before_action :set_client

  def index
    @source_type = params[:source_type] || ""
    scope = JournalEntry.for_client(@client_code).includes(:journal_entry_lines)
    scope = scope.by_source(@source_type) if @source_type.present?
    @entries = scope.order(date: :desc, transaction_no: :asc).page(params[:page]).per(25)
  end

  def show
    @entry = JournalEntry.for_client(@client_code).includes(:journal_entry_lines).find(params[:id])
  end

  def edit
    @entry = JournalEntry.for_client(@client_code).includes(:journal_entry_lines).find(params[:id])
  end

  def update
    @entry = JournalEntry.for_client(@client_code).includes(:journal_entry_lines).find(params[:id])

    if @entry.update(entry_params)
      redirect_to journal_entry_path(@entry, client_code: @client_code), notice: "仕訳を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def require_client_code
    @client_code = params[:client_code]
    redirect_to clients_path, alert: "クライアントを選択してください" if @client_code.blank?
  end

  def set_client
    @client = Client.find_by!(code: @client_code)
  end

  def entry_params
    params.require(:journal_entry).permit(
      :description, :tag, :memo, :cardholder, :status,
      journal_entry_lines_attributes: [
        :id, :side, :account, :sub_account, :department,
        :partner, :tax_category, :invoice, :amount, :_destroy
      ]
    )
  end

  def record_not_found
    redirect_to clients_path, alert: "仕訳が見つかりません"
  end
end
