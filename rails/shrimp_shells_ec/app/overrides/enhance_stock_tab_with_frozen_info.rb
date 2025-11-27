# 在庫テーブルのヘッダーに冷凍食品情報列を追加
Deface::Override.new(
  virtual_path: 'spree/admin/stock_items/_stock_management',
  name: 'add_frozen_headers',
  insert_before: 'th:contains("Actions")',
  text: '<th>冷凍食品情報</th>'
)

# JavaScriptで在庫行に冷凍食品情報を追加
Deface::Override.new(
  virtual_path: 'spree/admin/stock_items/_stock_management',
  name: 'add_frozen_stock_js',
  insert_bottom: "[id='listing_product_stock']",
  text: <<-HTML
    <script>
      document.addEventListener('DOMContentLoaded', function() {
        setTimeout(function() {
          // 在庫行に冷凍食品情報を追加
          document.querySelectorAll('.js-edit-stock-item').forEach(function(row) {
            try {
              const stockData = JSON.parse(row.dataset.stockItem || '{}');
              
              // 冷凍食品情報セルを作成
              const frozenCell = document.createElement('td');
              frozenCell.className = 'frozen-stock-info';
              
              let html = '<div style="font-size: 0.85em; line-height: 1.5;">';
              
              if (stockData.lot_number) {
                html += '<div><strong>ロット:</strong> <code>' + stockData.lot_number + '</code></div>';
              }
              
              if (stockData.expiry_date) {
                const expiryDate = new Date(stockData.expiry_date);
                const today = new Date();
                const daysLeft = Math.floor((expiryDate - today) / (1000 * 60 * 60 * 24));
                
                html += '<div><strong>期限:</strong> ' + expiryDate.toLocaleDateString('ja-JP');
                
                if (daysLeft < 0) {
                  html += ' <span class="badge badge-danger">期限切れ</span>';
                } else if (daysLeft <= 30) {
                  html += ' <span class="badge badge-warning">残' + daysLeft + '日</span>';
                }
                
                html += '</div>';
              }
              
              if (stockData.storage_temperature_actual) {
                html += '<div><strong>温度:</strong> ' + stockData.storage_temperature_actual + '℃</div>';
              }
              
              if (stockData.supplier_name) {
                html += '<div><strong>仕入先:</strong> ' + stockData.supplier_name + '</div>';
              }
              
              html += '</div>';
              frozenCell.innerHTML = html;
              
              // Actionsカラムの前に挿入
              const actionsCell = row.querySelector('td.actions');
              if (actionsCell) {
                row.insertBefore(frozenCell, actionsCell);
              }
            } catch (e) {
              console.error('Error adding frozen info:', e);
            }
          });
        }, 500);
      });
    </script>
  HTML
)

