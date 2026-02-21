class AddStatementBatchIdToJournalEntries < ActiveRecord::Migration[8.0]
  def change
    add_reference :journal_entries, :statement_batch, null: true, foreign_key: true
  end
end
