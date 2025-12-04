# frozen_string_literal: true

class ProductsController < StoreController
  before_action :load_product, only: :show
  before_action :load_taxon, only: :index

  helper 'spree/products', 'spree/taxons', 'taxon_filters'

  respond_to :html

  rescue_from Spree::Config.searcher_class::InvalidOptions do |error|
    raise ActionController::BadRequest.new, error.message
  end

  def index
    # カスタムフィルタリング機能を追加
    @search = Spree::Product.available
                            .ransack(params[:q])
    
    # 基本検索結果
    products = @search.result.includes(:master)
    
    # エビサイズフィルター
    if params[:shrimp_size].present?
      products = products.by_shrimp_size(params[:shrimp_size])
    end
    
    # 原産地フィルター
    if params[:shrimp_origin].present?
      products = products.by_shrimp_origin(params[:shrimp_origin])
    end
    
    # 漁獲方法フィルター
    if params[:catch_method].present?
      products = products.where(catch_method: params[:catch_method])
    end
    
    # 認証全般フィルター（ハラールまたはオーガニック）
    if params[:certified] == '1'
      products = products.with_certifications
    end
    
    # アレルギー対応フィルター（ログインユーザーのアレルギー情報に基づく）
    if current_spree_user&.allergies.present?
      allergen_keywords = current_spree_user.allergies.split(/[,、]/).map(&:strip)
      allergen_keywords.each do |allergen|
        next if allergen.blank?
        # アレルゲンを含む商品を除外
        products = products.where.not("allergens ILIKE ?", "%#{allergen}%")
      end
    end
    
    # ソート順（デフォルト: 新着順）
    sort_order = params[:sort] || 'newest'
    case sort_order
    when 'price_asc'
      products = products.joins(:master).merge(Spree::Variant.order(price: :asc))
    when 'price_desc'
      products = products.joins(:master).merge(Spree::Variant.order(price: :desc))
    when 'name_asc'
      products = products.order(name: :asc)
    when 'name_desc'
      products = products.order(name: :desc)
    else  # 'newest'
      products = products.order(available_on: :desc, created_at: :desc)
    end
    
    @products = products.page(params[:page]).per(params[:per_page] || 12)
    
    # フィルター用の選択肢を取得
    @available_shrimp_sizes = Spree::Product.available.where.not(shrimp_size: nil).distinct.pluck(:shrimp_size)
    @available_shrimp_origins = Spree::Product.available.where.not(shrimp_origin: nil).distinct.pluck(:shrimp_origin)
    @available_catch_methods = Spree::Product.available.where.not(catch_method: nil).distinct.pluck(:catch_method)
  end

  def show
    @variants = @product.
      variants_including_master.
      display_includes.
      with_prices(current_pricing_options).
      includes([:option_values, :images])

    @product_properties = @product.product_properties.includes(:property)
    @taxon = Spree::Taxon.find(params[:taxon_id]) if params[:taxon_id]
    @similar_products = @product.similar_products
  end

  private

  def accurate_title
    if @product
      @product.meta_title.blank? ? @product.name : @product.meta_title
    else
      super
    end
  end

  def load_product
    if spree_current_user.try(:has_spree_role?, "admin")
      @products = Spree::Product.with_discarded
    else
      @products = Spree::Product.available
    end
    @product = @products.friendly.find(params[:id])

    # Redirects to the correct product URL if the requested slug does not match the current product's slug.
    # This ensures that outdated or ID URLs always resolve to the latest canonical URL.
    redirect_to @product, status: :moved_permanently if params[:id] != @product.slug
  end

  def load_taxon
    @taxon = Spree::Taxon.find(params[:taxon]) if params[:taxon].present?
  end
end
