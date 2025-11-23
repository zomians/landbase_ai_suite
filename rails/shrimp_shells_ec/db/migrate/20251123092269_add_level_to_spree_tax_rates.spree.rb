# This migration comes from spree (originally 20220805202442)
class AddLevelToSpreeTaxRates < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_tax_rates, :level, :integer, default: 0, null: false
  end
end
