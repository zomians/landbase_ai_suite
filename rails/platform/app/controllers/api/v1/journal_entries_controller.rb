module Api
  module V1
    class JournalEntriesController < BaseController
      def index
        entries = @current_client.journal_entries

        entries = entries.by_source(params[:source_type]) if params[:source_type].present?
        entries = entries.review_required if params[:review_required] == "true"
        if params[:date_from].present? && params[:date_to].present?
          entries = entries.in_period(Date.parse(params[:date_from]), Date.parse(params[:date_to]))
        end
        if params[:statement_batch_id].present?
          entries = entries.where(statement_batch_id: params[:statement_batch_id])
        end

        entries = entries.order(date: :desc, transaction_no: :asc)

        render json: entries.map { |e| entry_json(e) }
      end

      def show
        entry = @current_client.journal_entries.find_by(id: params[:id])
        return render_not_found unless entry

        render json: entry_json(entry)
      end

      def update
        entry = @current_client.journal_entries.find_by(id: params[:id])
        return render_not_found unless entry

        if entry.update(entry_params)
          render json: entry_json(entry)
        else
          render_error(entry.errors.full_messages.join(", "))
        end
      end

      def export
        entries = @current_client.journal_entries

        entries = entries.by_source(params[:source_type]) if params[:source_type].present?
        if params[:statement_batch_id].present?
          entries = entries.where(statement_batch_id: params[:statement_batch_id])
        end

        csv = entries.order(date: :asc, transaction_no: :asc).to_csv

        send_data csv, filename: "journal_entries_#{Time.current.strftime('%Y%m%d%H%M%S')}.csv",
                       type: "text/csv; charset=utf-8"
      end

      private

      def entry_params
        params.permit(
          :debit_account, :debit_sub_account, :debit_department, :debit_partner,
          :debit_tax_category, :debit_invoice, :debit_amount,
          :credit_account, :credit_sub_account, :credit_department, :credit_partner,
          :credit_tax_category, :credit_invoice, :credit_amount,
          :description, :tag, :memo, :cardholder, :status
        )
      end

      def entry_json(entry)
        {
          id: entry.id,
          transaction_no: entry.transaction_no,
          date: entry.date,
          debit_account: entry.debit_account,
          debit_sub_account: entry.debit_sub_account,
          debit_department: entry.debit_department,
          debit_partner: entry.debit_partner,
          debit_tax_category: entry.debit_tax_category,
          debit_invoice: entry.debit_invoice,
          debit_amount: entry.debit_amount,
          credit_account: entry.credit_account,
          credit_sub_account: entry.credit_sub_account,
          credit_department: entry.credit_department,
          credit_partner: entry.credit_partner,
          credit_tax_category: entry.credit_tax_category,
          credit_invoice: entry.credit_invoice,
          credit_amount: entry.credit_amount,
          description: entry.description,
          tag: entry.tag,
          memo: entry.memo,
          cardholder: entry.cardholder,
          status: entry.status,
          source_type: entry.source_type,
          source_period: entry.source_period,
          statement_batch_id: entry.statement_batch_id,
          created_at: entry.created_at,
          updated_at: entry.updated_at
        }
      end
    end
  end
end
