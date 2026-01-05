import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]

  copy() {
    const text = this.sourceTarget.value || this.sourceTarget.textContent
    navigator.clipboard.writeText(text).then(() => {
      this.showFeedback()
    })
  }

  showFeedback() {
    const button = this.element.querySelector('button[data-action="clipboard#copy"]')
    if (button) {
      const originalText = button.textContent
      button.textContent = "Copied!"
      button.classList.add("bg-emerald-600")
      
      setTimeout(() => {
        button.textContent = originalText
        button.classList.remove("bg-emerald-600")
      }, 2000)
    }
  }
}