# 在庫編集モーダルに冷凍食品フィールドを追加
Deface::Override.new(
  virtual_path: 'spree/admin/stock_items/_stock_management',
  name: 'add_frozen_fields_to_stock_form',
  insert_bottom: "[id='listing_product_stock']",
  text: <<-HTML
    <style>
      .frozen-stock-details {
        font-size: 0.85em;
        line-height: 1.4;
      }
      .frozen-stock-details .badge {
        font-size: 0.8em;
        padding: 2px 6px;
      }
      .frozen-stock-fields {
        margin-top: 15px;
        padding: 15px;
        background: #f0f8ff;
        border: 1px solid #b0d4f1;
        border-radius: 4px;
      }
      .frozen-stock-fields h6 {
        color: #004085;
        margin-bottom: 10px;
      }
      .stock-lot-info {
        padding: 8px;
        vertical-align: top;
      }
    </style>
    
    <div id="frozen-stock-modal" class="modal fade" tabindex="-1">
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">🧊 在庫詳細編集</h5>
            <button type="button" class="close" data-dismiss="modal">&times;</button>
          </div>
          <div class="modal-body">
            <form id="frozen-stock-form">
              <input type="hidden" id="stock-item-id">
              
              <div class="form-group">
                <label>ロット番号</label>
                <input type="text" class="form-control" id="lot-number" placeholder="LOT-20251127-001">
              </div>
              
              <div class="row">
                <div class="col-md-6">
                  <div class="form-group">
                    <label>消費期限</label>
                    <input type="date" class="form-control" id="expiry-date">
                  </div>
                </div>
                <div class="col-md-6">
                  <div class="form-group">
                    <label>保管温度 (℃)</label>
                    <input type="number" class="form-control" id="storage-temp" step="0.1" placeholder="-18">
                  </div>
                </div>
              </div>
              
              <div class="row">
                <div class="col-md-6">
                  <div class="form-group">
                    <label>仕入先</label>
                    <input type="text" class="form-control" id="supplier-name" placeholder="株式会社〇〇水産">
                  </div>
                </div>
                <div class="col-md-6">
                  <div class="form-group">
                    <label>仕入価格 (円)</label>
                    <input type="number" class="form-control" id="purchase-price" step="0.01">
                  </div>
                </div>
              </div>
              
              <div class="form-group">
                <label>品質ステータス</label>
                <select class="form-control" id="quality-status">
                  <option value="">未設定</option>
                  <option value="good">✅ 良好</option>
                  <option value="warning">⚠️ 要確認</option>
                  <option value="discard">❌ 廃棄対象</option>
                </select>
              </div>
              
              <div class="form-group">
                <label>メモ</label>
                <textarea class="form-control" id="inventory-notes" rows="3"></textarea>
              </div>
            </form>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">キャンセル</button>
            <button type="button" class="btn btn-primary" onclick="saveFrozenStockData()">保存</button>
          </div>
        </div>
      </div>
    </div>
    
    <script>
      // 在庫行にダブルクリックで詳細編集モーダルを開く
      document.addEventListener('DOMContentLoaded', function() {
        setTimeout(function() {
          document.querySelectorAll('.js-edit-stock-item').forEach(function(row) {
            row.addEventListener('dblclick', function() {
              const stockData = JSON.parse(this.dataset.stockItem || '{}');
              openFrozenStockModal(stockData);
            });
          });
        }, 1000);
      });
      
      function openFrozenStockModal(stockData) {
        document.getElementById('stock-item-id').value = stockData.id;
        document.getElementById('lot-number').value = stockData.lot_number || '';
        document.getElementById('expiry-date').value = stockData.expiry_date || '';
        document.getElementById('storage-temp').value = stockData.storage_temperature_actual || '';
        document.getElementById('supplier-name').value = stockData.supplier_name || '';
        document.getElementById('purchase-price').value = stockData.purchase_price || '';
        document.getElementById('quality-status').value = stockData.quality_status || '';
        document.getElementById('inventory-notes').value = stockData.inventory_notes || '';
        
        $('#frozen-stock-modal').modal('show');
      }
      
      function saveFrozenStockData() {
        const stockItemId = document.getElementById('stock-item-id').value;
        const data = {
          stock_item: {
            lot_number: document.getElementById('lot-number').value,
            expiry_date: document.getElementById('expiry-date').value,
            storage_temperature_actual: document.getElementById('storage-temp').value,
            supplier_name: document.getElementById('supplier-name').value,
            purchase_price: document.getElementById('purchase-price').value,
            quality_status: document.getElementById('quality-status').value,
            inventory_notes: document.getElementById('inventory-notes').value
          }
        };
        
        fetch(`/admin/stock_items/${stockItemId}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
          },
          body: JSON.stringify(data)
        })
        .then(response => response.json())
        .then(data => {
          $('#frozen-stock-modal').modal('hide');
          location.reload();
        })
        .catch(error => {
          alert('保存に失敗しました: ' + error);
        });
      }
    </script>
  HTML
)
