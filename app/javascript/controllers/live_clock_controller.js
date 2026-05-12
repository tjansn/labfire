import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.formatter = new Intl.DateTimeFormat(undefined, { hour: "2-digit", minute: "2-digit" })
    this.tick()
    this.timer = setInterval(() => this.tick(), 30_000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    this.element.textContent = this.formatter.format(new Date())
  }
}
