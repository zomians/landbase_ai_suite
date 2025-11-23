# This migration comes from solidus_legacy_promotions_engine (originally 20230322085416)
class RemoveMatchPolicyFromSpreePromotion < ActiveRecord::Migration[5.2]
  def change
    if column_exists?(:spree_promotions, :match_policy)
      remove_column :spree_promotions, :match_policy, :string, default: "all"
    end
  end
end
