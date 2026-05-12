import { Controller } from "@hotwired/stimulus"

// Toggles an "open" class on a target element, keeps aria-expanded in sync on the
// trigger button, closes on Escape, and returns focus to the trigger on close.
export default class extends Controller {
  static values = {
    targetSelector: String,
    openClass: { type: String, default: "menu-open" }
  }

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("keydown", this.handleKeydown)
    document.addEventListener("click", this.handleClickOutside, true)
    this.syncAria()
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    document.removeEventListener("click", this.handleClickOutside, true)
  }

  toggle(event) {
    event?.preventDefault?.()
    const target = this.target
    if (!target) return

    const wasOpen = target.classList.contains(this.openClassValue)
    target.classList.toggle(this.openClassValue)
    this.syncAria()

    if (!wasOpen) {
      const panel = this.panel
      const first = panel?.querySelector(this.focusableSelector)
      first?.focus({ preventScroll: true })
    } else {
      this.element.focus({ preventScroll: true })
    }
  }

  close() {
    const target = this.target
    if (!target?.classList.contains(this.openClassValue)) return
    target.classList.remove(this.openClassValue)
    this.syncAria()
    this.element.focus({ preventScroll: true })
  }

  handleKeydown(event) {
    if (event.key !== "Escape") return
    if (!this.isOpen) return
    event.preventDefault()
    this.close()
  }

  handleClickOutside(event) {
    if (!this.isOpen) return
    const panel = this.panel
    if (this.element.contains(event.target)) return
    if (panel?.contains(event.target)) return
    this.close()
  }

  syncAria() {
    this.element.setAttribute("aria-expanded", this.isOpen ? "true" : "false")
  }

  get target() {
    return document.querySelector(this.targetSelectorValue)
  }

  get panel() {
    const id = this.element.getAttribute("aria-controls")
    return id ? document.getElementById(id) : this.target
  }

  get isOpen() {
    return !!this.target?.classList.contains(this.openClassValue)
  }

  get focusableSelector() {
    return "a, button, [role='menuitem'], [role='menuitemcheckbox'], [tabindex]:not([tabindex='-1'])"
  }
}
