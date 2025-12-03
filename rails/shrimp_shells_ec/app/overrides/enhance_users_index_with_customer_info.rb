# 顧客一覧画面に冷凍食品EC顧客管理情報を追加
Deface::Override.new(
  virtual_path: 'spree/admin/users/index',
  name: 'add_customer_management_columns',
  replace: 'thead tr[data-hook="admin_users_index_headers"]',
  text: <<-HTML
    <tr data-hook="admin_users_index_headers">
      <th><%= sort_link @search, :email, Spree.user_class.human_attribute_name(:email), {title: 'users_email_title'} %></th>
      <th>顧客ランク</th>
      <th class="align-center">購入回数</th>
      <th class="align-center">総購入額</th>
      <th class="align-center">平均購入額</th>
      <th class="align-center">最終購入日</th>
      <th class="align-center">ステータス</th>
      <th><%= Spree.user_class.human_attribute_name(:spree_roles) %></th>
      <th class="align-center"><%= sort_link @search, :created_at, t('spree.member_since') %></th>
      <th data-hook="admin_users_index_header_actions" class="actions"></th>
    </tr>
  HTML
)

# 顧客行データにカスタム情報を追加
Deface::Override.new(
  virtual_path: 'spree/admin/users/index',
  name: 'add_customer_management_data',
  replace: 'tbody',
  text: <<-HTML
    <tbody>
      <% @users.each do |user| %>
        <tr id="<%= spree_dom_id user %>" data-hook="admin_users_index_rows" class="customer-row">
          <td class='user_email'><%= link_to user.email, edit_admin_user_url(user) %></td>
          
          <!-- 顧客ランク -->
          <td class="customer-rank-cell">
            <% if user.customer_rank.present? %>
              <span class="badge badge-<%= user.customer_rank %>">
                <%= user.status_badge %>
              </span>
              <% if user.vip_flag? %>
                <span class="badge badge-warning ml-1">⭐️ VIP</span>
              <% end %>
            <% else %>
              <span class="text-muted">未設定</span>
            <% end %>
          </td>
          
          <!-- 購入回数 -->
          <td class="align-center">
            <%= link_to user.total_purchase_count || 0, spree.orders_admin_user_path(user) %>
            <% if user.total_purchase_count.to_i > 10 %>
              <span class="badge badge-info ml-1">🔥</span>
            <% end %>
          </td>
          
          <!-- 総購入額 -->
          <td class="align-center">
            <strong><%= number_to_currency(user.total_purchase_amount || 0, unit: '¥', precision: 0) %></strong>
            <% if user.total_purchase_amount.to_f >= 100000 %>
              <br><span class="badge badge-success">高額顧客</span>
            <% end %>
          </td>
          
          <!-- 平均購入額 -->
          <td class="align-center">
            <%= number_to_currency(user.average_purchase_amount, unit: '¥', precision: 0) %>
          </td>
          
          <!-- 最終購入日 -->
          <td class="align-center">
            <% if user.last_purchase_date %>
              <%= l user.last_purchase_date %>
              <br>
              <small class="text-muted">
                <% days = user.days_since_last_purchase %>
                <% if days == 0 %>
                  <span class="badge badge-success">本日</span>
                <% elsif days <= 7 %>
                  <%= days %>日前
                <% elsif days <= 30 %>
                  <span class="text-success"><%= days %>日前</span>
                <% elsif days <= 90 %>
                  <span class="text-warning"><%= days %>日前</span>
                <% else %>
                  <span class="badge badge-danger">休眠 (<%= days %>日)</span>
                <% end %>
              </small>
            <% else %>
              <span class="text-muted">未購入</span>
            <% end %>
          </td>
          
          <!-- ステータス -->
          <td class="align-center">
            <% if user.attention_flag? %>
              <span class="badge badge-danger">⚠️ 要注意</span>
            <% end %>
            <% if user.allergies.present? %>
              <span class="badge badge-warning" title="<%= user.allergies %>">🚫 アレルギー</span>
            <% end %>
            <% if user.newsletter_subscribed? %>
              <span class="badge badge-info">📧</span>
            <% end %>
            <% if user.dormant? %>
              <span class="badge badge-secondary">💤</span>
            <% elsif user.active? %>
              <span class="badge badge-success">✓</span>
            <% end %>
          </td>
          
          <!-- ロール -->
          <td><%= user.spree_roles.map(&:name).to_sentence %></td>
          
          <!-- 登録日 -->
          <td class="align-center"><%= l user.created_at.to_date %></td>
          
          <!-- アクション -->
          <td data-hook="admin_users_index_row_actions" class="actions">
            <% if can?(:edit, user) %>
              <%= link_to_edit user, no_text: true, url: spree.admin_user_path(user) %>
            <% end %>
            <% if can?(:destroy, user) && user.can_be_deleted? %>
              <%= link_to_delete user, no_text: true, url: spree.admin_user_path(user) %>
            <% end %>
          </td>
        </tr>
      <% end %>
    </tbody>
    
    <style>
      .badge-bronze { background-color: #cd7f32; color: white; }
      .badge-silver { background-color: #c0c0c0; color: #333; }
      .badge-gold { background-color: #ffd700; color: #333; }
      .badge-platinum { background-color: #e5e4e2; color: #333; font-weight: bold; }
      
      .customer-row .badge {
        font-size: 0.85em;
        padding: 0.3em 0.5em;
      }
      
      .customer-rank-cell {
        white-space: nowrap;
      }
    </style>
  HTML
)

# 検索フォームにカスタムフィルターを追加
Deface::Override.new(
  virtual_path: 'spree/admin/users/index',
  name: 'add_customer_filters',
  insert_after: '[data-hook="admin_users_index_search"] .row',
  text: <<-HTML
    <div class="row mt-3">
      <div class="col-md-3">
        <div class="form-group">
          <%= label_tag :customer_rank_filter, '顧客ランク' %>
          <%= select_tag :customer_rank_filter, 
              options_for_select([
                ['すべて', ''],
                ['ブロンズ', 'bronze'],
                ['シルバー', 'silver'],
                ['ゴールド', 'gold'],
                ['プラチナ', 'platinum']
              ], params[:customer_rank_filter]),
              class: 'form-control',
              onchange: 'this.form.submit()' %>
        </div>
      </div>
      
      <div class="col-md-3">
        <div class="form-group">
          <%= label_tag :customer_status_filter, '顧客ステータス' %>
          <%= select_tag :customer_status_filter,
              options_for_select([
                ['すべて', ''],
                ['アクティブ (30日以内)', 'active'],
                ['休眠顧客 (90日以上)', 'dormant'],
                ['VIP顧客', 'vip'],
                ['要注意顧客', 'attention'],
                ['高額購入者 (10万円以上)', 'high_value']
              ], params[:customer_status_filter]),
              class: 'form-control',
              onchange: 'this.form.submit()' %>
        </div>
      </div>
      
      <div class="col-md-3">
        <div class="form-group">
          <%= label_tag :marketing_filter, 'マーケティング' %>
          <%= select_tag :marketing_filter,
              options_for_select([
                ['すべて', ''],
                ['DM送信可', 'dm_allowed'],
                ['メルマガ購読中', 'newsletter'],
                ['マーケティング可能', 'marketable']
              ], params[:marketing_filter]),
              class: 'form-control',
              onchange: 'this.form.submit()' %>
        </div>
      </div>
      
      <div class="col-md-3">
        <div class="form-group">
          <%= label_tag :allergy_filter, 'アレルギー' %>
          <%= select_tag :allergy_filter,
              options_for_select([
                ['すべて', ''],
                ['アレルギー情報あり', 'has_allergies'],
                ['アレルギー情報なし', 'no_allergies']
              ], params[:allergy_filter]),
              class: 'form-control',
              onchange: 'this.form.submit()' %>
        </div>
      </div>
    </div>
  HTML
)
