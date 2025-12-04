# frozen_string_literal: true

# 商品詳細ページにブランドストーリーバナーを追加
Deface::Override.new(
  virtual_path: 'spree/products/show',
  name: 'add_brand_story_banner_to_product_show',
  insert_before: '[data-hook="product_show"], #product-details',
  text: <<-HTML
    <div class="brand-story-banner" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 2rem; border-radius: 1rem; margin-bottom: 2rem; text-align: center; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
      <h2 style="margin: 0 0 0.5rem 0; font-size: 1.5rem; font-weight: bold; text-shadow: 1px 1px 2px rgba(0,0,0,0.2);">🌺 ハワイのホームパーティ体験を、あなたの食卓に</h2>
      <p style="margin: 0; font-size: 1rem; opacity: 0.95;">横浜のプロ料理人が研究し尽くした、本場を超えるガーリックシュリンプ</p>
    </div>
  HTML
)

# 商品詳細ページに冷凍食品詳細情報セクションを追加
Deface::Override.new(
  virtual_path: 'spree/products/show',
  name: 'add_frozen_food_details_section',
  insert_after: '[data-hook="product_description"], #product-description',
  text: <<-HTML
    <div class="frozen-food-details" style="margin-top: 2.5rem; padding: 2rem; background: #f8f9fa; border-radius: 0.75rem;">
      
      <!-- 基本情報 -->
      <div class="product-specs" style="margin-bottom: 2rem;">
        <h3 style="margin: 0 0 1.5rem 0; font-size: 1.5rem; font-weight: 600; color: #333; border-bottom: 3px solid #667eea; padding-bottom: 0.5rem;">🦐 商品詳細</h3>
        
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1rem;">
          <% if @product.shrimp_origin.present? %>
            <div class="spec-item" style="background: white; padding: 1rem; border-radius: 0.5rem; border-left: 4px solid #17a2b8;">
              <strong style="display: block; color: #666; font-size: 0.875rem; margin-bottom: 0.25rem;">原産地</strong>
              <span style="font-size: 1.125rem; color: #333;"><%= @product.shrimp_origin %></span>
            </div>
          <% end %>
          
          <% if @product.shrimp_size.present? %>
            <div class="spec-item" style="background: white; padding: 1rem; border-radius: 0.5rem; border-left: 4px solid #17a2b8;">
              <strong style="display: block; color: #666; font-size: 0.875rem; margin-bottom: 0.25rem;">エビサイズ</strong>
              <span style="font-size: 1.125rem; color: #333;"><%= @product.shrimp_size %></span>
            </div>
          <% end %>
          
          <% if @product.catch_method.present? %>
            <div class="spec-item" style="background: white; padding: 1rem; border-radius: 0.5rem; border-left: 4px solid #20c997;">
              <strong style="display: block; color: #666; font-size: 0.875rem; margin-bottom: 0.25rem;">漁獲方法</strong>
              <span style="font-size: 1.125rem; color: #333;"><%= @product.catch_method %></span>
            </div>
          <% end %>
          
          <% if @product.net_weight.present? %>
            <div class="spec-item" style="background: white; padding: 1rem; border-radius: 0.5rem; border-left: 4px solid #ffc107;">
              <strong style="display: block; color: #666; font-size: 0.875rem; margin-bottom: 0.25rem;">内容量</strong>
              <span style="font-size: 1.125rem; color: #333;"><%= @product.net_weight %>g</span>
            </div>
          <% end %>
          
          <% if @product.storage_temperature.present? %>
            <div class="spec-item" style="background: white; padding: 1rem; border-radius: 0.5rem; border-left: 4px solid #007bff;">
              <strong style="display: block; color: #666; font-size: 0.875rem; margin-bottom: 0.25rem;">保管温度</strong>
              <span style="font-size: 1.125rem; color: #333;">❄️ <%= @product.storage_temperature %>℃以下</span>
            </div>
          <% end %>
          
          <% if @product.best_before_months.present? %>
            <div class="spec-item" style="background: white; padding: 1rem; border-radius: 0.5rem; border-left: 4px solid #6c757d;">
              <strong style="display: block; color: #666; font-size: 0.875rem; margin-bottom: 0.25rem;">賞味期限</strong>
              <span style="font-size: 1.125rem; color: #333;">製造から<%= @product.best_before_months %>ヶ月</span>
            </div>
          <% end %>
        </div>

        <!-- 認証バッジ -->
        <% if @product.halal_certified || @product.organic_certified %>
          <div class="certifications" style="margin-top: 1.5rem; display: flex; gap: 0.75rem;">
            <% if @product.halal_certified %>
              <div class="cert-badge" style="background: #28a745; color: white; padding: 0.75rem 1.5rem; border-radius: 2rem; font-weight: 600; display: inline-flex; align-items: center; gap: 0.5rem;">
                <span style="font-size: 1.25rem;">✓</span>
                <span>ハラール認証</span>
              </div>
            <% end %>
            
            <% if @product.organic_certified %>
              <div class="cert-badge" style="background: #20c997; color: white; padding: 0.75rem 1.5rem; border-radius: 2rem; font-weight: 600; display: inline-flex; align-items: center; gap: 0.5rem;">
                <span style="font-size: 1.25rem;">🌿</span>
                <span>オーガニック認証</span>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <!-- アレルギー情報 -->
      <% if @product.allergens.present? %>
        <div class="allergen-warning" style="background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%); padding: 1.5rem; border-radius: 0.75rem; margin-bottom: 2rem; border: 2px solid #ffc107; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
          <h4 style="margin: 0 0 1rem 0; font-size: 1.25rem; font-weight: 600; color: #856404; display: flex; align-items: center; gap: 0.5rem;">
            <span style="font-size: 1.5rem;">⚠️</span>
            <span>アレルギー情報</span>
          </h4>
          <div style="font-size: 1rem; color: #856404; line-height: 1.6;">
            <%= simple_format(@product.allergens) %>
          </div>
          <p style="margin: 1rem 0 0 0; font-size: 0.875rem; color: #856404; font-style: italic;">
            ※ アレルギーをお持ちの方は、必ず成分表示をご確認ください。
          </p>
        </div>
      <% end %>

      <!-- 栄養成分表 -->
      <% if @product.nutritional_info.present? && @product.nutritional_info.any? %>
        <div class="nutrition-facts" style="background: white; padding: 1.5rem; border-radius: 0.75rem; margin-bottom: 2rem; border: 1px solid #dee2e6;">
          <h4 style="margin: 0 0 1rem 0; font-size: 1.25rem; font-weight: 600; color: #333;">📊 栄養成分（100gあたり）</h4>
          <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 1rem;">
            <% if @product.calories.present? %>
              <div style="text-align: center; padding: 0.75rem; background: #f8f9fa; border-radius: 0.5rem;">
                <div style="font-size: 1.75rem; font-weight: bold; color: #667eea;"><%= @product.calories %></div>
                <div style="font-size: 0.875rem; color: #666; margin-top: 0.25rem;">kcal</div>
              </div>
            <% end %>
            
            <% if @product.protein.present? %>
              <div style="text-align: center; padding: 0.75rem; background: #f8f9fa; border-radius: 0.5rem;">
                <div style="font-size: 1.75rem; font-weight: bold; color: #28a745;"><%= @product.protein %></div>
                <div style="font-size: 0.875rem; color: #666; margin-top: 0.25rem;">タンパク質 (g)</div>
              </div>
            <% end %>
            
            <% if @product.fat.present? %>
              <div style="text-align: center; padding: 0.75rem; background: #f8f9fa; border-radius: 0.5rem;">
                <div style="font-size: 1.75rem; font-weight: bold; color: #ffc107;"><%= @product.fat %></div>
                <div style="font-size: 0.875rem; color: #666; margin-top: 0.25rem;">脂質 (g)</div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- 調理方法 -->
      <% if @product.cooking_instructions.present? %>
        <div class="cooking-instructions" style="background: white; padding: 1.5rem; border-radius: 0.75rem; margin-bottom: 2rem; border: 1px solid #dee2e6;">
          <h4 style="margin: 0 0 1rem 0; font-size: 1.25rem; font-weight: 600; color: #333; display: flex; align-items: center; gap: 0.5rem;">
            <span style="font-size: 1.5rem;">🍳</span>
            <span>調理方法</span>
          </h4>
          <div style="font-size: 1rem; color: #555; line-height: 1.8;">
            <%= simple_format(@product.cooking_instructions) %>
          </div>
        </div>
      <% end %>

      <!-- 提供提案 -->
      <% if @product.serving_suggestions.present? %>
        <div class="serving-suggestions" style="background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%); padding: 1.5rem; border-radius: 0.75rem; border: 2px solid #2196f3;">
          <h4 style="margin: 0 0 1rem 0; font-size: 1.25rem; font-weight: 600; color: #1565c0; display: flex; align-items: center; gap: 0.5rem;">
            <span style="font-size: 1.5rem;">🌟</span>
            <span>おすすめの食べ方</span>
          </h4>
          <div style="font-size: 1rem; color: #1565c0; line-height: 1.8;">
            <%= simple_format(@product.serving_suggestions) %>
          </div>
        </div>
      <% end %>

    </div>
  HTML
)
