class Current {
  get user() {
    const currentUserId = this.#extractContentFromMetaTag("current-user-id")

    if (currentUserId) {
      return { id: parseInt(currentUserId), name: this.#extractContentFromMetaTag("current-user-name") }
    }
  }

  get room() {
    const currentRoomId = document.body?.dataset.currentRoomId || this.#extractContentFromMetaTag("current-room-id")

    if (currentRoomId) {
      return { id: parseInt(currentRoomId) }
    }
  }

  #extractContentFromMetaTag(name) {
    const metaTags = document.head.querySelectorAll(`meta[name="${name}"]`)

    return metaTags[metaTags.length - 1]?.getAttribute("content")
  }
}

window.Current = new Current()
