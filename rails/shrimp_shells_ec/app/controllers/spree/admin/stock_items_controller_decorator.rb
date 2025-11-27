module Spree
  module Admin
    module StockItemsControllerDecorator
      def self.prepended(base)
        base.class_eval do
          before_action :load_product, only: [:index, :edit], if: -> { params[:product_slug].present? }
          before_action :load_stock_item_for_update, only: [:update]
          
          def index
            @stock_items = Spree::StockItem.includes(:variant, :stock_location).all
            
            # フィルタリング
            if params[:status].present?
              case params[:status]
              when 'expired'
                @stock_items = @stock_items.select(&:is_expired?)
              when 'expiring_soon'
                @stock_items = @stock_items.select(&:expiring_soon?)
              when 'temp_alert'
                @stock_items = @stock_items.select(&:temperature_alert?)
              when 'low_stock'
                @stock_items = @stock_items.where('count_on_hand > 0 AND count_on_hand <= 10')
              end
            end
            
            if params[:temperature].present?
              case params[:temperature]
              when 'frozen'
                @stock_items = @stock_items.where('storage_temperature_actual <= ?', -18)
              when 'chilled'
                @stock_items = @stock_items.where('storage_temperature_actual > ? AND storage_temperature_actual <= ?', -18, 5)
              when 'ambient'
                @stock_items = @stock_items.where('storage_temperature_actual > ?', 5)
              end
            end
            
            if params[:lot_number].present?
              @stock_items = @stock_items.where("lot_number ILIKE ?", "%#{params[:lot_number]}%")
            end
          end
          
          def edit
            # @stock_itemとproductは既にロード済み
          end
          
          def update
            stock_item_params = params.require(:stock_item).permit(
              :count_on_hand,
              :backorderable,
              :lot_number,
              :expiry_date,
              :storage_temperature_actual,
              :priority_order,
              :received_date,
              :inspection_date,
              :manufacturing_date,
              :supplier_name,
              :purchase_price,
              :quality_status,
              :inventory_notes
            )
            
            @stock_item = Spree::StockItem.find(params[:id])
            
            if @stock_item.update(stock_item_params)
              respond_to do |format|
                format.html do
                  flash[:success] = '在庫情報を更新しました'
                  if params[:product_slug].present?
                    redirect_to admin_product_stock_path(params[:product_slug])
                  else
                    redirect_back(fallback_location: spree.admin_products_path)
                  end
                end
                format.json { render json: { success: true, stock_item: @stock_item } }
              end
            else
              respond_to do |format|
                format.html do
                  flash.now[:error] = '在庫情報の更新に失敗しました'
                  render :edit
                end
                format.json { render json: { success: false, errors: @stock_item.errors }, status: :unprocessable_entity }
              end
            end
          end
          
          private
          
          def load_product
            @product = Spree::Product.friendly.find(params[:product_slug] || params[:product_id])
          end
          
          def load_stock_item_for_update
            # update時はproductのロードは不要
          end
        end
      end
      
      ::Spree::Admin::StockItemsController.prepend(self) if defined?(::Spree::Admin::StockItemsController)
    end
  end
end
