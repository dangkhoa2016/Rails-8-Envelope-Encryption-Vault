import { Controller } from "@hotwired/stimulus"

// Restore keyboard focus after the successful Turbo Stream button replacement.
export default class extends Controller {
  static values = { updated: Boolean }

  connect() {
    if (!this.updatedValue) return

    this.element.querySelector("button[type=submit]")?.focus({ preventScroll: true })
  }
}
