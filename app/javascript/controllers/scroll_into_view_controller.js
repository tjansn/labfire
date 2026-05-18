import { Controller } from "@hotwired/stimulus"
import { nextFrame } from "helpers/timing_helpers"

export default class extends Controller {
  static values = { hideLatest: Boolean }

  #latestButton
  #latestButtonWasHidden
  #latestButtonDisplay

  async connect() {
    if (this.hideLatestValue) {
      document.body.classList.add("editing-message")
      this.#hideLatestButton()
    }

    await nextFrame()
    this.element.scrollIntoView({ behavior: "smooth", block: "center" })
  }

  disconnect() {
    if (this.hideLatestValue) {
      document.body.classList.remove("editing-message")
      this.#restoreLatestButton()
    }
  }

  #hideLatestButton() {
    this.#latestButton = document.querySelector("[data-messages-target~='latest']")

    if (this.#latestButton) {
      this.#latestButtonWasHidden = this.#latestButton.hidden
      this.#latestButtonDisplay = this.#latestButton.style.display
      this.#latestButton.hidden = true
      this.#latestButton.style.display = "none"
      this.#latestButton.classList.add("message-area__return-to-latest--editing")
    }
  }

  #restoreLatestButton() {
    if (this.#latestButton) {
      this.#latestButton.hidden = this.#latestButtonWasHidden
      this.#latestButton.style.display = this.#latestButtonDisplay
      this.#latestButton.classList.remove("message-area__return-to-latest--editing")
    }
  }
}
