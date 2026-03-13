class AddLineUserIdToClients < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :line_user_id, :string, comment: "LINE user ID（Webhook識別用）"
    add_index :clients, :line_user_id, unique: true, where: "line_user_id IS NOT NULL"
  end
end
