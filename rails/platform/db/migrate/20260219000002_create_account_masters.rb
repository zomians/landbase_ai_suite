class CreateAccountMasters < ActiveRecord::Migration[8.0]
  def change
    create_table :account_masters do |t|
      t.string :client_code, null: false, comment: "マルチテナント識別子"
      t.string :merchant_keyword, comment: "店舗名キーワード（マッチング用）"
      t.string :description_keyword, comment: "取引内容キーワード（マッチング用）"
      t.string :account_category, null: false, comment: "勘定科目カテゴリ"
      t.integer :confidence_score, default: 50, comment: "信頼度スコア（0-100）"
      t.date :last_used_date, comment: "最終使用日"
      t.integer :usage_count, default: 0, comment: "使用回数"
      t.boolean :auto_learned, default: false, comment: "自動学習フラグ"
      t.text :notes, default: "", comment: "備考"

      t.timestamps
    end

    add_index :account_masters, :client_code, name: "idx_account_masters_client"
    add_index :account_masters, :merchant_keyword, name: "idx_account_masters_merchant"
  end
end
