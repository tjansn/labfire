import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "theme"

export default class extends Controller {
  static targets = [ "toggle" ]

  connect() {
    this.mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.mediaQuery.addEventListener?.("change", this.sync)
    this.apply()
  }

  disconnect() {
    this.mediaQuery?.removeEventListener?.("change", this.sync)
  }

  toggle() {
    const nextTheme = document.documentElement.classList.contains("dark") ? "light" : "dark"
    localStorage.setItem(STORAGE_KEY, nextTheme)
    this.apply(nextTheme)
  }

  sync = () => {
    this.apply()
  }

  apply(theme = localStorage.getItem(STORAGE_KEY)) {
    const prefersDark = this.mediaQuery?.matches
    const dark = theme === "dark" || (!theme && prefersDark)
    const light = theme === "light"

    document.documentElement.classList.toggle("dark", dark)
    document.documentElement.classList.toggle("light", light)
    document.documentElement.style.colorScheme = dark ? "dark" : "light"

    this.toggleTargets.forEach((toggle) => {
      const state = dark ? "true" : "false"
      const label = dark ? "Switch to light mode" : "Switch to dark mode"

      if (toggle.getAttribute("role") === "menuitemcheckbox" || toggle.hasAttribute("aria-checked")) {
        toggle.setAttribute("aria-checked", state)
      } else {
        toggle.setAttribute("aria-pressed", state)
      }
      toggle.title = label
      toggle.setAttribute("aria-label", label)
    })
  }
}
