class CreateCleaningManuals < ActiveRecord::Migration[8.0]
  def change
    create_table :cleaning_manuals do |t|
      t.references :client, null: false, foreign_key: true
      t.string :property_name, null: false
      t.string :room_type, null: false
      t.jsonb :manual_data, null: false, default: {}
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    add_index :cleaning_manuals, :status
    add_index :cleaning_manuals, [:client_id, :property_name]
  end
end
