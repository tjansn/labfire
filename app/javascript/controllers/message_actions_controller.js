import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "inlineAction", "overflow" ]
  static values = { viewportMargin: { type: Number, default: 8 } }

  connect() {
    this.message = this.element.closest(".message")
    this.scrollContainer = this.element.closest(".messages")
    this.boundRefresh = () => this.refresh()
    this.boundActivate = (event) => this.activateOnTap(event)
    this.boundDeactivate = (event) => this.deactivateOnOutsideTap(event)

    window.addEventListener("resize", this.boundRefresh)
    window.addEventListener("orientationchange", this.boundRefresh)
    this.scrollContainer?.addEventListener("scroll", this.boundRefresh, { passive: true })
    this.message?.addEventListener("mouseenter", this.boundRefresh)
    this.message?.addEventListener("focusin", this.boundRefresh)
    this.message?.addEventListener("click", this.boundActivate)
    document.addEventListener("pointerdown", this.boundDeactivate, true)
    requestAnimationFrame(this.boundRefresh)
  }

  disconnect() {
    window.removeEventListener("resize", this.boundRefresh)
    window.removeEventListener("orientationchange", this.boundRefresh)
    this.scrollContainer?.removeEventListener("scroll", this.boundRefresh)
    this.message?.removeEventListener("mouseenter", this.boundRefresh)
    this.message?.removeEventListener("focusin", this.boundRefresh)
    this.message?.removeEventListener("click", this.boundActivate)
    document.removeEventListener("pointerdown", this.boundDeactivate, true)
  }

  activateOnTap(event) {
    if (!this.usesTapToActivate || this.isInteractive(event.target)) return

    this.deactivateOtherMessages()
    this.message?.classList.add("message--actions-active")
    this.refresh()
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

    this.positionInViewport()
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
    return this.element.offsetWidth <= this.availableWidth
  }

  positionInViewport() {
    const anchorRect = this.anchorElement.getBoundingClientRect()
    const toolbarRect = this.element.getBoundingClientRect()

    const left = this.clamp(anchorRect.right - toolbarRect.width, this.leftBoundary, this.rightBoundary - toolbarRect.width)
    const top = this.clamp(anchorRect.top - toolbarRect.height / 2, this.viewportMarginValue, document.documentElement.clientHeight - toolbarRect.height - this.viewportMarginValue)

    this.element.style.setProperty("--message-actions-left", `${left}px`)
    this.element.style.setProperty("--message-actions-top", `${top}px`)
  }

  clamp(value, min, max) {
    if (max < min) return min

    return Math.min(Math.max(value, min), max)
  }

  get availableWidth() {
    return this.rightBoundary - this.leftBoundary
  }

  get leftBoundary() {
    return Math.max(this.viewportMarginValue, this.sidebarRight + this.viewportMarginValue)
  }

  get rightBoundary() {
    return document.documentElement.clientWidth - this.viewportMarginValue
  }

  get sidebarRight() {
    const sidebar = document.getElementById("sidebar")
    if (!sidebar) return 0

    const rect = sidebar.getBoundingClientRect()
    if (rect.width <= 0 || rect.right <= 0 || rect.left >= document.documentElement.clientWidth) return 0

    return rect.right
  }

  get anchorElement() {
    return this.message?.querySelector(".message__body-content") || this.message || this.element
  }
}
