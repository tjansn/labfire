import { Controller } from "@hotwired/stimulus"

const ALL_CONTENT_VIEWED_EVENT = "messages:all-content-viewed"
const EDITING_MESSAGE_SELECTOR = ".message__body-content--editing"
const LATEST_CONTENT_AVAILABLE_EVENT = "messages:latest-content-available"

export default class extends Controller {
  #footer
  #mutationObserver
  #resizeObserver
  #visible = false

  connect() {
    this.#visible = !this.element.hidden
    this.#resizeObserver = new ResizeObserver(this.#updatePosition)
    this.#mutationObserver = new MutationObserver(this.#update)
    this.#mutationObserver.observe(document.body, {
      attributeFilter: [ "class" ],
      attributes: true,
      childList: true,
      subtree: true,
    })

    document.addEventListener(LATEST_CONTENT_AVAILABLE_EVENT, this.#show)
    document.addEventListener(ALL_CONTENT_VIEWED_EVENT, this.#hide)
    window.addEventListener("resize", this.#updatePosition)

    this.#observeFooter()
    this.#update()
  }

  disconnect() {
    this.#mutationObserver?.disconnect()
    this.#resizeObserver?.disconnect()
    document.removeEventListener(LATEST_CONTENT_AVAILABLE_EVENT, this.#show)
    document.removeEventListener(ALL_CONTENT_VIEWED_EVENT, this.#hide)
    window.removeEventListener("resize", this.#updatePosition)
  }

  show() {
    this.#visible = true
    this.#update()
  }

  hide() {
    this.#visible = false
    this.#update()
  }

  returnToLatest() {
    this.hide()
    this.dispatch("return")
  }

  #show = () => {
    this.show()
  }

  #hide = () => {
    this.hide()
  }

  #update = () => {
    this.#updatePosition()

    const editing = this.#editingMessage
    this.element.hidden = !this.#visible
    this.element.classList.toggle("message-area__return-to-latest--editing", editing)
  }

  #updatePosition = () => {
    this.#observeFooter()

    if (this.#footer) {
      const gap = this.#spaceValue("--gl-space-4", 16)
      const footerHeight = this.#footer.getBoundingClientRect().height

      this.element.style.setProperty("--latest-message-button-bottom", `${Math.ceil(footerHeight + gap)}px`)
    }
  }

  #observeFooter() {
    const footer = document.querySelector("#footer")

    if (footer === this.#footer) return

    if (this.#footer) {
      this.#resizeObserver.unobserve(this.#footer)
    }

    this.#footer = footer

    if (this.#footer) {
      this.#resizeObserver.observe(this.#footer)
    }
  }

  #spaceValue(name, fallback) {
    const value = getComputedStyle(document.documentElement).getPropertyValue(name).trim()
    const number = parseFloat(value)

    if (!Number.isFinite(number)) return fallback
    if (value.endsWith("px")) return number
    if (value.endsWith("rem")) return number * parseFloat(getComputedStyle(document.documentElement).fontSize)
    if (value.endsWith("em")) return number * parseFloat(getComputedStyle(this.element).fontSize)

    return number
  }

  get #editingMessage() {
    return document.querySelector(EDITING_MESSAGE_SELECTOR) !== null
  }
}
