# 注文編集画面に冷凍食品配送管理セクションを追加
Deface::Override.new(
  virtual_path: 'spree/admin/orders/_form',
  name: 'add_frozen_delivery_management',
  insert_after: '[data-hook="admin_order_form_fields"]',
  text: <<-HTML
    <% if @order.persisted? %>
      <fieldset id="frozen-delivery-management" data-hook="frozen_delivery_management">
        <legend class="legend">
          🧊 冷凍食品配送管理
        </legend>
        
        <%= form_for [:admin, @order], html: { id: 'frozen-delivery-form' } do |f| %>
          <div class="row">
            <!-- 配送希望日時 -->
            <div class="col-md-6">
              <div class="field">
                <%= f.label :preferred_delivery_date, '配送希望日' %>
                <%= f.date_field :preferred_delivery_date, 
                    class: 'form-control',
                    value: @order.preferred_delivery_date&.strftime('%Y-%m-%d') %>
                <% if @order.preferred_delivery_date %>
                  <small class="form-text text-muted">
                    <% days_until = (@order.preferred_delivery_date.to_date - Date.today).to_i %>
                    <% if days_until == 0 %>
                      <span class="badge badge-danger">本日配送予定</span>
                    <% elsif days_until == 1 %>
                      <span class="badge badge-warning">明日配送予定</span>
                    <% elsif days_until < 0 %>
                      <span class="badge badge-secondary">期限超過 (<%= days_until.abs %>日前)</span>
                    <% else %>
                      残り<%= days_until %>日
                    <% end %>
                  </small>
                <% end %>
              </div>
            </div>
            
            <div class="col-md-6">
              <div class="field">
                <%= f.label :preferred_delivery_time, '配送時間帯' %>
                <%= f.select :preferred_delivery_time,
                    Spree::Order::DELIVERY_TIME_SLOTS,
                    { include_blank: '指定なし' },
                    class: 'form-control' %>
              </div>
            </div>
          </div>
          
          <div class="row mt-3">
            <!-- 配送業者・再配達 -->
            <div class="col-md-4">
              <div class="field">
                <%= f.label :carrier_code, '配送業者' %>
                <%= f.select :carrier_code,
                    Spree::Order::CARRIER_CODES.map { |k, v| [v, k] },
                    { include_blank: '未選択' },
                    class: 'form-control' %>
              </div>
            </div>
            
            <div class="col-md-4">
              <div class="field">
                <%= f.label :tracking_url, '追跡URL' %>
                <%= f.text_field :tracking_url, class: 'form-control' %>
                <% if @order.tracking_url.present? %>
                  <small class="form-text">
                    <%= link_to '追跡ページを開く', @order.tracking_url, 
                        target: '_blank', class: 'btn btn-sm btn-info mt-1' %>
                  </small>
                <% end %>
              </div>
            </div>
            
            <div class="col-md-4">
              <div class="field">
                <%= f.label :redelivery_count, '再配達回数' %>
                <%= f.number_field :redelivery_count, 
                    class: 'form-control', 
                    min: 0,
                    value: @order.redelivery_count || 0 %>
                <% if @order.redelivery_count.to_i > 0 %>
                  <small class="text-warning">⚠️ 再配達が発生しています</small>
                <% end %>
              </div>
            </div>
          </div>
          
          <!-- ピッキング管理 -->
          <div class="row mt-3">
            <div class="col-md-12">
              <h5>ピッキング状態</h5>
              <div class="card">
                <div class="card-body">
                  <div class="row">
                    <div class="col-md-4">
                      <strong>開始:</strong>
                      <% if @order.picking_started_at %>
                        <span class="badge badge-info">
                          <%= @order.picking_started_at.strftime('%Y/%m/%d %H:%M') %>
                        </span>
                      <% else %>
                        <span class="text-muted">未着手</span>
                      <% end %>
                    </div>
                    
                    <div class="col-md-4">
                      <strong>完了:</strong>
                      <% if @order.picking_completed_at %>
                        <span class="badge badge-success">
                          ✓ <%= @order.picking_completed_at.strftime('%Y/%m/%d %H:%M') %>
                        </span>
                      <% else %>
                        <span class="text-muted">未完了</span>
                      <% end %>
                    </div>
                    
                    <div class="col-md-4">
                      <% if @order.picking_inspector_name %>
                        <strong>検品者:</strong> <%= @order.picking_inspector_name %>
                      <% end %>
                    </div>
                  </div>
                  
                  <div class="mt-3">
                    <% unless @order.picking_completed_at %>
                      <button type="button" id="mark-picking-complete" class="btn btn-success">
                        ✓ ピッキング完了を記録
                      </button>
                    <% else %>
                      <span class="badge badge-success">ピッキング完了済み</span>
                      <% if @order.ready_to_ship? %>
                        <span class="badge badge-primary ml-2">🚚 出荷可能</span>
                      <% end %>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- 温度管理 -->
          <div class="row mt-3">
            <div class="col-md-12">
              <h5>温度管理</h5>
              <div class="card">
                <div class="card-body">
                  <div class="row">
                    <div class="col-md-3">
                      <div class="field">
                        <%= f.label :packing_temperature, '梱包時温度 (℃)' %>
                        <%= f.number_field :packing_temperature, 
                            class: 'form-control', 
                            step: 0.1,
                            placeholder: '-18.0' %>
                      </div>
                    </div>
                    
                    <div class="col-md-3">
                      <div class="field">
                        <%= f.label :ice_pack_count, '保冷剤数' %>
                        <%= f.number_field :ice_pack_count, 
                            class: 'form-control', 
                            min: 0,
                            readonly: true %>
                        <small class="form-text text-muted">自動計算</small>
                      </div>
                    </div>
                    
                    <div class="col-md-3">
                      <div class="form-check mt-4">
                        <%= f.check_box :temperature_alert, class: 'form-check-input' %>
                        <%= f.label :temperature_alert, '温度異常アラート', class: 'form-check-label' %>
                      </div>
                    </div>
                    
                    <div class="col-md-3">
                      <div class="form-check mt-4">
                        <%= f.check_box :temperature_controlled, class: 'form-check-input' %>
                        <%= f.label :temperature_controlled, '温度管理必須', class: 'form-check-label' %>
                      </div>
                    </div>
                  </div>
                  
                  <% if @order.temperature_alert? %>
                    <div class="alert alert-danger mt-3">
                      ⚠️ 温度異常が検知されています！
                      <% if @order.packing_temperature.present? %>
                        (現在温度: <%= @order.packing_temperature %>℃)
                      <% end %>
                    </div>
                  <% elsif @order.packing_temperature.present? && @order.packing_temperature <= -15 %>
                    <div class="alert alert-success mt-3">
                      ✓ 適正温度範囲内です (現在温度: <%= @order.packing_temperature %>℃)
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
          
          <!-- 備考 -->
          <div class="row mt-3">
            <div class="col-md-6">
              <div class="field">
                <%= f.label :packing_note, '梱包メモ' %>
                <%= f.text_area :packing_note, 
                    class: 'form-control', 
                    rows: 3,
                    placeholder: '梱包時の特記事項' %>
              </div>
            </div>
            
            <div class="col-md-6">
              <div class="field">
                <%= f.label :delivery_note, '配送メモ' %>
                <%= f.text_area :delivery_note, 
                    class: 'form-control', 
                    rows: 3,
                    placeholder: '配送時の注意事項' %>
              </div>
            </div>
          </div>
          
          <div class="form-actions mt-3">
            <%= f.submit '冷凍配送情報を更新', class: 'btn btn-primary' %>
          </div>
        <% end %>
      </fieldset>
      
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          // ピッキング完了ボタン
          const pickingBtn = document.getElementById('mark-picking-complete');
          if (pickingBtn) {
            pickingBtn.addEventListener('click', function() {
              const inspectorName = prompt('検品者名を入力してください:');
              if (inspectorName) {
                fetch('/admin/orders/<%= @order.number %>/mark_picking_complete', {
                  method: 'POST',
                  headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
                  },
                  body: JSON.stringify({ inspector_name: inspectorName })
                })
                .then(response => response.json())
                .then(data => {
                  if (data.success) {
                    alert('ピッキング完了を記録しました');
                    location.reload();
                  } else {
                    alert('エラー: ' + (data.error || '記録に失敗しました'));
                  }
                })
                .catch(err => {
                  alert('エラーが発生しました: ' + err.message);
                });
              }
            });
          }
        });
      </script>
      
      <style>
        #frozen-delivery-management {
          margin-top: 2rem;
          padding: 1.5rem;
          background-color: #f8f9fa;
          border-radius: 8px;
        }
        
        #frozen-delivery-management .legend {
          font-size: 1.2rem;
          font-weight: bold;
          color: #2c5aa0;
        }
        
        #frozen-delivery-management .card {
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        #frozen-delivery-management .field {
          margin-bottom: 1rem;
        }
      </style>
    <% end %>
  HTML
)
