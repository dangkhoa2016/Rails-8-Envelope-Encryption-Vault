import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "button"]

  toggle() {
    const willOpen = this.panelTarget.classList.contains("hidden")
    this.panelTarget.classList.toggle("hidden")
    this.buttonTarget.setAttribute("aria-expanded", willOpen.toString())
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }
}
