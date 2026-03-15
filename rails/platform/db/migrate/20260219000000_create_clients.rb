class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients do |t|
      t.string :code, null: false, comment: "クライアント識別子 (例: ikigai_stay)"
      t.string :name, null: false, comment: "クライアント名"
      t.string :industry, comment: "業種: restaurant / hotel / tour"
      t.jsonb :services, default: {}, comment: "サービス設定"
      t.string :status, default: "active", comment: "ステータス: active / trial / inactive"
      t.string :line_user_id, comment: "LINE user ID（Webhook識別用）"

      t.timestamps
    end

    add_index :clients, :code, unique: true, name: "idx_clients_code"
    add_index :clients, :services, using: :gin, name: "idx_clients_services"
    add_index :clients, :line_user_id, unique: true, where: "line_user_id IS NOT NULL"
  end
end
