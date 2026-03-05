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

  def export
    entries = JournalEntry.for_client(@client_code)
    entries = entries.by_source(params[:source_type]) if params[:source_type].present?
    if params[:from].present? && params[:to].present?
      begin
        entries = entries.in_period(Date.parse(params[:from]), Date.parse(params[:to]))
      rescue Date::Error
        redirect_to journal_entries_path(client_code: @client_code), alert: "日付の形式が不正です" and return
      end
    end

    entries = entries.order(date: :asc, transaction_no: :asc)

    case params[:format_type]
    when "yayoi_single"
      csv_data = YayoiExportService.new.export_single_entry(entries)
      send_data csv_data,
                filename: "journal_entries_yayoi_single_#{Time.current.strftime('%Y%m%d%H%M%S')}.csv",
                type: "text/csv; charset=shift_jis"
    when "yayoi_transfer"
      csv_data = YayoiExportService.new.export_transfer_slip(entries)
      send_data csv_data,
                filename: "journal_entries_yayoi_transfer_#{Time.current.strftime('%Y%m%d%H%M%S')}.csv",
                type: "text/csv; charset=shift_jis"
    else
      csv = "\uFEFF" + entries.to_csv
      send_data csv, filename: "journal_entries_#{Time.current.strftime('%Y%m%d%H%M%S')}.csv",
                     type: "text/csv; charset=utf-8"
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
