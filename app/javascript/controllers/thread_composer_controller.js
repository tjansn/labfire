import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "text", "clientid"]

  connect() {
    if (!this.#usingTouchDevice) {
      requestAnimationFrame(() => this.textTarget.focus())
    }
  }

  submit(event) {
    event.preventDefault()
    if (this.#validInput()) {
      this.clientidTarget.value = this.#generateClientId()
      this.formTarget.requestSubmit()
    }
  }

  submitByKeyboard(event) {
    const plainEnter = event.keyCode === 13 && !event.shiftKey && !event.isComposing
    const metaEnter = event.key === "Enter" && (event.metaKey || event.ctrlKey)

    if (!this.#usingTouchDevice && (metaEnter || plainEnter)) {
      this.submit(event)
    }
  }

  submitEnd(event) {
    if (event.detail.success) {
      this.#reset()
    }
  }

  #validInput() {
    return this.textTarget.textContent.trim().length > 0
  }

  #reset() {
    const editor = this.textTarget.editor
    if (editor) {
      editor.setSelectedRange([0, editor.getDocument().toString().length])
      editor.deleteInDirection("forward")
    } else {
      this.textTarget.value = ""
    }
  }

  #generateClientId() {
    return Math.random().toString(36).slice(2)
  }

  get #usingTouchDevice() {
    return "ontouchstart" in window || navigator.maxTouchPoints > 0
  }
}
