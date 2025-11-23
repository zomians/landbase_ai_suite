# This migration comes from spree (originally 20240904152041)
class AddPrivilegeAndCategoryToSpreePermissionSets < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_permission_sets, :privilege, :string
    add_column :spree_permission_sets, :category, :string
  end
end
