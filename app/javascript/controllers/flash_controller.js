import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: { type: Number, default: 4500 } }

  connect() {
    this.remaining = this.durationValue
    this.closed = false
    this.resume()
  }

  disconnect() {
    window.clearTimeout(this.timeout)
    window.clearTimeout(this.removalTimeout)
  }

  pause() {
    if (this.closed || !this.timeout) return

    window.clearTimeout(this.timeout)
    this.timeout = null
    this.remaining = Math.max(0, this.remaining - (Date.now() - this.startedAt))
  }

  resume() {
    if (this.closed || this.timeout) return

    this.startedAt = Date.now()
    this.timeout = window.setTimeout(() => this.dismiss(), this.remaining)
  }

  dismiss() {
    if (this.closed) return

    this.closed = true
    window.clearTimeout(this.timeout)
    this.timeout = null
    this.element.classList.add("opacity-0", "translate-y-2")
    this.removalTimeout = window.setTimeout(() => this.element.remove(), 180)
  }
}
