import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "inlineAction", "overflow" ]
  static values = { viewportMargin: { type: Number, default: 8 } }

  connect() {
    this.boundRefresh = () => this.refresh()

    window.addEventListener("resize", this.boundRefresh)
    window.addEventListener("orientationchange", this.boundRefresh)
    requestAnimationFrame(this.boundRefresh)
  }

  disconnect() {
    window.removeEventListener("resize", this.boundRefresh)
    window.removeEventListener("orientationchange", this.boundRefresh)
  }

  refresh() {
    if (!this.hasOverflowTarget) return

    this.showInlineActions()

    if (!this.fitsInViewport()) {
      this.showOverflowMenu()
    }
  }

  showInlineActions() {
    this.inlineActionTargets.forEach((action) => action.hidden = false)
    this.overflowTarget.open = false
    this.overflowTarget.hidden = true
  }

  showOverflowMenu() {
    this.inlineActionTargets.forEach((action) => action.hidden = true)
    this.overflowTarget.hidden = false
  }

  fitsInViewport() {
    const rect = this.element.getBoundingClientRect()
    const viewportWidth = document.documentElement.clientWidth
    const margin = this.viewportMarginValue

    return rect.left >= margin && rect.right <= viewportWidth - margin
  }
}
