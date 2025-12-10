import { Controller } from "@hotwired/stimulus"

// 配送希望日のバリデーションコントローラー
export default class extends Controller {
  connect() {
    this.validateDate()
  }

  validateDate() {
    const dateInput = this.element
    const selectedDate = new Date(dateInput.value)
    const minDate = new Date()
    minDate.setDate(minDate.getDate() + 2) // 2日後
    minDate.setHours(0, 0, 0, 0)

    if (selectedDate < minDate) {
      dateInput.setCustomValidity('配送希望日は注文日の2日後以降を選択してください')
      this.showError('配送希望日は注文日の2日後以降を選択してください')
    } else {
      dateInput.setCustomValidity('')
      this.clearError()
    }
  }

  showError(message) {
    let errorElement = this.element.parentElement.querySelector('.error-message')
    if (!errorElement) {
      errorElement = document.createElement('p')
      errorElement.className = 'error-message text-red-500 text-xs mt-1'
      this.element.parentElement.appendChild(errorElement)
    }
    errorElement.textContent = message
    this.element.classList.add('border-red-500')
  }

  clearError() {
    const errorElement = this.element.parentElement.querySelector('.error-message')
    if (errorElement) {
      errorElement.remove()
    }
    this.element.classList.remove('border-red-500')
  }
}
