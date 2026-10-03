import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = window.setTimeout(() => this.dismiss(), 4500)
  }

  disconnect() {
    window.clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.classList.add("opacity-0", "-translate-y-1")
    window.setTimeout(() => this.element.remove(), 180)
  }
}
