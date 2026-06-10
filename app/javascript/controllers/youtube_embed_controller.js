import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { videoId: String }

  play() {
    const iframe = document.createElement("iframe")
    iframe.src = `https://www.youtube-nocookie.com/embed/${encodeURIComponent(this.videoIdValue)}?autoplay=1`
    iframe.allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    iframe.allowFullscreen = true
    iframe.title = "YouTube video player"

    this.element.classList.add("yt-embed--playing")
    this.element.replaceChildren(iframe)
  }
}
