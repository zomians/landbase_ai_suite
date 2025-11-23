# frozen_string_literal: true

# This migration comes from solidus_legacy_promotions_engine (originally 20180202190713)
class CreatePromotionRuleStores < ActiveRecord::Migration[5.1]
  def change
    unless table_exists?(:spree_promotion_rules_stores)
      create_table :spree_promotion_rules_stores do |t|
        t.references :store, null: false
        t.references :promotion_rule, null: false

        t.timestamps
      end
    end
  end
end
