import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form", "dropZone", "fileInput", "fileName",
    "submitButton", "loading", "error", "errorMessage",
    "result", "resultContent", "clientCode", "statementPeriod"
  ]

  connect() {
    this.file = null
  }

  openFileDialog() {
    this.fileInputTarget.click()
  }

  fileSelected(event) {
    const files = event.target.files
    if (files.length > 0) {
      this.setFile(files[0])
    }
  }

  dragOver(event) {
    event.preventDefault()
  }

  dragEnter(event) {
    event.preventDefault()
    this.dropZoneTarget.classList.add("border-blue-500", "bg-blue-50")
  }

  dragLeave(event) {
    event.preventDefault()
    this.dropZoneTarget.classList.remove("border-blue-500", "bg-blue-50")
  }

  drop(event) {
    event.preventDefault()
    this.dropZoneTarget.classList.remove("border-blue-500", "bg-blue-50")
    const files = Array.from(event.dataTransfer.files).filter(f =>
      f.type === "application/pdf"
    )
    if (files.length > 0) {
      this.setFile(files[0])
    } else {
      this.showError("PDF形式のファイルのみ対応しています。")
    }
  }

  setFile(file) {
    if (file.type !== "application/pdf") {
      this.showError("PDF形式のファイルのみ対応しています。")
      return
    }
    this.file = file
    this.fileNameTarget.textContent = file.name
    this.fileNameTarget.classList.remove("hidden")
    this.submitButtonTarget.disabled = false
    this.hideError()
  }

  async submit(event) {
    event.preventDefault()

    const clientCode = this.clientCodeTarget.value.trim()
    if (!clientCode) {
      this.showError("クライアントコードは必須です。")
      return
    }

    if (!this.file) {
      this.showError("PDFファイルを選択してください。")
      return
    }

    this.hideError()
    this.hideResult()
    this.showLoading()
    this.submitButtonTarget.disabled = true

    const formData = new FormData()
    formData.append("pdf", this.file)
    formData.append("client_code", clientCode)
    if (this.hasStatementPeriodTarget) {
      const period = this.statementPeriodTarget.value.trim()
      if (period) formData.append("statement_period", period)
    }

    try {
      const response = await fetch("/api/v1/amex_statements/process_statement", {
        method: "POST",
        body: formData,
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
        }
      })

      const data = await response.json()

      if (!response.ok) {
        this.showError(data.error || "明細の処理に失敗しました。")
        this.hideLoading()
        this.submitButtonTarget.disabled = false
        return
      }

      await this.pollStatus(data.id, clientCode)
    } catch (error) {
      this.showError(`通信エラー: ${error.message}`)
    } finally {
      this.hideLoading()
      this.submitButtonTarget.disabled = false
    }
  }

  async pollStatus(batchId, clientCode) {
    const POLL_INTERVAL = 3000
    const MAX_POLLS = 300

    for (let i = 0; i < MAX_POLLS; i++) {
      await new Promise(resolve => setTimeout(resolve, POLL_INTERVAL))

      try {
        const response = await fetch(
          `/api/v1/amex_statements/${batchId}/status?client_code=${encodeURIComponent(clientCode)}`
        )
        const data = await response.json()

        if (data.status === "completed") {
          this.showResult(data, clientCode)
          return
        }

        if (data.status === "failed") {
          this.showError(data.error_message || "明細の処理に失敗しました。")
          return
        }
      } catch (error) {
        console.warn("Polling error:", error.message)
      }
    }

    this.showError("処理がタイムアウトしました。しばらく待ってからページを再読み込みしてください。")
  }

  showLoading() {
    this.loadingTarget.classList.remove("hidden")
  }

  hideLoading() {
    this.loadingTarget.classList.add("hidden")
  }

  showError(message) {
    this.errorMessageTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorTarget.classList.add("hidden")
  }

  showResult(data, clientCode) {
    this.resultTarget.classList.remove("hidden")
    const summary = data.summary || {}
    let html = ""

    html += `<div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">`
    html += `<div class="bg-white shadow rounded-lg p-4 text-center">`
    html += `<p class="text-2xl font-bold text-blue-600">${this.escapeHTML(String(summary.total_transactions || 0))}</p>`
    html += `<p class="text-sm text-gray-500">取引件数</p></div>`
    html += `<div class="bg-white shadow rounded-lg p-4 text-center">`
    html += `<p class="text-2xl font-bold text-blue-600">${this.escapeHTML(String((summary.total_amount || 0).toLocaleString()))}円</p>`
    html += `<p class="text-sm text-gray-500">合計金額</p></div>`
    html += `<div class="bg-white shadow rounded-lg p-4 text-center">`
    html += `<p class="text-2xl font-bold text-yellow-600">${this.escapeHTML(String(summary.review_required_count || 0))}</p>`
    html += `<p class="text-sm text-gray-500">要確認</p></div>`
    html += `<div class="bg-white shadow rounded-lg p-4 text-center">`
    html += `<p class="text-2xl font-bold text-green-600">${this.escapeHTML(String(data.journal_entries_count || 0))}</p>`
    html += `<p class="text-sm text-gray-500">仕訳登録数</p></div>`
    html += `</div>`

    html += `<div class="flex gap-4">`
    html += `<a href="/journal_entries?client_code=${encodeURIComponent(clientCode)}&source_type=amex" class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 transition-colors">仕訳一覧を確認</a>`
    html += `<a href="/api/v1/journal_entries/export?client_code=${encodeURIComponent(clientCode)}&statement_batch_id=${data.id}" class="bg-gray-600 text-white px-4 py-2 rounded-md hover:bg-gray-700 transition-colors">CSVダウンロード</a>`
    html += `</div>`

    this.resultContentTarget.innerHTML = html
  }

  hideResult() {
    this.resultTarget.classList.add("hidden")
    this.resultContentTarget.innerHTML = ""
  }

  escapeHTML(str) {
    if (!str) return ""
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
