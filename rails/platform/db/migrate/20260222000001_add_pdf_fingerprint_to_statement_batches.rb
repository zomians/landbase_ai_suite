class AddPdfFingerprintToStatementBatches < ActiveRecord::Migration[8.0]
  def change
    add_column :statement_batches, :pdf_fingerprint, :string, comment: "PDFファイルのSHA256ハッシュ（重複検知用）"
    add_index :statement_batches, [:client_id, :pdf_fingerprint], name: "idx_statement_batches_client_fingerprint"
  end
end
