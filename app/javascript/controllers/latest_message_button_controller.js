import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  #footer
  #mutationObserver
  #resizeObserver

  connect() {
    this.#footer = document.querySelector("#footer")
    this.#mutationObserver = new MutationObserver(this.#update.bind(this))
    this.#mutationObserver.observe(document.body, { childList: true, subtree: true })
    this.#resizeObserver = new ResizeObserver(this.#updatePosition.bind(this))

    if (this.#footer) {
      this.#resizeObserver.observe(this.#footer)
    }

    window.addEventListener("resize", this.#updatePosition)
    this.#update()
  }

  disconnect() {
    this.#mutationObserver?.disconnect()
    this.#resizeObserver?.disconnect()
    window.removeEventListener("resize", this.#updatePosition)
  }

  #update() {
    this.#updatePosition()

    if (this.#editingMessage) {
      this.element.style.setProperty("display", "none", "important")
      this.element.classList.add("message-area__return-to-latest--editing")
    } else {
      this.element.style.removeProperty("display")
      this.element.classList.remove("message-area__return-to-latest--editing")
    }
  }

  #updatePosition = () => {
    if (this.#footer) {
      const gap = this.#spaceValue("--gl-space-4", 16)
      const footerHeight = this.#footer.getBoundingClientRect().height

      this.element.style.setProperty("--latest-message-button-bottom", `${Math.ceil(footerHeight + gap)}px`)
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
    return document.querySelector(".message__body-content--editing") !== null
  }
}
