class CreateStatementBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :statement_batches do |t|
      t.references :client, null: false, foreign_key: true
      t.string :source_type, null: false, default: "amex", comment: "入力元区別: amex / bank / invoice / receipt"
      t.string :statement_period, comment: "明細期間（例: 2026年1月）"
      t.string :status, null: false, default: "processing", comment: "処理状態: processing / completed / failed"
      t.text :error_message, comment: "エラーメッセージ"
      t.jsonb :summary, default: {}, comment: "処理結果サマリー"

      t.timestamps
    end

    add_index :statement_batches, :status
    add_index :statement_batches, [:client_id, :status], name: "idx_statement_batches_client_status"
  end
end
