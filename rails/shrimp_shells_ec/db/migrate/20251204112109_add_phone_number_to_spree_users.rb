class AddPhoneNumberToSpreeUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :spree_users, :phone_number, :string
  end
end
