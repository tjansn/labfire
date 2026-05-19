import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input" ]
  static values = { content: String, html: String }

  insert(event) {
    event.preventDefault()

    if (this.hasHtmlValue) {
      this.#insertHtml(this.htmlValue)
    } else {
      this.#insertContent(this.contentValue)
    }
  }

  insertInput(event) {
    event.preventDefault()

    const content = this.inputTarget.value.trim()
    if (!content) return

    this.#insertContent(content)
    this.inputTarget.value = ""
  }

  #insertContent(content) {
    const editor = document.querySelector("#composer trix-editor")
    if (!editor) return

    editor.editor.insertString(content)
    editor.focus()
    this.#closePicker()
  }

  #insertHtml(html) {
    const editor = document.querySelector("#composer trix-editor")
    if (!editor) return

    editor.editor.insertHTML(html)
    editor.focus()
    this.#closePicker()
  }

  #closePicker() {
    this.element.closest("details[open]")?.removeAttribute("open")
  }
}
