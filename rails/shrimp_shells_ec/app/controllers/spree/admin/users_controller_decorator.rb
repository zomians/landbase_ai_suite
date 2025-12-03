module Spree
  module Admin
    module UsersControllerDecorator
      def self.prepended(base)
        base.class_eval do
          # フィルター適用前の処理
          before_action :apply_customer_filters, only: [:index]
        end
      end

      # カスタムフィールドを許可
      def permitted_user_attributes
        super + [
          :gender,
          :birth_date,
          :phone_number,
          :company_name,
          :customer_rank,
          :vip_flag,
          :attention_flag,
          :customer_memo,
          :allergies,
          :dietary_restrictions,
          :dm_allowed,
          :newsletter_subscribed,
          :instagram_handle,
          :line_user_id,
          :preferred_carrier,
          :preferred_delivery_time,
          :delivery_memo,
          :total_purchase_amount,
          :total_purchase_count,
          :last_purchase_date
        ]
      end

      # 顧客一覧にフィルター機能を追加
      def index
        params[:q] ||= {}
        
        # 基本検索
        @search = Spree.user_class.accessible_by(current_ability, :index)
                                   .ransack(params[:q])
        
        users = @search.result.includes(:spree_roles)
        
        # カスタムフィルター適用
        users = apply_custom_filters(users)
        
        @users = users.page(params[:page]).per(params[:per_page] || 25)
        
        # ロール情報取得（既存処理）
        @roles = Spree::Role.accessible_by(current_ability, :read)
        @user_roles = @user&.spree_roles || []
      end

      private

      def apply_customer_filters
        # フィルターパラメータを保持
        @customer_rank_filter = params[:customer_rank_filter]
        @customer_status_filter = params[:customer_status_filter]
        @marketing_filter = params[:marketing_filter]
        @allergy_filter = params[:allergy_filter]
      end

      def apply_custom_filters(users)
        # 顧客ランクフィルター
        if params[:customer_rank_filter].present?
          users = users.by_rank(params[:customer_rank_filter])
        end

        # 顧客ステータスフィルター
        case params[:customer_status_filter]
        when 'active'
          users = users.recent_purchasers(30)
        when 'dormant'
          users = users.inactive_customers(90)
        when 'vip'
          users = users.vip_customers
        when 'attention'
          users = users.attention_customers
        when 'high_value'
          users = users.high_value_customers
        end

        # マーケティングフィルター
        case params[:marketing_filter]
        when 'dm_allowed'
          users = users.dm_allowed_customers
        when 'newsletter'
          users = users.newsletter_subscribers
        when 'marketable'
          users = users.dm_allowed_customers
                       .where(attention_flag: false)
                       .where(deleted_at: nil)
        end

        # アレルギーフィルター
        case params[:allergy_filter]
        when 'has_allergies'
          users = users.where.not(allergies: [nil, ''])
        when 'no_allergies'
          users = users.where(allergies: [nil, ''])
        end

        users
      end
    end
  end
end

Spree::Admin::UsersController.prepend(Spree::Admin::UsersControllerDecorator)
