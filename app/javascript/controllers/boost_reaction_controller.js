import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static classes = [ "reveal", "perform" ]
  static targets = [ "content", "deleteButton" ]
  static values = { descriptionId: String }

  connect() {
    if (this.#currentUserDeleteButton) {
      this.#currentUserDeleteButton.hidden = false
      this.#setAccessibleAttributes()
    }
  }

  submitOrReveal(event) {
    if (this.#currentUserDeleteButton) {
      event.preventDefault()
      this.element.classList.toggle(this.revealClass)
      this.#currentUserDeleteButton.focus()
    }
  }

  perform() {
    this.element.classList.add(this.performClass)
  }

  #setAccessibleAttributes() {
    this.contentTarget.setAttribute("tabindex", "0")
    this.contentTarget.setAttribute("aria-describedby", this.descriptionIdValue)
  }

  get #currentUserDeleteButton() {
    const currentUserId = window.Current?.user?.id

    if (!currentUserId) return

    return this.deleteButtonTargets.find((button) => {
      return parseInt(button.dataset.boostReactionBoosterId) === currentUserId
    })
  }
}
