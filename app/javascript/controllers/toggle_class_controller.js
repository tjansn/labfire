import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static classes = [ "toggle" ]
  static values = { targetSelector: String }

  toggle() {
    const target = this.hasTargetSelectorValue ? document.querySelector(this.targetSelectorValue) : this.element
    target?.classList.toggle(this.toggleClass)
  }
}
