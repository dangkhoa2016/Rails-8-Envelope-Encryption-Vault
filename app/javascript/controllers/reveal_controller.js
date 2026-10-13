import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { timeout: { type: Number, default: 30000 } }

  connect() {
    this.timer = window.setTimeout(() => this.hide(), this.timeoutValue)
  }

  disconnect() {
    if (this.timer) window.clearTimeout(this.timer)
  }

  hide() {
    this.element.querySelectorAll("[data-secret-value]").forEach((node) => {
      node.textContent = "••••••••••••"
    })
    const status = this.element.querySelector("[data-secret-status]")
    if (status) status.textContent = "Plaintext auto-hidden. Reveal again from the item page if needed."
    if (this.timer) window.clearTimeout(this.timer)
  }
}
