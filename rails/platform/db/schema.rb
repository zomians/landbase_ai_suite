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

ActiveRecord::Schema[8.0].define(version: 2026_02_22_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "account_masters", force: :cascade do |t|
    t.bigint "client_id", null: false, comment: "クライアント"
    t.string "source_type", comment: "入力元区別: amex / bank / invoice / receipt（nilは全ソース共通）"
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
    t.index ["client_id", "source_type"], name: "idx_account_masters_client_source"
    t.index ["client_id"], name: "index_account_masters_on_client_id"
    t.index ["merchant_keyword"], name: "idx_account_masters_merchant"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cleaning_manuals", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.string "property_name", null: false
    t.string "room_type", null: false
    t.jsonb "manual_data", default: {}, null: false
    t.string "status", default: "draft", null: false
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "property_name"], name: "index_cleaning_manuals_on_client_id_and_property_name"
    t.index ["client_id"], name: "index_cleaning_manuals_on_client_id"
    t.index ["status"], name: "index_cleaning_manuals_on_status"
  end

  create_table "clients", force: :cascade do |t|
    t.string "code", null: false, comment: "クライアント識別子 (例: shrimp_shells)"
    t.string "name", null: false, comment: "クライアント名"
    t.string "industry", comment: "業種: restaurant / hotel / tour"
    t.jsonb "services", default: {}, comment: "サービス設定"
    t.string "status", default: "active", comment: "ステータス: active / trial / inactive"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "idx_clients_code", unique: true
    t.index ["services"], name: "idx_clients_services", using: :gin
  end

  create_table "journal_entries", force: :cascade do |t|
    t.bigint "client_id", null: false, comment: "クライアント"
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
    t.bigint "statement_batch_id"
    t.index ["client_id", "source_type", "source_period", "transaction_no"], name: "idx_journal_entries_unique_transaction", unique: true
    t.index ["client_id"], name: "index_journal_entries_on_client_id"
    t.index ["date"], name: "idx_journal_entries_date"
    t.index ["source_type", "source_period"], name: "idx_journal_entries_source"
    t.index ["statement_batch_id"], name: "index_journal_entries_on_statement_batch_id"
    t.index ["status"], name: "idx_journal_entries_review_required", where: "((status)::text = 'review_required'::text)"
  end

  create_table "statement_batches", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.string "source_type", default: "amex", null: false, comment: "入力元区別: amex / bank / invoice / receipt"
    t.string "statement_period", comment: "明細期間（例: 2026年1月）"
    t.string "status", default: "processing", null: false, comment: "処理状態: processing / completed / failed"
    t.text "error_message", comment: "エラーメッセージ"
    t.jsonb "summary", default: {}, comment: "処理結果サマリー"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pdf_fingerprint", comment: "PDFファイルのSHA256ハッシュ（重複検知用）"
    t.index ["client_id", "pdf_fingerprint"], name: "idx_statement_batches_client_fingerprint"
    t.index ["client_id", "status"], name: "idx_statement_batches_client_status"
    t.index ["client_id"], name: "index_statement_batches_on_client_id"
    t.index ["status"], name: "index_statement_batches_on_status"
  end

  add_foreign_key "account_masters", "clients"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cleaning_manuals", "clients"
  add_foreign_key "journal_entries", "clients"
  add_foreign_key "journal_entries", "statement_batches"
  add_foreign_key "statement_batches", "clients"
end
