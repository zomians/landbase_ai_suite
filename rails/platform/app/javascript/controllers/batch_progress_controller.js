import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loading", "error", "errorMessage", "result", "resultContent"]
  static values = {
    batchId: Number,
    sourceType: String,
    clientCode: String,
    statusUrl: String,
    status: String
  }

  connect() {
    this.pollCount = 0
    this.maxPolls = 300
    this.pollInterval = 3000

    if (!this.statusUrlValue) return

    if (this.statusValue === "completed") {
      this.fetchAndShowResult()
    } else if (this.statusValue === "processing") {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.timer = setInterval(() => this.poll(), this.pollInterval)
  }

  stopPolling() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  async poll() {
    this.pollCount++
    if (this.pollCount > this.maxPolls) {
      this.stopPolling()
      this.showError("処理がタイムアウトしました。しばらく待ってからページを再読み込みしてください。")
      return
    }

    try {
      const response = await fetch(this.statusUrlValue)
      const data = await response.json()

      if (data.status === "completed") {
        this.stopPolling()
        this.showResult(data)
        return
      }

      if (data.status === "failed") {
        this.stopPolling()
        this.showError(data.error_message || "処理に失敗しました。")
        return
      }
    } catch (error) {
      console.warn("Polling error:", error.message)
    }
  }

  async fetchAndShowResult() {
    try {
      const response = await fetch(this.statusUrlValue)
      const data = await response.json()
      this.showResult(data)
    } catch (error) {
      console.warn("Fetch error:", error.message)
    }
  }

  showError(message) {
    this.loadingTarget.classList.add("hidden")
    this.errorMessageTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  showResult(data) {
    this.loadingTarget.classList.add("hidden")
    this.resultTarget.classList.remove("hidden")

    const summary = data.summary || {}
    const clientCode = this.clientCodeValue
    const sourceType = this.sourceTypeValue
    let html = ""

    html += `<div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">`
    html += this.statCard(String(summary.total_transactions || 0), "取引件数", "text-blue-600")

    if (sourceType === "bank") {
      html += this.statCard(String((summary.total_withdrawals || 0).toLocaleString()) + "円", "出金合計", "text-red-600")
      html += this.statCard(String((summary.total_deposits || 0).toLocaleString()) + "円", "入金合計", "text-green-600")
    } else {
      html += this.statCard(String((summary.total_amount || 0).toLocaleString()) + "円", "合計金額", "text-blue-600")
      html += this.statCard(String(data.journal_entries_count || 0), "仕訳登録数", "text-green-600")
    }

    html += this.statCard(String(summary.review_required_count || 0), "要確認", "text-yellow-600")
    html += `</div>`

    html += `<div class="flex gap-4">`
    html += `<a href="/journal_entries?client_code=${encodeURIComponent(clientCode)}&source_type=${encodeURIComponent(sourceType)}" class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 transition-colors">仕訳一覧を確認</a>`
    html += `<a href="/api/v1/journal_entries/export?client_code=${encodeURIComponent(clientCode)}&statement_batch_id=${data.id}" class="bg-gray-600 text-white px-4 py-2 rounded-md hover:bg-gray-700 transition-colors">CSVダウンロード</a>`
    html += `</div>`

    this.resultContentTarget.innerHTML = html
  }

  statCard(value, label, colorClass) {
    return `<div class="bg-white shadow rounded-lg p-4 text-center">` +
      `<p class="text-2xl font-bold ${colorClass}">${this.escapeHTML(value)}</p>` +
      `<p class="text-sm text-gray-500">${this.escapeHTML(label)}</p></div>`
  }

  escapeHTML(str) {
    if (!str) return ""
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
