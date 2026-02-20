import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form", "dropZone", "fileInput", "preview", "fileCount",
    "submitButton", "loading", "error", "errorMessage",
    "result", "resultContent", "clientCode", "propertyName", "roomType"
  ]

  connect() {
    this.files = []
    this.objectURLs = []
  }

  openFileDialog() {
    this.fileInputTarget.click()
  }

  filesSelected(event) {
    this.addFiles(Array.from(event.target.files))
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
      ["image/jpeg", "image/png", "image/webp"].includes(f.type)
    )
    this.addFiles(files)
  }

  addFiles(newFiles) {
    this.files = [...this.files, ...newFiles]
    this.updatePreview()
    this.updateFileCount()
    this.submitButtonTarget.disabled = this.files.length === 0
  }

  removeFile(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.files.splice(index, 1)
    this.updatePreview()
    this.updateFileCount()
    this.submitButtonTarget.disabled = this.files.length === 0
  }

  updatePreview() {
    if (this.files.length === 0) {
      this.previewTarget.classList.add("hidden")
      return
    }

    this.previewTarget.classList.remove("hidden")
    this.objectURLs.forEach(url => URL.revokeObjectURL(url))
    this.objectURLs = []
    this.previewTarget.innerHTML = ""

    this.files.forEach((file, index) => {
      const div = document.createElement("div")
      div.className = "relative group"

      const img = document.createElement("img")
      img.className = "w-full h-24 object-cover rounded-lg"
      const objectURL = URL.createObjectURL(file)
      this.objectURLs.push(objectURL)
      img.src = objectURL

      const removeBtn = document.createElement("button")
      removeBtn.type = "button"
      removeBtn.className = "absolute top-1 right-1 bg-red-500 text-white rounded-full w-5 h-5 flex items-center justify-center text-xs opacity-0 group-hover:opacity-100 transition-opacity"
      removeBtn.textContent = "×"
      removeBtn.dataset.index = index
      removeBtn.dataset.action = "click->image-upload#removeFile"

      const label = document.createElement("p")
      label.className = "text-xs text-gray-500 mt-1 truncate"
      label.textContent = file.name

      div.appendChild(img)
      div.appendChild(removeBtn)
      div.appendChild(label)
      this.previewTarget.appendChild(div)
    })
  }

  updateFileCount() {
    if (this.files.length === 0) {
      this.fileCountTarget.textContent = "画像が選択されていません"
    } else {
      this.fileCountTarget.textContent = `${this.files.length}枚の画像が選択されています`
    }
  }

  async submit(event) {
    event.preventDefault()

    const clientCode = this.clientCodeTarget.value.trim()
    const propertyName = this.propertyNameTarget.value.trim()
    const roomType = this.roomTypeTarget.value.trim()

    if (!clientCode || !propertyName || !roomType) {
      this.showError("クライアントコード、施設名、部屋タイプは必須です。")
      return
    }

    if (this.files.length === 0) {
      this.showError("画像を1枚以上アップロードしてください。")
      return
    }

    this.hideError()
    this.hideResult()
    this.showLoading()
    this.submitButtonTarget.disabled = true

    const formData = new FormData()
    formData.append("client_code", clientCode)
    formData.append("property_name", propertyName)
    formData.append("room_type", roomType)
    this.files.forEach(file => formData.append("images[]", file))

    try {
      const response = await fetch(`/api/v1/cleaning_manuals/generate?client_code=${encodeURIComponent(clientCode)}`, {
        method: "POST",
        body: formData,
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
        }
      })

      const data = await response.json()

      if (response.ok) {
        this.showResult(data)
      } else {
        this.showError(data.error || "マニュアルの生成に失敗しました。")
      }
    } catch (error) {
      this.showError(`通信エラー: ${error.message}`)
    } finally {
      this.hideLoading()
      this.submitButtonTarget.disabled = false
    }
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

  showResult(data) {
    this.resultTarget.classList.remove("hidden")
    this.resultContentTarget.innerHTML = this.buildResultHTML(data)
  }

  hideResult() {
    this.resultTarget.classList.add("hidden")
    this.resultContentTarget.innerHTML = ""
  }

  buildResultHTML(data) {
    const manual = data.manual_data || data
    const areas = manual.areas || []
    let html = ""

    html += `<div class="flex items-center justify-between mb-4">`
    html += `<h2 class="text-xl font-bold">${this.escapeHTML(data.property_name)} - ${this.escapeHTML(data.room_type)}</h2>`
    if (data.id) {
      html += `<a href="/cleaning_manuals/${data.id}" class="text-blue-600 hover:text-blue-800 text-sm">詳細ページ →</a>`
    }
    html += `</div>`

    areas.forEach(area => {
      html += `<div class="bg-white shadow rounded-lg overflow-hidden mb-4">`
      html += `<div class="bg-gray-50 px-6 py-3 border-b"><h3 class="font-semibold">${this.escapeHTML(area.area_name)}</h3></div>`
      html += `<div class="p-4"><ol class="space-y-3">`

      ;(area.cleaning_steps || []).forEach(step => {
        html += `<li class="flex gap-3">`
        html += `<span class="flex-shrink-0 w-7 h-7 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center text-sm">${step.order}</span>`
        html += `<div><p class="font-medium text-sm">${this.escapeHTML(step.task)}</p>`
        html += `<p class="text-xs text-gray-600">${this.escapeHTML(step.description)}</p></div>`
        html += `</li>`
      })

      html += `</ol></div></div>`
    })

    return html
  }

  escapeHTML(str) {
    if (!str) return ""
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
