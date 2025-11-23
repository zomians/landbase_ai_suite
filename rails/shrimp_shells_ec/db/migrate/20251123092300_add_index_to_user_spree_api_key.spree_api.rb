# frozen_string_literal: true

# This migration comes from spree_api (originally 20131017162334)
class AddIndexToUserSpreeApiKey < ActiveRecord::Migration[4.2]
  def change
    if table_exists?(:spree_users)
      add_index :spree_users, :spree_api_key
    end
  end
end
