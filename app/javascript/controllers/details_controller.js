import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    event?.stopPropagation()
    this.element.open = true
  }
}
