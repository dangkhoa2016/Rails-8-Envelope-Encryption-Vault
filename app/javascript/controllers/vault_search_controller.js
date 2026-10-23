import { Controller } from "@hotwired/stimulus"

// A Turbo Stream search replaces only the Vault listing. Reconcile the browser
// location with a session-scoped opaque filter reference; no title/tag leaks.
export default class extends Controller {
  static values = { updated: Boolean, listUrl: String }

  connect() {
    if (!this.updatedValue) return

    window.history.pushState(window.history.state, "", this.listUrlValue)
    this.element.querySelector("input[type=search]")?.focus({ preventScroll: true })
  }
}
