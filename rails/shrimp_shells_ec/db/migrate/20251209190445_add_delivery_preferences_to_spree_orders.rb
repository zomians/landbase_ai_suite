class AddDeliveryPreferencesToSpreeOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :spree_orders, :preferred_carrier, :string
    add_column :spree_orders, :allergies_confirmed, :boolean
  end
end
