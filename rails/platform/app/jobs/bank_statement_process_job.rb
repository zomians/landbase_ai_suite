class BankStatementProcessJob < ApplicationJob
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

    service = BankStatementProcessorService.new(
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
      batch.journal_entries.create!(
        client: batch.client,
        source_type: batch.source_type,
        source_period: data[:statement_period],
        transaction_no: txn[:transaction_no],
        date: txn[:date],
        debit_account: txn[:debit_account],
        debit_sub_account: txn[:debit_sub_account] || "",
        debit_department: txn[:debit_department] || "",
        debit_partner: txn[:debit_partner] || "",
        debit_tax_category: txn[:debit_tax_category] || "",
        debit_invoice: txn[:debit_invoice] || "",
        debit_amount: txn[:debit_amount],
        credit_account: txn[:credit_account],
        credit_sub_account: txn[:credit_sub_account] || "",
        credit_department: txn[:credit_department] || "",
        credit_partner: txn[:credit_partner] || "",
        credit_tax_category: txn[:credit_tax_category] || "",
        credit_invoice: txn[:credit_invoice] || "",
        credit_amount: txn[:credit_amount],
        description: txn[:description] || "",
        tag: txn[:tag] || "bank",
        memo: txn[:memo] || "",
        cardholder: txn[:cardholder] || "",
        status: txn[:status] || "ok"
      )
    end
  end
end
