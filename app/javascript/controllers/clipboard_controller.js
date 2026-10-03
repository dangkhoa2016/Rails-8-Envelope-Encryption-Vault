import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "status"]

  async copy() {
    const text = this.sourceValue()
    try {
      await navigator.clipboard.writeText(text)
      this.announce("Copied")
    } catch (_error) {
      this.announce("Copy failed")
    }
  }

  sourceValue() {
    if ("value" in this.sourceTarget) return this.sourceTarget.value
    return this.sourceTarget.textContent
  }

  announce(message) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = message
    window.clearTimeout(this.resetTimer)
    this.resetTimer = window.setTimeout(() => {
      this.statusTarget.textContent = ""
    }, 2200)
  }

  disconnect() {
    window.clearTimeout(this.resetTimer)
  }
}
