import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]
  static values = {
    open: { type: Boolean, default: true }
  }

  connect() {
    this.updateState()
  }

  toggle() {
    this.openValue = !this.openValue
    this.updateState()
  }

  updateState() {
    if (this.openValue) {
      this.expand()
    } else {
      this.collapse()
    }
  }

  expand() {
    this.contentTarget.classList.remove("hidden")
    this.iconTarget.style.transform = "rotate(0deg)"
  }

  collapse() {
    this.contentTarget.classList.add("hidden")
    this.iconTarget.style.transform = "rotate(180deg)"
  }
}
