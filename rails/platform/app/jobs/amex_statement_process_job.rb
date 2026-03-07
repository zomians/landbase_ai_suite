class AmexStatementProcessJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: 2

  discard_on ActiveRecord::RecordNotFound

  after_discard do |job, exception|
    batch_id = job.arguments.first
    batch = StatementBatch.find_by(id: batch_id)
    batch&.update(status: "failed", error_message: "ジョブ実行エラー: #{exception.message}")
  end

  def perform(statement_batch_id)
    batch = StatementBatch.find(statement_batch_id)
    return unless batch.status == "processing"

    service = AmexStatementProcessorService.new(
      pdf: batch.pdf,
      client_code: batch.client.code
    )
    result = service.call

    if result.success?
      ActiveRecord::Base.transaction do
        create_journal_entries(batch, result.data)
        batch.update!(
          status: "completed",
          summary: result.data[:summary] || {},
          error_message: nil
        )
      end
    else
      batch.update!(status: "failed", error_message: result.error)
    end
  end

  private

  def create_journal_entries(batch, data)
    transactions = data[:transactions] || []
    transactions.each do |txn|
      entry = batch.journal_entries.create!(
        client: batch.client,
        source_type: batch.source_type,
        source_period: data[:statement_period],
        transaction_no: txn[:transaction_no],
        date: txn[:date],
        description: txn[:description] || "",
        tag: txn[:tag] || "amex",
        memo: txn[:memo] || "",
        cardholder: txn[:cardholder] || "",
        status: txn[:status] || "ok",
        journal_entry_lines_attributes: [
          {
            side: "debit",
            account: txn[:debit_account],
            sub_account: txn[:debit_sub_account] || "",
            department: txn[:debit_department] || "",
            partner: txn[:debit_partner] || "",
            tax_category: txn[:debit_tax_category] || "",
            invoice: txn[:debit_invoice] || "",
            amount: txn[:debit_amount]
          },
          {
            side: "credit",
            account: txn[:credit_account],
            sub_account: txn[:credit_sub_account] || "",
            department: txn[:credit_department] || "",
            partner: txn[:credit_partner] || "",
            tax_category: txn[:credit_tax_category] || "",
            invoice: txn[:credit_invoice] || "",
            amount: txn[:credit_amount]
          }
        ]
      )
    end
  end
end
