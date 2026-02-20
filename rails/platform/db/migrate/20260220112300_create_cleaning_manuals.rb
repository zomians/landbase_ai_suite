class CreateCleaningManuals < ActiveRecord::Migration[8.0]
  def change
    create_table :cleaning_manuals do |t|
      t.string :client_code, null: false
      t.string :property_name, null: false
      t.string :room_type, null: false
      t.jsonb :manual_data, null: false, default: {}
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    add_index :cleaning_manuals, :client_code
    add_index :cleaning_manuals, :status
    add_index :cleaning_manuals, [:client_code, :property_name]
  end
end
