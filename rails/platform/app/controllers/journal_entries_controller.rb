class JournalEntriesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  before_action :require_client_code
  before_action :set_client

  def index
    @source_type = params[:source_type] || ""
    scope = JournalEntry.for_client(@client_code)
    scope = scope.by_source(@source_type) if @source_type.present?
    @entries = scope.order(date: :desc, transaction_no: :asc).page(params[:page]).per(25)
  end

  def show
    @entry = JournalEntry.for_client(@client_code).find(params[:id])
  end

  def edit
    @entry = JournalEntry.for_client(@client_code).find(params[:id])
  end

  def update
    @entry = JournalEntry.for_client(@client_code).find(params[:id])

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
      :debit_account, :debit_sub_account, :debit_department, :debit_partner,
      :debit_tax_category, :debit_invoice, :debit_amount,
      :credit_account, :credit_sub_account, :credit_department, :credit_partner,
      :credit_tax_category, :credit_invoice, :credit_amount,
      :description, :tag, :memo, :cardholder, :status
    )
  end

  def record_not_found
    redirect_to clients_path, alert: "仕訳が見つかりません"
  end
end
