# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_02_19_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "account_masters", force: :cascade do |t|
    t.string "client_code", null: false, comment: "マルチテナント識別子"
    t.string "merchant_keyword", comment: "店舗名キーワード（マッチング用）"
    t.string "description_keyword", comment: "取引内容キーワード（マッチング用）"
    t.string "account_category", null: false, comment: "勘定科目カテゴリ"
    t.integer "confidence_score", default: 50, comment: "信頼度スコア（0-100）"
    t.date "last_used_date", comment: "最終使用日"
    t.integer "usage_count", default: 0, comment: "使用回数"
    t.boolean "auto_learned", default: false, comment: "自動学習フラグ"
    t.text "notes", default: "", comment: "備考"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_code"], name: "idx_account_masters_client"
    t.index ["merchant_keyword"], name: "idx_account_masters_merchant"
  end

  create_table "journal_entries", force: :cascade do |t|
    t.string "client_code", null: false, comment: "マルチテナント識別子"
    t.string "source_type", null: false, comment: "入力元区別: amex / bank / invoice / receipt"
    t.string "source_period", comment: "明細期間（例: 2026-01）"
    t.integer "transaction_no", comment: "取引番号"
    t.date "date", null: false, comment: "取引日"
    t.string "debit_account", null: false, comment: "借方勘定科目"
    t.string "debit_sub_account", default: "", comment: "借方補助科目"
    t.string "debit_department", default: "", comment: "借方部門"
    t.string "debit_partner", default: "", comment: "借方取引先"
    t.string "debit_tax_category", default: "", comment: "借方税区分"
    t.string "debit_invoice", default: "", comment: "借方インボイス"
    t.integer "debit_amount", null: false, comment: "借方金額"
    t.string "credit_account", null: false, comment: "貸方勘定科目"
    t.string "credit_sub_account", default: "", comment: "貸方補助科目"
    t.string "credit_department", default: "", comment: "貸方部門"
    t.string "credit_partner", default: "", comment: "貸方取引先"
    t.string "credit_tax_category", default: "", comment: "貸方税区分"
    t.string "credit_invoice", default: "", comment: "貸方インボイス"
    t.integer "credit_amount", null: false, comment: "貸方金額"
    t.text "description", default: "", comment: "摘要"
    t.string "tag", default: "", comment: "タグ"
    t.text "memo", default: "", comment: "メモ"
    t.string "cardholder", default: "", comment: "カード利用者（Amex等の複数会員明細用）"
    t.string "status", default: "ok", comment: "確認状態: ok / review_required"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_code"], name: "idx_journal_entries_client"
    t.index ["client_code", "source_type", "source_period", "transaction_no"], name: "idx_journal_entries_unique_transaction", unique: true
    t.index ["date"], name: "idx_journal_entries_date"
    t.index ["source_type", "source_period"], name: "idx_journal_entries_source"
    t.index ["status"], name: "idx_journal_entries_review_required", where: "((status)::text = 'review_required'::text)"
  end
end
