import { Controller } from "@hotwired/stimulus"
import FileUploader from "models/file_uploader"
import { escapeHTML } from "helpers/dom_helpers"

export default class extends Controller {
  static classes = ["toolbar"]
  static targets = ["form", "text", "clientid", "fields", "fileList"]

  #files = []

  connect() {
    if (!this.#usingTouchDevice) {
      requestAnimationFrame(() => this.textTarget.focus())
    }
  }

  submit(event) {
    event.preventDefault()

    if (!this.fieldsTarget.disabled) {
      this.#submitFiles()
      this.#submitMessage()
      this.collapseToolbar()
      this.textTarget.focus()
    }
  }

  submitByKeyboard(event) {
    const toolbarVisible = this.element.classList.contains(this.toolbarClass)
    const plainEnter = event.keyCode === 13 && !event.shiftKey && !event.isComposing
    const metaEnter = event.key === "Enter" && (event.metaKey || event.ctrlKey)

    if (!this.#usingTouchDevice && (metaEnter || (plainEnter && !toolbarVisible))) {
      this.submit(event)
    }
  }

  submitEnd(event) {
    if (event.detail.success) {
      this.#reset()
    }
  }

  toggleToolbar() {
    const expanded = this.element.classList.toggle(this.toolbarClass)
    this.#setToolbarTogglePressed(expanded)
    this.textTarget.focus()
  }

  collapseToolbar() {
    this.element.classList.remove(this.toolbarClass)
    this.#setToolbarTogglePressed(false)
  }

  filePicked(event) {
    for (const file of event.target.files) {
      this.#files.push(file)
    }
    event.target.value = null
    this.#updateFileList()
  }

  fileUnpicked(event) {
    this.#files.splice(event.params.index, 1)
    this.#updateFileList()
  }

  pasteFiles(event) {
    if (event.clipboardData.files.length > 0) {
      event.preventDefault()
    }

    for (const file of event.clipboardData.files) {
      this.#files.push(file)
    }

    this.#updateFileList()
  }

  #submitMessage() {
    if (this.#validInput()) {
      this.clientidTarget.value = this.#generateClientId()
      this.#serializeCustomEmojisForSubmission()
      this.formTarget.requestSubmit()
    }
  }

  #validInput() {
    return this.textTarget.textContent.trim().length > 0 || this.textTarget.querySelector("[data-custom-emoji-shortcode]")
  }

  async #submitFiles() {
    const files = this.#files
    if (files.length === 0) return

    this.#files = []
    this.#updateFileList()

    const parentMessageId = this.formTarget.querySelector("input[name='message[parent_message_id]']")?.value

    for (const file of files) {
      const clientMessageId = this.#generateClientId()
      const uploader = new FileUploader(
        file,
        this.formTarget.action,
        clientMessageId,
        () => {},
        { parent_message_id: parentMessageId }
      )

      try {
        const resp = await uploader.upload()
        Turbo.renderStreamMessage(resp)
      } catch (_) {
        // ignore per-file upload failures for now
      }
    }
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

  #serializeCustomEmojisForSubmission() {
    const input = this.textTarget.inputElement
    if (!input?.value.includes("data-custom-emoji-shortcode")) return

    const document = new DOMParser().parseFromString(input.value, "text/html")

    document.querySelectorAll("[data-custom-emoji-shortcode]").forEach((emoji) => {
      emoji.replaceWith(document.createTextNode(emoji.dataset.customEmojiShortcode))
    })

    input.value = document.body.innerHTML
  }

  #setToolbarTogglePressed(pressed) {
    this.element.querySelectorAll("[data-thread-composer-toolbar-toggle]").forEach((button) => {
      button.setAttribute("aria-pressed", pressed)
    })
  }

  #updateFileList() {
    this.#files.sort((a, b) => a.name.localeCompare(b.name))

    const fileNodes = this.#files.map((file, index) => {
      const filename = file.name.split(".").slice(0, -1).join(".")
      const extension = file.name.split(".").pop()

      const node = document.createElement("button")
      node.setAttribute("type", "button")
      node.setAttribute("style", "gap: 0")
      node.dataset.action = "thread-composer#fileUnpicked"
      node.dataset.threadComposerIndexParam = index
      node.className = "btn btn--plain composer__file txt-normal position-relative unpad flex-column"
      node.innerHTML = file.type.match(/^image\/.*/)
        ? `<img role="presentation" class="flex-item-no-shrink composer__file-thumbnail" src="${URL.createObjectURL(file)}">`
        : `<span class="composer__file-thumbnail composer__file-thumbnail--common colorize--black"></span>`
      node.innerHTML += `<span class="pad-inline txt-small flex align-center max-width composer__file-caption"><span class="overflow-ellipsis">${escapeHTML(filename)}.</span><span class="flex-item-no-shrink">${escapeHTML(extension)}</span></span>`

      return node
    })

    this.fileListTarget.replaceChildren(...fileNodes)
  }

  get #usingTouchDevice() {
    return "ontouchstart" in window || navigator.maxTouchPoints > 0
  }
}
