class CreateJournalEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :journal_entries do |t|
      t.references :client, null: false, foreign_key: true, comment: "クライアント"
      t.string :source_type, null: false, comment: "入力元区別: amex / bank / invoice / receipt"
      t.string :source_period, comment: "明細期間（例: 2026-01）"
      t.integer :transaction_no, comment: "取引番号"
      t.date :date, null: false, comment: "取引日"
      t.text :description, default: "", comment: "摘要"
      t.string :tag, default: "", comment: "タグ"
      t.text :memo, default: "", comment: "メモ"
      t.string :cardholder, default: "", comment: "カード利用者（Amex等の複数会員明細用）"
      t.string :status, default: "ok", comment: "確認状態: ok / review_required"
      t.references :statement_batch, null: true, foreign_key: true

      t.timestamps
    end

    add_index :journal_entries, [:source_type, :source_period], name: "idx_journal_entries_source"
    add_index :journal_entries, [:client_id, :source_type, :source_period, :transaction_no],
              unique: true, name: "idx_journal_entries_unique_transaction"
    add_index :journal_entries, :date, name: "idx_journal_entries_date"
    add_index :journal_entries, :status, where: "status = 'review_required'",
              name: "idx_journal_entries_review_required"
  end
end
