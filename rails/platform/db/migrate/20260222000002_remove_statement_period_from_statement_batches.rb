class RemoveStatementPeriodFromStatementBatches < ActiveRecord::Migration[8.0]
  def change
    remove_column :statement_batches, :statement_period, :string
  end
end
