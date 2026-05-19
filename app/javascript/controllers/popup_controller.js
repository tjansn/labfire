import { Controller } from "@hotwired/stimulus"

const BOTTOM_THRESHOLD = 90
const VIEWPORT_MARGIN = 8

export default class extends Controller {
  static targets = [ "menu" ]
  static classes = [ "orientationTop" ]

  close() {
    this.element.open = false
  }

  toggle() {
    this.#orient()
  }

  closeOnClickOutside({ target }) {
    if (!this.element.contains(target)) this.close()
  }

  #orient() {
    this.menuTarget.style.removeProperty("--popup-offset-x")
    this.element.classList.toggle(this.orientationTopClass, this.#distanceToBottom < BOTTOM_THRESHOLD)
    this.menuTarget.style.setProperty("--max-width", this.#maxWidth + "px")
    this.#clampInlinePosition()
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
