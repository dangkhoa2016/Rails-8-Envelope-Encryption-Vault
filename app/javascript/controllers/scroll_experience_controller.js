import { Controller } from "@hotwired/stimulus"

const PENDING_SCROLL_KEY = "revault:pagination-scroll"
const PENDING_LIFETIME_MS = 15_000
const SHOW_TOP_AFTER_PX = 160

// Applied application-wide. Pagination records a short-lived navigation intent
// and restores the position only after Turbo renders the requested page.
export default class extends Controller {
  static targets = ["topButton"]

  connect() {
    this.handleScroll = this.updateButton.bind(this)
    this.handlePaginationClick = this.capturePagination.bind(this)
    this.handleTurboLoad = this.restorePagination.bind(this)

    window.addEventListener("scroll", this.handleScroll, { passive: true })
    document.addEventListener("click", this.handlePaginationClick, true)
    document.addEventListener("turbo:load", this.handleTurboLoad)
    this.updateButton()
    // Stimulus may connect after Turbo's load event on a restored document.
    requestAnimationFrame(() => this.restorePagination())
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
    document.removeEventListener("click", this.handlePaginationClick, true)
    document.removeEventListener("turbo:load", this.handleTurboLoad)
  }

  updateButton() {
    if (!this.hasTopButtonTarget) return
    this.topButtonTarget.hidden = window.scrollY < SHOW_TOP_AFTER_PX
  }

  toTop(event) {
    event.preventDefault()
    window.scrollTo({ top: 0, behavior: this.motionBehavior() })
  }

  capturePagination(event) {
    if (event.defaultPrevented || event.button !== 0 ||
        event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return

    const link = event.target.closest?.("nav[data-pagination-scroll-target] a[href]")
    if (!link || link.target === "_blank" || link.hasAttribute("download")) return

    const nav = link.closest("nav[data-pagination-scroll-target]")
    const target = nav?.dataset.paginationScrollTarget
    if (!target || !document.getElementById(target)) return

    const destination = new URL(link.href, window.location.href)
    if (destination.origin !== window.location.origin) return

    try {
      sessionStorage.setItem(PENDING_SCROLL_KEY, JSON.stringify({
        path: destination.pathname,
        page: destination.searchParams.get("page") || "1",
        target,
        savedAt: Date.now()
      }))
    } catch (_error) {
      // Private browsing or disabled browser storage must never block navigation.
    }
  }

  restorePagination() {
    let intent
    try {
      intent = JSON.parse(sessionStorage.getItem(PENDING_SCROLL_KEY) || "null")
    } catch (_error) {
      return
    }
    if (!intent) return

    const locationPage = new URL(window.location.href).searchParams.get("page") || "1"
    if (intent.path !== window.location.pathname || intent.page !== locationPage ||
        Date.now() - intent.savedAt > PENDING_LIFETIME_MS) {
      // Never hijack unrelated navigation, browser Back/Forward, or stale visits.
      try { sessionStorage.removeItem(PENDING_SCROLL_KEY) } catch (_error) {}
      return
    }

    try { sessionStorage.removeItem(PENDING_SCROLL_KEY) } catch (_error) {}
    requestAnimationFrame(() => {
      const target = document.getElementById(intent.target)
      if (!target) return

      // scroll-margin-top on targets makes room for the sticky application bar.
      target.scrollIntoView({ behavior: this.motionBehavior(), block: "start" })
    })
  }

  motionBehavior() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth"
  }
}
