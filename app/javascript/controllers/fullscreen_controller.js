import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "expandIcon", "compressIcon"]

  connect() {
    this.boundHandleFullscreenChange = this.handleFullscreenChange.bind(this)
    document.addEventListener("fullscreenchange", this.boundHandleFullscreenChange)
  }

  disconnect() {
    document.removeEventListener("fullscreenchange", this.boundHandleFullscreenChange)
  }

  toggle() {
    if (document.fullscreenElement) {
      document.exitFullscreen()
    } else {
      this.containerTarget.requestFullscreen()
    }
  }

  handleFullscreenChange() {
    const isFullscreen = !!document.fullscreenElement

    if (this.hasExpandIconTarget && this.hasCompressIconTarget) {
      this.expandIconTargets.forEach(el => el.classList.toggle("hidden", isFullscreen))
      this.compressIconTargets.forEach(el => el.classList.toggle("hidden", !isFullscreen))
    }

    if (this.hasContainerTarget) {
      this.containerTarget.classList.toggle("is-fullscreen", isFullscreen)
    }
  }
}
