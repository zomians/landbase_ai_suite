# This migration comes from solidus_stripe (originally 20230109183332)
class CreateSolidusStripePaymentSources < ActiveRecord::Migration[5.2]
  def change
    create_table :solidus_stripe_payment_sources do |t|
      t.integer :payment_method_id
      t.string :stripe_payment_method_id

      t.timestamps
    end
  end
end
