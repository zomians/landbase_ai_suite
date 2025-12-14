// 再注文機能を制御するStimulus Controller
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    orderId: Number
  }

  confirm(event) {
    event.preventDefault()
    
    if (confirm('この注文の商品をカートに追加しますか？')) {
      this.reorder()
    }
  }

  async reorder() {
    try {
      const response = await fetch(`/orders/${this.orderIdValue}/reorder`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      if (response.ok) {
        const data = await response.json()
        alert('商品をカートに追加しました！')
        window.location.href = '/cart'
      } else {
        const error = await response.json()
        alert(`エラー: ${error.message || '再注文に失敗しました'}`)
      }
    } catch (error) {
      console.error('Reorder error:', error)
      alert('再注文処理中にエラーが発生しました')
    }
  }
}
