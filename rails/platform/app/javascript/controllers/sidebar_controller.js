import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  toggle() {
    const isHidden = this.sidebarTarget.classList.contains("-translate-x-full")
    if (isHidden) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.sidebarTarget.classList.remove("-translate-x-full")
    this.overlayTarget.classList.remove("hidden")
  }

  close() {
    this.sidebarTarget.classList.add("-translate-x-full")
    this.overlayTarget.classList.add("hidden")
  }
}
