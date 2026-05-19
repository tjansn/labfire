import { Controller } from "@hotwired/stimulus"

const BOTTOM_THRESHOLD = 90
const VIEWPORT_MARGIN = 8
const POPUP_GAP = 6

export default class extends Controller {
  static targets = [ "menu" ]
  static classes = [ "orientationTop" ]
  static values = { fixed: Boolean }

  close() {
    this.element.open = false
  }

  toggle() {
    this.#orient()
  }

  closeOnClickOutside(event) {
    if (!event.composedPath().includes(this.element)) this.close()
  }

  #orient() {
    this.menuTarget.style.removeProperty("--popup-offset-x")
    this.menuTarget.style.setProperty("--max-width", this.#maxWidth + "px")

    if (this.fixedValue) {
      this.#positionFixed()
    } else {
      this.element.classList.toggle(this.orientationTopClass, this.#distanceToBottom < BOTTOM_THRESHOLD)
      this.#clampInlinePosition()
    }
  }

  #positionFixed() {
    const triggerRect = this.element.getBoundingClientRect()
    const menuRect = this.#boundingClientRect
    const openAbove = triggerRect.bottom + POPUP_GAP + menuRect.height > window.innerHeight - VIEWPORT_MARGIN

    const left = this.#clamp(triggerRect.right - menuRect.width, this.#leftBoundary, this.#rightBoundary - menuRect.width)
    const top = openAbove ? triggerRect.top - menuRect.height - POPUP_GAP : triggerRect.bottom + POPUP_GAP

    this.element.classList.toggle(this.orientationTopClass, openAbove)
    this.#setFixedPosition(left, this.#clamp(top, VIEWPORT_MARGIN, window.innerHeight - menuRect.height - VIEWPORT_MARGIN))
  }

  #setFixedPosition(left, top) {
    this.menuTarget.style.setProperty("--popup-left", left + "px")
    this.menuTarget.style.setProperty("--popup-top", top + "px")

    // Ancestors with filters/backdrop filters can become the containing block for
    // fixed descendants. Compensate when the measured viewport position differs.
    const rect = this.#boundingClientRect
    this.menuTarget.style.setProperty("--popup-left", left + (left - rect.left) + "px")
    this.menuTarget.style.setProperty("--popup-top", top + (top - rect.top) + "px")
  }

  #clampInlinePosition() {
    const rect = this.#boundingClientRect
    let offset = 0

    if (rect.left < this.#leftBoundary) {
      offset = this.#leftBoundary - rect.left
    }

    if (rect.right + offset > this.#rightBoundary) {
      offset -= rect.right + offset - this.#rightBoundary
    }

    this.menuTarget.style.setProperty("--popup-offset-x", offset + "px")
  }

  #clamp(value, min, max) {
    if (max < min) return min

    return Math.min(Math.max(value, min), max)
  }

  get #distanceToBottom() {
    return window.innerHeight - this.#boundingClientRect.bottom
  }

  get #maxWidth() {
    return Math.max(this.#rightBoundary - this.#leftBoundary, 0)
  }

  get #leftBoundary() {
    return Math.max(VIEWPORT_MARGIN, this.#sidebarRight + VIEWPORT_MARGIN)
  }

  get #rightBoundary() {
    return window.innerWidth - VIEWPORT_MARGIN
  }

  get #sidebarRight() {
    const sidebar = document.getElementById("sidebar")
    if (!sidebar) return 0

    const rect = sidebar.getBoundingClientRect()
    if (rect.width <= 0 || rect.right <= 0 || rect.left >= window.innerWidth) return 0

    return rect.right
  }

  get #boundingClientRect() {
    return this.menuTarget.getBoundingClientRect()
  }
}
