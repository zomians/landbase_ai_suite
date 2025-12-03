# ユーザー編集画面に顧客管理情報セクションを追加
Deface::Override.new(
  virtual_path: 'spree/admin/users/edit',
  name: 'add_customer_management_section',
  insert_after: 'fieldset[data-hook="admin_user_edit_general_settings"]',
  text: <<-HTML
    <% if @user.persisted? %>
      <!-- 購入統計セクション -->
      <fieldset id="customer-purchase-stats" class="no-border-bottom">
        <legend>📊 購入統計・顧客ランク</legend>
        
        <div class="row">
          <div class="col-md-3">
            <div class="stat-card bg-primary text-white">
              <h4><%= @user.total_purchase_count || 0 %> 回</h4>
              <p>総購入回数</p>
            </div>
          </div>
          
          <div class="col-md-3">
            <div class="stat-card bg-success text-white">
              <h4><%= number_to_currency(@user.total_purchase_amount || 0, unit: '¥', precision: 0) %></h4>
              <p>総購入額 (LTV)</p>
            </div>
          </div>
          
          <div class="col-md-3">
            <div class="stat-card bg-info text-white">
              <h4><%= number_to_currency(@user.average_purchase_amount, unit: '¥', precision: 0) %></h4>
              <p>平均購入額</p>
            </div>
          </div>
          
          <div class="col-md-3">
            <div class="stat-card bg-warning text-dark">
              <h4><%= @user.customer_rank_name %></h4>
              <p>顧客ランク</p>
              <% if @user.amount_to_next_rank > 0 %>
                <small>次のランクまで<br><%= number_to_currency(@user.amount_to_next_rank, unit: '¥', precision: 0) %></small>
              <% end %>
            </div>
          </div>
        </div>
        
        <div class="row mt-3">
          <div class="col-md-12">
            <% if @user.last_purchase_date %>
              <p>
                <strong>最終購入日:</strong> <%= l @user.last_purchase_date %> 
                <span class="badge badge-<%= @user.active? ? 'success' : (@user.dormant? ? 'danger' : 'warning') %>">
                  <%= @user.days_since_last_purchase %>日前
                  <% if @user.active? %>
                    (アクティブ)
                  <% elsif @user.dormant? %>
                    (休眠)
                  <% end %>
                </span>
              </p>
            <% else %>
              <p class="text-muted">まだ購入履歴がありません</p>
            <% end %>
          </div>
        </div>
      </fieldset>
      
      <!-- 顧客情報管理フォーム -->
      <fieldset id="customer-management-form">
        <legend>👤 顧客情報管理</legend>
        
        <%= form_for [:admin, @user], url: admin_user_url(@user), method: :put do |f| %>
          <div class="row">
            <!-- 基本情報 -->
            <div class="col-md-6">
              <h5>基本情報</h5>
              
              <div class="field">
                <%= f.label :gender, '性別' %>
                <%= f.select :gender,
                    Spree::User::GENDERS.map { |k, v| [v, k] },
                    { include_blank: '未指定' },
                    class: 'form-control' %>
              </div>
              
              <div class="field">
                <%= f.label :birth_date, '生年月日' %>
                <%= f.date_field :birth_date, class: 'form-control' %>
                <% if @user.age %>
                  <small class="form-text text-muted">年齢: <%= @user.age %>歳 (<%= @user.age_group %>)</small>
                <% end %>
              </div>
              
              <div class="field">
                <%= f.label :phone_number, '電話番号' %>
                <%= f.text_field :phone_number, class: 'form-control' %>
              </div>
              
              <div class="field">
                <%= f.label :company_name, '会社名（法人の場合）' %>
                <%= f.text_field :company_name, class: 'form-control' %>
              </div>
            </div>
            
            <!-- 顧客ランク・ステータス -->
            <div class="col-md-6">
              <h5>ランク・ステータス</h5>
              
              <div class="field">
                <%= f.label :customer_rank, '顧客ランク' %>
                <%= f.select :customer_rank,
                    Spree::User::CUSTOMER_RANKS.map { |k, v| [v, k] },
                    {},
                    class: 'form-control' %>
                <small class="form-text text-muted">※通常は購入額に応じて自動設定されます</small>
              </div>
              
              <div class="form-check mt-3">
                <%= f.check_box :vip_flag, class: 'form-check-input' %>
                <%= f.label :vip_flag, '⭐️ VIP顧客フラグ', class: 'form-check-label' %>
                <small class="form-text text-muted">特別対応が必要な重要顧客</small>
              </div>
              
              <div class="form-check mt-2">
                <%= f.check_box :attention_flag, class: 'form-check-input' %>
                <%= f.label :attention_flag, '⚠️ 要注意顧客フラグ', class: 'form-check-label' %>
                <small class="form-text text-muted">クレーム履歴や特別な注意が必要</small>
              </div>
              
              <div class="field mt-3">
                <%= f.label :customer_memo, '顧客メモ' %>
                <%= f.text_area :customer_memo, 
                    class: 'form-control', 
                    rows: 4,
                    placeholder: '顧客対応の特記事項など' %>
              </div>
            </div>
          </div>
          
          <hr class="my-4">
          
          <div class="row">
            <!-- アレルギー情報 -->
            <div class="col-md-6">
              <h5>🚫 アレルギー情報</h5>
              
              <div class="field">
                <%= f.label :allergies, 'アレルギー食材' %>
                <%= f.text_area :allergies, 
                    class: 'form-control', 
                    rows: 3,
                    placeholder: '例: えび、かに、小麦' %>
                <small class="form-text text-warning">
                  ⚠️ 重要: 冷凍食品発送時に必ず確認してください
                </small>
              </div>
              
              <div class="field">
                <%= f.label :dietary_restrictions, '食事制限' %>
                <%= f.text_area :dietary_restrictions, 
                    class: 'form-control', 
                    rows: 2,
                    placeholder: '例: ベジタリアン、ハラル、グルテンフリー' %>
              </div>
            </div>
            
            <!-- マーケティング設定 -->
            <div class="col-md-6">
              <h5>📧 マーケティング設定</h5>
              
              <div class="form-check">
                <%= f.check_box :dm_allowed, class: 'form-check-input' %>
                <%= f.label :dm_allowed, 'DM送信許可', class: 'form-check-label' %>
              </div>
              
              <div class="form-check mt-2">
                <%= f.check_box :newsletter_subscribed, class: 'form-check-input' %>
                <%= f.label :newsletter_subscribed, 'メールマガジン購読', class: 'form-check-label' %>
              </div>
              
              <div class="alert alert-info mt-3">
                <strong>マーケティング可否:</strong>
                <% if @user.marketable? %>
                  <span class="badge badge-success">✓ 送信可能</span>
                <% else %>
                  <span class="badge badge-danger">✗ 送信不可</span>
                  <% if @user.attention_flag? %>
                    <br><small>要注意顧客のためマーケティング対象外</small>
                  <% end %>
                <% end %>
              </div>
            </div>
          </div>
          
          <hr class="my-4">
          
          <div class="row">
            <!-- SNS・外部連携 -->
            <div class="col-md-6">
              <h5>🔗 SNS・外部連携</h5>
              
              <div class="field">
                <%= f.label :instagram_handle, 'Instagram ID' %>
                <div class="input-group">
                  <div class="input-group-prepend">
                    <span class="input-group-text">@</span>
                  </div>
                  <%= f.text_field :instagram_handle, class: 'form-control' %>
                </div>
              </div>
              
              <div class="field">
                <%= f.label :line_user_id, 'LINE ユーザーID' %>
                <%= f.text_field :line_user_id, class: 'form-control' %>
              </div>
            </div>
            
            <!-- 配送設定 -->
            <div class="col-md-6">
              <h5>🚚 配送設定</h5>
              
              <div class="field">
                <%= f.label :preferred_carrier, '希望配送業者' %>
                <%= f.select :preferred_carrier,
                    [
                      ['指定なし', ''],
                      ['ヤマト運輸', 'yamato'],
                      ['佐川急便', 'sagawa'],
                      ['日本郵便', 'japan_post'],
                      ['西濃運輸', 'seino']
                    ],
                    {},
                    class: 'form-control' %>
              </div>
              
              <div class="field">
                <%= f.label :preferred_delivery_time, '希望配送時間帯' %>
                <%= f.select :preferred_delivery_time,
                    Spree::Order::DELIVERY_TIME_SLOTS,
                    { include_blank: '指定なし' },
                    class: 'form-control' %>
              </div>
              
              <div class="field">
                <%= f.label :delivery_memo, '配送メモ' %>
                <%= f.text_area :delivery_memo, 
                    class: 'form-control', 
                    rows: 2,
                    placeholder: '例: 不在時は宅配ボックスに' %>
              </div>
            </div>
          </div>
          
          <div class="form-actions mt-4">
            <%= f.submit '顧客情報を更新', class: 'btn btn-primary btn-lg' %>
          </div>
        <% end %>
      </fieldset>
      
      <style>
        .stat-card {
          padding: 20px;
          border-radius: 8px;
          text-align: center;
          margin-bottom: 15px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .stat-card h4 {
          font-size: 2rem;
          font-weight: bold;
          margin-bottom: 5px;
        }
        
        .stat-card p {
          margin: 0;
          font-size: 0.9rem;
        }
        
        .stat-card small {
          font-size: 0.75rem;
          opacity: 0.9;
        }
        
        #customer-management-form fieldset {
          background-color: #f8f9fa;
          padding: 2rem;
          border-radius: 8px;
          margin-top: 2rem;
        }
        
        #customer-management-form .field {
          margin-bottom: 1.5rem;
        }
        
        #customer-management-form h5 {
          color: #2c5aa0;
          font-weight: bold;
          margin-bottom: 1rem;
          padding-bottom: 0.5rem;
          border-bottom: 2px solid #e0e0e0;
        }
      </style>
    <% end %>
  HTML
)
