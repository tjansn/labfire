import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "image", "input", "placeholder" ]

  previewImage() {
    const file = this.inputTarget.files[0]

    if (file) {
      this.imageTarget.src = URL.createObjectURL(this.inputTarget.files[0]);
      this.imageTarget.onload = () => { URL.revokeObjectURL(this.imageTarget.src) }
      if (this.hasPlaceholderTarget) this.placeholderTarget.hidden = true
      this.element.classList.remove("gl-avatar-upload--empty", "gl-join-avatar-upload--empty")
    }
  }
}
