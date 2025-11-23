# frozen_string_literal: true

# This migration comes from spree (originally 20250628094037)
class ChangeCountriesIsoToUnique < ActiveRecord::Migration[7.0]
  def change
    remove_index :spree_countries, :iso

    add_index :spree_countries, :iso, unique: true
  end
end
