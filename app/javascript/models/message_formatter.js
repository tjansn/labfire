import { onNextEventLoopTick } from "helpers/timing_helpers"

const GROUPING_TIME_WINDOW_MILLISECONDS = 5 * 1000 // 5 seconds
const THREADING_TIME_WINDOW_MILLISECONDS = 5 * 60 * 1000 // 5 minutes

export const ThreadStyle = {
  none: 0,
  thread: 1,
}

export default class MessageFormatter {
  #userId
  #classes
  #dateFormatter = new Intl.DateTimeFormat(undefined, { dateStyle: "short" })

  constructor(userId, classes) {
    this.#userId = userId
    this.#classes = classes
  }

  format(message, threadstyle) {
    this.#setMeClass(message)
    this.#highlightMentions(message)

    if (threadstyle != ThreadStyle.none) {
      this.#threadMessage(message)
      this.#setFirstOfDayClass(message)
    }

    this.#makeVisible(message)
  }

  formatBody(body) {
    this.#highlightCode(body)
  }

  #setMeClass(message) {
    const isMe = message.dataset.userId == this.#userId
    message.classList.toggle(this.#classes.me, isMe)
  }

  #makeVisible(message) {
    message.classList.add(this.#classes.formatted)
  }

  #setFirstOfDayClass(message) {
    let showSeparator = true

    if (message.dataset.messageTimestamp && message.previousElementSibling?.dataset?.messageTimestamp) {
      const prev = new Date(Number(message.previousElementSibling.dataset.messageTimestamp))
      const curr = new Date(Number(message.dataset.messageTimestamp))

      showSeparator = this.#dateFormatter.format(prev) !== this.#dateFormatter.format(curr)
    }

    message.classList.toggle(this.#classes.firstOfDay, showSeparator)
  }

  #threadMessage(message) {
    const previousMessage = message.previousElementSibling

    if (previousMessage) {
      const isSameUser = previousMessage.dataset.userId == message.dataset.userId
      const threadedWithPrevious = isSameUser && this.#previousMessageIsWithin(message, THREADING_TIME_WINDOW_MILLISECONDS)
      const groupedWithPrevious = isSameUser && this.#previousMessageIsWithin(message, GROUPING_TIME_WINDOW_MILLISECONDS)

      message.classList.toggle(this.#classes.threaded, threadedWithPrevious)
      message.classList.toggle(this.#classes.grouped, groupedWithPrevious)
      previousMessage.classList.toggle(this.#classes.continued, groupedWithPrevious)
    } else {
      message.classList.remove(this.#classes.threaded, this.#classes.grouped)
    }
  }

  #highlightMentions(message) {
    const mentionsCurrentUser = message.querySelector(this.#selectorForCurrentUser) !== null
    message.classList.toggle(this.#classes.mentioned, mentionsCurrentUser)
  }

  #highlightCode(body) {
    body.querySelectorAll("pre").forEach(block => {
      onNextEventLoopTick(() => this.#highlightCodeBlock(block))
    })
  }

  #highlightCodeBlock(block) {
    if (this.#isPlainText(block)) window.hljs.highlightElement(block)
  }

  #isPlainText(element) {
    return Array.from(element.childNodes).every(node => node.nodeType === Node.TEXT_NODE)
  }

  #previousMessageIsWithin(message, milliseconds) {
    const previousTimestamp = message.previousElementSibling.dataset.messageTimestamp
    const threadTimestamp = message.dataset.messageTimestamp
    return Math.abs(previousTimestamp - threadTimestamp) <= milliseconds
  }

  get #selectorForCurrentUser() {
    return `.mention img[src^="/users/${Current.user.id}/avatar"]`
  }
}
