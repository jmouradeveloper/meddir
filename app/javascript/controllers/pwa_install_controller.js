import { Controller } from "@hotwired/stimulus"

// Manages the PWA install prompt
export default class extends Controller {
  static targets = ["button", "container", "iosInstructions", "androidPrompt"]
  static values = {
    dismissDays: { type: Number, default: 7 },
    showDelay: { type: Number, default: 1500 }
  }

  connect() {
    this.installPrompt = null
    this.isInstalled = this.checkIfInstalled()
    this.isMobile = this.checkIfMobile()
    this.isIOS = this.checkIfIOS()
    this.isAndroid = this.checkIfAndroid()
    
    this.setupEventListeners()
    
    // On mobile, show prompt after a delay (simulates post-login notification)
    if (this.isMobile && !this.isInstalled && !this.wasDismissedRecently()) {
      setTimeout(() => this.showMobilePrompt(), this.showDelayValue)
    }
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

  checkIfMobile() {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ||
           (navigator.maxTouchPoints && navigator.maxTouchPoints > 2)
  }

  checkIfIOS() {
    return /iPad|iPhone|iPod/.test(navigator.userAgent) ||
           (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)
  }

  checkIfAndroid() {
    return /Android/i.test(navigator.userAgent)
  }

  wasDismissedRecently() {
    const dismissedAt = localStorage.getItem('pwa-install-dismissed')
    if (!dismissedAt) return false
    
    const dismissedDate = new Date(parseInt(dismissedAt, 10))
    const daysSinceDismiss = (Date.now() - dismissedDate.getTime()) / (1000 * 60 * 60 * 24)
    
    return daysSinceDismiss < this.dismissDaysValue
  }

  showMobilePrompt() {
    if (this.isInstalled || this.wasDismissedRecently()) return
    
    // For iOS, show manual instructions since beforeinstallprompt is not supported
    if (this.isIOS) {
      this.showIOSInstructions()
    } else if (this.installPrompt) {
      // Android with install prompt available
      this.showContainer()
    } else {
      // Android without prompt yet - show anyway, install button will trigger when ready
      this.showContainer()
    }
  }

  showIOSInstructions() {
    if (this.hasContainerTarget) {
      this.containerTarget.classList.remove('hidden')
      this.containerTarget.setAttribute('data-ios', 'true')
    }
    if (this.hasIosInstructionsTarget) {
      this.iosInstructionsTarget.classList.remove('hidden')
    }
    if (this.hasAndroidPromptTarget) {
      this.androidPromptTarget.classList.add('hidden')
    }
  }

  showContainer() {
    if (this.hasContainerTarget) {
      this.containerTarget.classList.remove('hidden')
      this.containerTarget.removeAttribute('data-ios')
    }
    if (this.hasIosInstructionsTarget) {
      this.iosInstructionsTarget.classList.add('hidden')
    }
    if (this.hasAndroidPromptTarget) {
      this.androidPromptTarget.classList.remove('hidden')
    }
  }

  handleInstallAvailable(event) {
    this.installPrompt = event.detail.prompt
    
    // If we're on mobile and not dismissed, show the prompt
    if (this.isMobile && !this.wasDismissedRecently() && !this.isInstalled) {
      this.showContainer()
    }
  }

  handleInstalled() {
    this.isInstalled = true
    this.installPrompt = null
    this.hide()
  }

  hide() {
    if (this.hasContainerTarget) {
      this.containerTarget.classList.add('hidden')
    }
  }

  async install() {
    if (!this.installPrompt) {
      console.log('[PWA Install] No install prompt available yet')
      // On Android, the prompt might not be ready yet
      // Show a message to the user
      if (this.hasButtonTarget) {
        const originalText = this.buttonTarget.innerHTML
        this.buttonTarget.innerHTML = '<span class="animate-pulse">Preparing...</span>'
        setTimeout(() => {
          this.buttonTarget.innerHTML = originalText
        }, 2000)
      }
      return
    }

    // Show the install prompt
    this.installPrompt.prompt()
    
    // Wait for the user to respond
    const { outcome } = await this.installPrompt.userChoice
    
    console.log(`[PWA Install] User ${outcome === 'accepted' ? 'accepted' : 'dismissed'} the install prompt`)
    
    // Clear the prompt
    this.installPrompt = null
    
    if (outcome === 'accepted') {
      this.hide()
    }
  }

  dismiss() {
    this.hide()
    
    // Store dismissal in localStorage to not show again for configured days
    localStorage.setItem('pwa-install-dismissed', Date.now().toString())
  }
}
