# frozen_string_literal: true

# 商品一覧ページにブランドストーリーバナーとフィルターUIを追加
Deface::Override.new(
  virtual_path: 'spree/products/index',
  name: 'add_shrimp_shells_brand_banner',
  insert_top: '[data-hook="products_search_results_heading"], #products',
  text: <<-HTML
    <div class="shrimp-shells-brand-banner" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 2.5rem 2rem; border-radius: 1rem; margin-bottom: 2rem; text-align: center; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);">
      <h1 style="margin: 0 0 0.75rem 0; font-size: 2rem; font-weight: bold; text-shadow: 2px 2px 4px rgba(0,0,0,0.2);">🌺 ハワイのホームパーティ体験を、あなたの食卓に</h1>
      <p style="margin: 0; font-size: 1.125rem; opacity: 0.95;">横浜のプロ料理人が研究し尽くした、本場を超えるガーリックシュリンプ</p>
      <p style="margin: 0.5rem 0 0 0; font-size: 0.875rem; opacity: 0.85;">Port to Port. 港町から港町へ 🦐✨</p>
    </div>

    <% if current_spree_user&.allergies.present? %>
      <div class="alert alert-info" style="background: #d1ecf1; border: 1px solid #bee5eb; padding: 1rem; border-radius: 0.5rem; margin-bottom: 1.5rem;">
        <strong>💡 あなたのアレルギー情報に基づいて表示しています</strong>
        <p style="margin: 0.5rem 0 0 0;">除外アレルゲン: <%= current_spree_user.allergies %></p>
        <%= link_to '設定を変更', account_path, class: 'btn btn-sm btn-secondary', style: 'margin-top: 0.5rem;' %>
      </div>
    <% end %>
  HTML
)

# 商品一覧ページにフィルターUIを追加
Deface::Override.new(
  virtual_path: 'spree/products/index',
  name: 'add_frozen_food_filters',
  insert_after: '[data-hook="products_search_results_heading"], #products',
  text: <<-HTML
    <div class="frozen-food-filters" style="background: #f8f9fa; padding: 1.5rem; border-radius: 0.5rem; margin-bottom: 2rem;">
      <h3 style="margin: 0 0 1rem 0; font-size: 1.25rem; font-weight: 600;">🔍 商品を絞り込む</h3>
      
      <%= form_tag products_path, method: :get, style: 'display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem;' do %>
        
        <!-- エビサイズフィルター -->
        <% if @available_shrimp_sizes.present? %>
          <div class="filter-group">
            <label style="display: block; font-weight: 600; margin-bottom: 0.5rem; font-size: 0.875rem;">エビサイズ</label>
            <select name="shrimp_size" class="form-control" style="width: 100%;">
              <option value="">すべて</option>
              <% @available_shrimp_sizes.each do |size| %>
                <option value="<%= size %>" <%= 'selected' if params[:shrimp_size] == size %>><%= size %></option>
              <% end %>
            </select>
          </div>
        <% end %>

        <!-- 原産地フィルター -->
        <% if @available_shrimp_origins.present? %>
          <div class="filter-group">
            <label style="display: block; font-weight: 600; margin-bottom: 0.5rem; font-size: 0.875rem;">原産地</label>
            <select name="shrimp_origin" class="form-control" style="width: 100%;">
              <option value="">すべて</option>
              <% @available_shrimp_origins.each do |origin| %>
                <option value="<%= origin %>" <%= 'selected' if params[:shrimp_origin] == origin %>><%= origin %></option>
              <% end %>
            </select>
          </div>
        <% end %>

        <!-- 漁獲方法フィルター -->
        <% if @available_catch_methods.present? %>
          <div class="filter-group">
            <label style="display: block; font-weight: 600; margin-bottom: 0.5rem; font-size: 0.875rem;">漁獲方法</label>
            <select name="catch_method" class="form-control" style="width: 100%;">
              <option value="">すべて</option>
              <% @available_catch_methods.each do |method| %>
                <option value="<%= method %>" <%= 'selected' if params[:catch_method] == method %>><%= method %></option>
              <% end %>
            </select>
          </div>
        <% end %>

        <!-- 認証フィルター -->
        <div class="filter-group">
          <label style="display: block; font-weight: 600; margin-bottom: 0.5rem; font-size: 0.875rem;">認証</label>
          <select name="certified" class="form-control" style="width: 100%;">
            <option value="">すべて</option>
            <option value="1" <%= 'selected' if params[:certified] == '1' %>>認証商品のみ</option>
          </select>
        </div>

        <!-- ソート順 -->
        <div class="filter-group">
          <label style="display: block; font-weight: 600; margin-bottom: 0.5rem; font-size: 0.875rem;">並び順</label>
          <select name="sort" class="form-control" style="width: 100%;">
            <option value="newest" <%= 'selected' if params[:sort] == 'newest' || params[:sort].blank? %>>新着順</option>
            <option value="price_asc" <%= 'selected' if params[:sort] == 'price_asc' %>>価格が安い順</option>
            <option value="price_desc" <%= 'selected' if params[:sort] == 'price_desc' %>>価格が高い順</option>
            <option value="name_asc" <%= 'selected' if params[:sort] == 'name_asc' %>>名前 (A-Z)</option>
            <option value="name_desc" <%= 'selected' if params[:sort] == 'name_desc' %>>名前 (Z-A)</option>
          </select>
        </div>

        <!-- 検索・フィルター実行ボタン -->
        <div class="filter-group" style="display: flex; align-items: flex-end;">
          <%= submit_tag '絞り込む', class: 'btn btn-primary', style: 'width: 100%; padding: 0.5rem 1rem; font-weight: 600;' %>
        </div>

        <% if params[:shrimp_size].present? || params[:shrimp_origin].present? || params[:catch_method].present? || params[:certified].present? || params[:sort].present? %>
          <div class="filter-group" style="display: flex; align-items: flex-end;">
            <%= link_to 'リセット', products_path, class: 'btn btn-secondary', style: 'width: 100%; text-align: center; padding: 0.5rem 1rem; text-decoration: none; display: block;' %>
          </div>
        <% end %>

      <% end %>
    </div>
  HTML
)

# 商品カードに冷凍食品バッジを追加
Deface::Override.new(
  virtual_path: 'spree/products/_product',
  name: 'add_frozen_food_badges_to_product_card',
  insert_after: '[data-hook="product_price"], .product-price',
  text: <<-HTML
    <div class="product-badges" style="margin-top: 0.5rem; display: flex; flex-wrap: wrap; gap: 0.25rem;">
      <% if product.shrimp_size.present? %>
        <span class="badge badge-info" style="background: #17a2b8; color: white; padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem;">
          <%= product.shrimp_size %>
        </span>
      <% end %>
      
      <% if product.shrimp_origin.present? %>
        <span class="badge badge-secondary" style="background: #6c757d; color: white; padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem;">
          <%= product.shrimp_origin %>産
        </span>
      <% end %>
      
      <% if product.halal_certified %>
        <span class="badge badge-success" style="background: #28a745; color: white; padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem;">
          ✓ ハラール
        </span>
      <% end %>
      
      <% if product.organic_certified %>
        <span class="badge badge-success" style="background: #20c997; color: white; padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem;">
          🌿 オーガニック
        </span>
      <% end %>
      
      <% if product.frozen_product? %>
        <span class="badge badge-primary" style="background: #007bff; color: white; padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem;">
          ❄️ 冷凍
        </span>
      <% end %>
    </div>
  HTML
)
