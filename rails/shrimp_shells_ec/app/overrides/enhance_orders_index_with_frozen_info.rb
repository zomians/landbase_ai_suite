# 注文一覧画面に冷凍食品配送情報を追加
Deface::Override.new(
  virtual_path: 'spree/admin/orders/index',
  name: 'add_frozen_delivery_columns',
  insert_before: 'th:contains("Total")',
  text: <<-HTML
    <th>配送希望日</th>
    <th>時間帯</th>
    <th>ピッキング</th>
    <th>温度管理</th>
  HTML
)

# 注文行に冷凍食品配送情報を追加
Deface::Override.new(
  virtual_path: 'spree/admin/orders/index',
  name: 'add_frozen_delivery_data',
  insert_after: "[id='listing_orders']",
  text: <<-HTML
    <script>
      document.addEventListener('DOMContentLoaded', function() {
        setTimeout(function() {
          // 注文行を取得してカスタム情報を追加
          const orderRows = document.querySelectorAll('#listing_orders tbody tr');
          
          orderRows.forEach(function(row) {
            // 注文番号のリンクから注文IDを取得
            const orderLink = row.querySelector('td:first-child a');
            if (!orderLink) return;
            
            const orderId = orderLink.textContent.trim();
            
            // カスタム情報セルを作成（Totalの前に挿入）
            const totalCell = row.querySelector('td:nth-last-child(2)'); // Totalの前
            
            if (totalCell) {
              // 配送希望日セル
              const deliveryDateCell = document.createElement('td');
              deliveryDateCell.className = 'delivery-date-cell';
              deliveryDateCell.innerHTML = '<span class="text-muted">未設定</span>';
              
              // 時間帯セル
              const timeSlotCell = document.createElement('td');
              timeSlotCell.className = 'time-slot-cell';
              timeSlotCell.innerHTML = '<span class="text-muted">-</span>';
              
              // ピッキングセル
              const pickingCell = document.createElement('td');
              pickingCell.className = 'picking-cell text-center';
              pickingCell.innerHTML = '<span class="badge badge-secondary">未着手</span>';
              
              // 温度管理セル
              const tempCell = document.createElement('td');
              tempCell.className = 'temp-cell text-center';
              tempCell.innerHTML = '<span class="badge badge-info">🧊 冷凍</span>';
              
              // Totalセルの前に挿入
              totalCell.parentNode.insertBefore(deliveryDateCell, totalCell);
              totalCell.parentNode.insertBefore(timeSlotCell, totalCell);
              totalCell.parentNode.insertBefore(pickingCell, totalCell);
              totalCell.parentNode.insertBefore(tempCell, totalCell);
              
              // 注文詳細をAJAXで取得して更新
              fetch('/admin/orders/' + orderId + '.json')
                .then(response => response.json())
                .then(data => {
                  // 配送希望日
                  if (data.preferred_delivery_date) {
                    const deliveryDate = new Date(data.preferred_delivery_date);
                    const today = new Date();
                    const daysUntil = Math.floor((deliveryDate - today) / (1000 * 60 * 60 * 24));
                    
                    let dateHtml = deliveryDate.toLocaleDateString('ja-JP');
                    if (daysUntil === 0) {
                      dateHtml += ' <span class="badge badge-danger">本日</span>';
                    } else if (daysUntil === 1) {
                      dateHtml += ' <span class="badge badge-warning">明日</span>';
                    } else if (daysUntil < 0) {
                      dateHtml += ' <span class="badge badge-secondary">期限超過</span>';
                    }
                    
                    deliveryDateCell.innerHTML = dateHtml;
                  }
                  
                  // 時間帯
                  if (data.preferred_delivery_time) {
                    timeSlotCell.innerHTML = '<small>' + data.preferred_delivery_time + '</small>';
                  }
                  
                  // ピッキング状態
                  if (data.picking_completed_at) {
                    pickingCell.innerHTML = '<span class="badge badge-success">✓ 完了</span>';
                  } else if (data.picking_started_at) {
                    pickingCell.innerHTML = '<span class="badge badge-warning">作業中</span>';
                  } else if (data.state === 'complete') {
                    pickingCell.innerHTML = '<span class="badge badge-info">未着手</span>';
                  }
                  
                  // 温度管理
                  if (data.temperature_alert) {
                    tempCell.innerHTML = '<span class="badge badge-danger">⚠️ 異常</span>';
                  } else if (data.packing_temperature) {
                    tempCell.innerHTML = '<span class="badge badge-success">🧊 ' + data.packing_temperature + '℃</span>';
                  }
                })
                .catch(err => console.log('Order data load error:', err));
            }
          });
        }, 300);
      });
    </script>
    
    <style>
      .delivery-date-cell, .time-slot-cell {
        white-space: nowrap;
        font-size: 0.9em;
      }
      .picking-cell .badge, .temp-cell .badge {
        font-size: 0.85em;
        padding: 0.35em 0.6em;
      }
    </style>
  HTML
)
