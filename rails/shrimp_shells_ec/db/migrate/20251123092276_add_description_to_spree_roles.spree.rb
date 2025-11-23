# This migration comes from spree (originally 20240821173641)
class AddDescriptionToSpreeRoles < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_roles, :description, :text
  end
end
