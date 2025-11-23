# This migration comes from spree (originally 20250508145917)
class AddEmailToStockLocations < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_stock_locations, :email, :string
  end
end
