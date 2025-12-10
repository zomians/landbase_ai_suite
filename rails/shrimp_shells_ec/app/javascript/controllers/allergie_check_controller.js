import { Controller } from "@hotwired/stimulus"

// アレルギー確認チェックボックスのコントローラー
export default class extends Controller {
  connect() {
    this.updateCheckoutButton()
  }

  validate(event) {
    this.updateCheckoutButton()
  }

  updateCheckoutButton() {
    const checkoutButton = document.getElementById('checkout-link')
    if (!checkoutButton) return

    if (this.element.checked) {
      checkoutButton.disabled = false
      checkoutButton.classList.remove('opacity-50', 'cursor-not-allowed')
    } else {
      checkoutButton.disabled = true
      checkoutButton.classList.add('opacity-50', 'cursor-not-allowed')
    }
  }
}
