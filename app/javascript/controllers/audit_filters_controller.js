import { Controller } from "@hotwired/stimulus"

// Action choices are scoped to the selected category before form submission.
// Source data contains event action identifiers only, never secret payloads.
export default class extends Controller {
  static targets = ["category", "action"]
  static values = { actions: Array }

  connect() {
    this.refreshActions(false)
  }

  categoryChanged() {
    this.refreshActions(true)
  }

  refreshActions(resetSelection) {
    const category = this.categoryTarget.value
    const chosen = resetSelection ? "" : this.actionTarget.value
    const actions = this.actionsValue.filter((item) => !category || item.category === category)
    const options = [new Option("All actions", "")]
    for (const item of actions) options.push(new Option(item.label, item.value))

    this.actionTarget.replaceChildren(...options)
    this.actionTarget.value = actions.some((item) => item.value === chosen) ? chosen : ""
  }
}
