import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form", "dropZone", "fileInput", "fileName",
    "submitButton", "loading", "error", "errorMessage",
    "clientCode"
  ]

  // --- サブクラスでオーバーライド ---
  get uploadUrl() { throw new Error("implement uploadUrl in subclass") }
  get sourceType() { throw new Error("implement sourceType in subclass") }
  get documentLabel() { return "明細" }

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
    if (file.size > 20 * 1024 * 1024) {
      this.showError("PDFファイルは20MB以下にしてください。")
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
    this.showLoading()
    this.submitButtonTarget.disabled = true

    const progressTab = window.open("about:blank", "_blank")

    const formData = new FormData()
    formData.append("pdf", this.file)
    formData.append("client_code", clientCode)
    try {
      const response = await fetch(this.uploadUrl, {
        method: "POST",
        body: formData,
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
        }
      })

      const data = await response.json()

      if (response.status === 409 && data.duplicate) {
        this.closeTab(progressTab)
        this.hideLoading()
        this.submitButtonTarget.disabled = false
        if (confirm(`この${this.documentLabel}は既に処理済みです。再処理しますか？`)) {
          await this.submitWithForce(formData)
        }
        return
      }

      if (!response.ok) {
        this.closeTab(progressTab)
        this.showError(data.error || `${this.documentLabel}の処理に失敗しました。`)
        this.hideLoading()
        this.submitButtonTarget.disabled = false
        return
      }

      this.openProgressTab(progressTab, data.id)
      this.resetForm()
    } catch (error) {
      this.closeTab(progressTab)
      this.showError(`通信エラー: ${error.message}`)
    } finally {
      this.hideLoading()
      this.submitButtonTarget.disabled = false
    }
  }

  async submitWithForce(formData) {
    this.showLoading()
    this.submitButtonTarget.disabled = true

    const progressTab = window.open("about:blank", "_blank")
    formData.append("force", "true")

    try {
      const response = await fetch(this.uploadUrl, {
        method: "POST",
        body: formData,
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
        }
      })

      const data = await response.json()

      if (!response.ok) {
        this.closeTab(progressTab)
        this.showError(data.error || `${this.documentLabel}の処理に失敗しました。`)
        return
      }

      this.openProgressTab(progressTab, data.id)
      this.resetForm()
    } catch (error) {
      this.closeTab(progressTab)
      this.showError(`通信エラー: ${error.message}`)
    } finally {
      this.hideLoading()
      this.submitButtonTarget.disabled = false
    }
  }

  openProgressTab(tab, batchId) {
    const url = `/statement_batches/${batchId}`
    if (tab) {
      tab.location.href = url
    } else {
      window.location.href = url
    }
  }

  closeTab(tab) {
    if (tab) tab.close()
  }

  resetForm() {
    this.file = null
    this.fileInputTarget.value = ""
    this.fileNameTarget.textContent = ""
    this.fileNameTarget.classList.add("hidden")
    this.submitButtonTarget.disabled = true
    this.hideError()
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
}
