import { Controller } from "@hotwired/stimulus"
import { cable } from "@hotwired/turbo-rails"
import { ignoringBriefDisconnects } from "helpers/dom_helpers"

export default class extends Controller {
  static targets = [ "room" ]
  static classes = [ "unread", "current", "active" ]

  #disconnected = true

  async connect() {
    this.channel ??= await cable.subscribeTo({ channel: "UnreadRoomsChannel" }, {
      connected: this.#channelConnected.bind(this),
      disconnected: this.#channelDisconnected.bind(this),
      received: this.#unread.bind(this)
    })
  }

  disconnect() {
    ignoringBriefDisconnects(this.element, () => {
      this.channel?.unsubscribe()
      this.channel = null
    })
  }

  loaded() {
    if (Current.room?.id) {
      this.#markCurrent(Current.room.id)
      this.read({ detail: { roomId: Current.room.id } })
    }
  }

  read({ detail: { roomId } }) {
    const room = this.#findRoomTarget(roomId)

    if (room) {
      room.classList.remove(this.unreadClass)
      this.dispatch("read", { detail: { targetId: roomId } })
    }
  }

  select(event) {
    if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return

    const room = event.target.closest(`[data-${this.identifier}-target~="room"]`)

    if (room && this.element.contains(room)) {
      this.#markCurrent(room.dataset.roomId)
      this.read({ detail: { roomId: room.dataset.roomId } })
    }
  }

  #channelConnected() {
    if (this.#disconnected) {
      this.#disconnected = false
      this.element.reload()
    }
  }

  #channelDisconnected() {
    this.#disconnected = true
  }

  #markCurrent(roomId) {
    this.roomTargets.forEach((roomTarget) => {
      const isCurrent = roomTarget.dataset.roomId == roomId

      roomTarget.classList.toggle(this.currentClass, isCurrent)
      if (this.hasActiveClass) roomTarget.classList.toggle(this.activeClass, isCurrent)
      if (isCurrent) roomTarget.setAttribute("aria-current", "page")
      else roomTarget.removeAttribute("aria-current")
    })
  }

  #unread({ roomId }) {
    const unreadRoom = this.#findRoomTarget(roomId)

    if (unreadRoom) {
      if (Current.room?.id != roomId) {
        unreadRoom.classList.add(this.unreadClass)
      }

      this.dispatch("unread", { detail: { targetId: unreadRoom.id } })
    }
  }

  #findRoomTarget(roomId) {
    return this.roomTargets.find(roomTarget => roomTarget.dataset.roomId == roomId)
  }
}
