module JournalEntryCreator
  extend ActiveSupport::Concern

  private

  def create_journal_entries(batch, data)
    source_period = if data[:receipt_date].present?
      begin
        date = Date.parse(data[:receipt_date])
        "#{date.year}年#{date.month}月"
      rescue Date::Error
        nil
      end
    end

    transactions = data[:transactions] || []
    transactions.each do |txn|
      batch.journal_entries.create!(
        client: batch.client,
        source_type: batch.source_type,
        source_period: source_period,
        transaction_no: txn[:transaction_no],
        date: txn[:date],
        description: txn[:description] || "",
        tag: txn[:tag] || "receipt",
        memo: txn[:memo] || "",
        cardholder: "",
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
