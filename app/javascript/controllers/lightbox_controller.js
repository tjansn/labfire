import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "image", "dialog", "zoomedImage", "download", "share" ]

  open(event) {
    event.preventDefault()

    this.dialogTarget.showModal()
    this.#set(event.target.closest("a"))
  }

  reset() {
    this.zoomedImageTarget.src = ""
    this.zoomedImageTarget.alt = ""
    this.downloadTarget.href = ""
    this.shareTarget.dataset.webShareFilesValue = ""
  }

  #set(target) {
    const filename = target.dataset.lightboxFilenameValue || ""
    this.zoomedImageTarget.src = target.href
    this.zoomedImageTarget.alt = filename
    this.dialogTarget.setAttribute(
      "aria-label",
      filename ? `Image viewer — ${filename}. Press Escape to close.` : "Image viewer. Press Escape to close."
    )
    this.downloadTarget.href = target.dataset.lightboxUrlValue
    this.shareTarget.dataset.webShareFilesValue = target.dataset.lightboxUrlValue
  }
}
