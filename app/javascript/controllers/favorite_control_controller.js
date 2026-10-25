import { Controller } from "@hotwired/stimulus"

// Restore keyboard focus after the successful Turbo Stream button replacement.
export default class extends Controller {
  static values = { updated: Boolean }

  // Disable the star for the lifetime of a Turbo form submission. Turbo
  // replaces a successful control and dispatches submit-end on failure.
  disable(event) {
    if (!this.element.contains(event.target)) return

    this.element.querySelectorAll("button[type=submit]").forEach((button) => {
      button.disabled = true
      button.setAttribute("aria-busy", "true")
    })
  }

  enable(event) {
    if (!this.element.contains(event.target)) return

    this.element.querySelectorAll("button[type=submit]").forEach((button) => {
      button.disabled = false
      button.removeAttribute("aria-busy")
    })
  }

  connect() {
    if (!this.updatedValue) return

    this.element.querySelector("button[type=submit]")?.focus({ preventScroll: true })
  }
}
