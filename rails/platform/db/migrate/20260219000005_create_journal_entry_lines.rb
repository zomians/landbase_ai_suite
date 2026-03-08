class CreateJournalEntryLines < ActiveRecord::Migration[8.0]
  def change
    create_table :journal_entry_lines do |t|
      t.references :journal_entry, null: false, foreign_key: true, comment: "仕訳"
      t.string :side, null: false, comment: "借方/貸方: debit / credit"
      t.string :account, null: false, comment: "勘定科目"
      t.string :sub_account, default: "", comment: "補助科目"
      t.string :department, default: "", comment: "部門"
      t.string :partner, default: "", comment: "取引先"
      t.string :tax_category, default: "", comment: "税区分"
      t.string :invoice, default: "", comment: "インボイス番号"
      t.integer :amount, null: false, comment: "金額"

      t.timestamps
    end

    add_index :journal_entry_lines, [:journal_entry_id, :side], name: "idx_journal_entry_lines_entry_side"
  end
end
