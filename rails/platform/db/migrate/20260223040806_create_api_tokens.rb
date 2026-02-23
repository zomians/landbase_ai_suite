class CreateApiTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :api_tokens do |t|
      t.string :name, null: false, comment: "トークン識別名（例: n8n, development）"
      t.string :token_digest, null: false, comment: "SHA256ハッシュ化トークン"
      t.datetime :last_used_at, comment: "最終使用日時"
      t.datetime :expires_at, comment: "有効期限（nilは無期限）"

      t.timestamps
    end

    add_index :api_tokens, :token_digest, unique: true
  end
end
