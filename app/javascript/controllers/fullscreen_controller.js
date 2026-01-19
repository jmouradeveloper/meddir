import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "modalContent"]

  connect() {
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    console.log("Fullscreen controller connected", this.hasModalTarget)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
    document.body.classList.remove("overflow-hidden")
  }

  open() {
    console.log("Opening fullscreen modal")
    if (!this.hasModalTarget) {
      console.error("Modal target not found")
      return
    }
    
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    document.addEventListener("keydown", this.boundHandleKeydown)
    
    // Animate in (use setTimeout to ensure the hidden class is removed first)
    setTimeout(() => {
      this.modalTarget.classList.remove("opacity-0")
      this.modalTarget.classList.add("opacity-100")
      this.modalContentTarget.classList.remove("scale-95")
      this.modalContentTarget.classList.add("scale-100")
    }, 10)
  }

  close() {
    console.log("Closing fullscreen modal")
    this.modalTarget.classList.remove("opacity-100")
    this.modalTarget.classList.add("opacity-0")
    this.modalContentTarget.classList.remove("scale-100")
    this.modalContentTarget.classList.add("scale-95")
    
    setTimeout(() => {
      this.modalTarget.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
      document.removeEventListener("keydown", this.boundHandleKeydown)
    }, 200)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }
}
