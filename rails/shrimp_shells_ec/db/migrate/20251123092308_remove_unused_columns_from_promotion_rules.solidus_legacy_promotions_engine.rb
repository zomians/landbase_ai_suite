# This migration comes from solidus_legacy_promotions_engine (originally 20230325132905)
class RemoveUnusedColumnsFromPromotionRules < ActiveRecord::Migration[5.2]
  def change
    if column_exists?(:spree_promotion_rules, :code)
      remove_column :spree_promotion_rules, :code, :string
    end
    if column_exists?(:spree_promotion_rules, :product_group_id)
      remove_column :spree_promotion_rules, :product_group_id, :integer
    end
  end
end
