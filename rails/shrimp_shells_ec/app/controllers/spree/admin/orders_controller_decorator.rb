module Spree
  module Admin
    module OrdersControllerDecorator
      def self.prepended(base)
        base.class_eval do
          # ピッキング完了を記録するアクション
          before_action :load_order_for_picking, only: [:mark_picking_complete]
        end
      end

      # 冷凍食品配送フィールドを許可
      def permitted_order_attributes
        super + [
          :preferred_delivery_date,
          :preferred_delivery_time,
          :carrier_code,
          :tracking_url,
          :redelivery_count,
          :picking_started_at,
          :picking_completed_at,
          :picking_inspector_name,
          :packing_temperature,
          :ice_pack_count,
          :temperature_alert,
          :temperature_controlled,
          :packing_note,
          :delivery_note,
          :subscription_order,
          :instagram_order_id
        ]
      end

      # 注文一覧にフィルタースコープを追加
      def index
        params[:q] ||= {}
        @search = Spree::Order.accessible_by(current_ability, :index)
                              .ransack(params[:q])

        # カスタムスコープを適用
        orders = @search.result.includes(:user).order(created_at: :desc)

        # 配送日でフィルタリング
        if params[:delivery_filter] == 'today'
          orders = orders.delivery_today
        elsif params[:delivery_filter] == 'tomorrow'
          orders = orders.delivery_tomorrow
        elsif params[:delivery_filter] == 'scheduled'
          orders = orders.delivery_scheduled
        end

        # ピッキング状態でフィルタリング
        if params[:picking_filter] == 'completed'
          orders = orders.picking_completed
        elsif params[:picking_filter] == 'pending'
          orders = orders.requires_shipping.where(picking_completed_at: nil)
        end

        # 温度アラートでフィルタリング
        if params[:temperature_filter] == 'alert'
          orders = orders.temperature_alerts
        end

        # 配送業者でフィルタリング
        if params[:carrier_code].present?
          orders = orders.by_carrier(params[:carrier_code])
        end

        # 再配達でフィルタリング
        if params[:redelivery_filter] == 'yes'
          orders = orders.redelivery_orders
        end

        @orders = orders.page(params[:page]).per(params[:per_page] || 25)
      end

      # ピッキング完了を記録
      def mark_picking_complete
        inspector_name = params[:inspector_name] || current_spree_user&.email
        
        if @order.mark_picking_completed!(inspector_name)
          render json: { 
            success: true, 
            message: 'ピッキング完了を記録しました',
            picking_completed_at: @order.picking_completed_at,
            inspector_name: @order.picking_inspector_name
          }
        else
          render json: { 
            success: false, 
            error: @order.errors.full_messages.join(', ')
          }, status: :unprocessable_entity
        end
      rescue => e
        render json: { 
          success: false, 
          error: e.message 
        }, status: :internal_server_error
      end

      private

      def load_order_for_picking
        @order = Spree::Order.find_by!(number: params[:id])
        authorize! :update, @order
      end
    end
  end
end

Spree::Admin::OrdersController.prepend(Spree::Admin::OrdersControllerDecorator)
