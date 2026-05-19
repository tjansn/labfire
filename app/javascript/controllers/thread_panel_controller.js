import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    document.body.classList.add("thread-panel-open")
  }

  disconnect() {
    document.body.classList.remove("thread-panel-open")
  }

  close() {
    const frame = this.element.closest("turbo-frame#thread-panel")
    if (frame) {
      frame.removeAttribute("src")
      frame.innerHTML = ""
    } else {
      this.element.remove()
    }
    document.body.classList.remove("thread-panel-open")
  }
}
