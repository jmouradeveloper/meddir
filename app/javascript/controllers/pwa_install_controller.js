import { Controller } from "@hotwired/stimulus"

// Manages the PWA install prompt
export default class extends Controller {
  static targets = ["button", "container"]

  connect() {
    this.installPrompt = null
    this.isInstalled = this.checkIfInstalled()
    
    this.setupEventListeners()
    this.updateVisibility()
  }

  disconnect() {
    this.removeEventListeners()
  }

  setupEventListeners() {
    this.handleInstallAvailable = this.handleInstallAvailable.bind(this)
    this.handleInstalled = this.handleInstalled.bind(this)
    
    window.addEventListener('pwa:install-available', this.handleInstallAvailable)
    window.addEventListener('pwa:installed', this.handleInstalled)
  }

  removeEventListeners() {
    window.removeEventListener('pwa:install-available', this.handleInstallAvailable)
    window.removeEventListener('pwa:installed', this.handleInstalled)
  }

  checkIfInstalled() {
    // Check if running as standalone PWA
    return window.matchMedia('(display-mode: standalone)').matches ||
           window.navigator.standalone === true
  }

  handleInstallAvailable(event) {
    this.installPrompt = event.detail.prompt
    this.updateVisibility()
  }

  handleInstalled() {
    this.isInstalled = true
    this.installPrompt = null
    this.updateVisibility()
  }

  updateVisibility() {
    if (this.hasContainerTarget) {
      if (this.installPrompt && !this.isInstalled) {
        this.containerTarget.classList.remove('hidden')
      } else {
        this.containerTarget.classList.add('hidden')
      }
    }
  }

  async install() {
    if (!this.installPrompt) {
      console.log('[PWA Install] No install prompt available')
      return
    }

    // Show the install prompt
    this.installPrompt.prompt()
    
    // Wait for the user to respond
    const { outcome } = await this.installPrompt.userChoice
    
    console.log(`[PWA Install] User ${outcome === 'accepted' ? 'accepted' : 'dismissed'} the install prompt`)
    
    // Clear the prompt
    this.installPrompt = null
    this.updateVisibility()
  }

  dismiss() {
    if (this.hasContainerTarget) {
      this.containerTarget.classList.add('hidden')
    }
    
    // Store dismissal in localStorage to not show again for a while
    localStorage.setItem('pwa-install-dismissed', Date.now().toString())
  }
}
