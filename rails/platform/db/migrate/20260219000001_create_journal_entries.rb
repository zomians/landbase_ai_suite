class CreateJournalEntries < ActiveRecord::Migration[8.0]
  def up
    create_table :journal_entries do |t|
      t.string :client_code, null: false, comment: "マルチテナント識別子"
      t.string :source_type, null: false, comment: "入力元区別: amex / bank / invoice / receipt"
      t.string :source_period, comment: "明細期間（例: 2026-01）"
      t.integer :transaction_no, comment: "取引番号"
      t.date :date, null: false, comment: "取引日"
      t.string :debit_account, null: false, comment: "借方勘定科目"
      t.string :debit_sub_account, default: "", comment: "借方補助科目"
      t.string :debit_department, default: "", comment: "借方部門"
      t.string :debit_partner, default: "", comment: "借方取引先"
      t.string :debit_tax_category, default: "", comment: "借方税区分"
      t.string :debit_invoice, default: "", comment: "借方インボイス"
      t.integer :debit_amount, null: false, comment: "借方金額"
      t.string :credit_account, null: false, comment: "貸方勘定科目"
      t.string :credit_sub_account, default: "", comment: "貸方補助科目"
      t.string :credit_department, default: "", comment: "貸方部門"
      t.string :credit_partner, default: "", comment: "貸方取引先"
      t.string :credit_tax_category, default: "", comment: "貸方税区分"
      t.string :credit_invoice, default: "", comment: "貸方インボイス"
      t.integer :credit_amount, null: false, comment: "貸方金額"
      t.text :description, default: "", comment: "摘要"
      t.string :tag, default: "", comment: "タグ"
      t.text :memo, default: "", comment: "メモ"
      t.string :status, default: "ok", comment: "確認状態: ok / review_required"

      t.timestamps
    end

    add_index :journal_entries, :client_code, name: "idx_journal_entries_client"
    add_index :journal_entries, [:source_type, :source_period], name: "idx_journal_entries_source"
    add_index :journal_entries, :date, name: "idx_journal_entries_date"
    add_index :journal_entries, :status, name: "idx_journal_entries_status"
  end

  def down
    drop_table :journal_entries
  end
end
