import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "inlineAction", "overflow" ]
  static values = { viewportMargin: { type: Number, default: 8 } }

  connect() {
    this.message = this.element.closest(".message")
    this.boundRefresh = () => this.refresh()
    this.boundActivate = (event) => this.activateOnTap(event)
    this.boundDeactivate = (event) => this.deactivateOnOutsideTap(event)

    window.addEventListener("resize", this.boundRefresh)
    window.addEventListener("orientationchange", this.boundRefresh)
    this.message?.addEventListener("click", this.boundActivate)
    document.addEventListener("pointerdown", this.boundDeactivate, true)
    requestAnimationFrame(this.boundRefresh)
  }

  disconnect() {
    window.removeEventListener("resize", this.boundRefresh)
    window.removeEventListener("orientationchange", this.boundRefresh)
    this.message?.removeEventListener("click", this.boundActivate)
    document.removeEventListener("pointerdown", this.boundDeactivate, true)
  }

  activateOnTap(event) {
    if (!this.usesTapToActivate || this.isInteractive(event.target)) return

    this.deactivateOtherMessages()
    this.message?.classList.add("message--actions-active")
  }

  deactivateOnOutsideTap(event) {
    if (!this.usesTapToActivate || this.message?.contains(event.target)) return

    this.message?.classList.remove("message--actions-active")
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

  deactivateOtherMessages() {
    document.querySelectorAll(".message--actions-active").forEach((message) => {
      if (message !== this.message) message.classList.remove("message--actions-active")
    })
  }

  isInteractive(target) {
    return target.closest("a, button, summary, input, textarea, select, label, trix-editor, [contenteditable='true'], [role='button']")
  }

  get usesTapToActivate() {
    return window.matchMedia("(hover: none), (pointer: coarse)").matches
  }

  fitsInViewport() {
    const rect = this.element.getBoundingClientRect()
    const viewportWidth = document.documentElement.clientWidth
    const margin = this.viewportMarginValue

    return rect.left >= margin && rect.right <= viewportWidth - margin
  }
}
