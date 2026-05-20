import { Controller } from "@hotwired/stimulus"
import MessageFormatter, { ThreadStyle } from "models/message_formatter"

export default class extends Controller {
  static classes = ["firstOfDay", "formatted", "me", "mentioned", "grouped", "continued", "threaded"]

  #formatter
  #observer

  initialize() {
    this.#formatter = new MessageFormatter(Current.user.id, {
      firstOfDay: this.firstOfDayClass,
      formatted: this.formattedClass,
      me: this.meClass,
      mentioned: this.mentionedClass,
      grouped: this.groupedClass,
      continued: this.continuedClass,
      threaded: this.threadedClass,
    })

    this.#observer = new MutationObserver(records => {
      for (const record of records) {
        for (const node of record.addedNodes) {
          if (node.nodeType !== Node.ELEMENT_NODE) continue
          this.#formatTree(node)
        }
      }
    })
  }

  connect() {
    this.#formatTree(this.element)
    this.#observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    this.#observer.disconnect()
  }

  #formatTree(root) {
    if (root.matches?.(".message")) {
      this.#format(root)
    }
    root.querySelectorAll?.(".message").forEach(message => this.#format(message))
  }

  #format(message) {
    this.#formatter.format(message, ThreadStyle.thread)

    const body = message.querySelector("[data-messages-target='body']")
    if (body) this.#formatter.formatBody(body)
  }
}
