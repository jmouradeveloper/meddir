import { Controller } from "@hotwired/stimulus"

// Manages the PWA install prompt
export default class extends Controller {
  static targets = [
    "button", "container", "iosInstructions", "androidPrompt",
    "debugPanel", "debugHttps", "debugSw", "debugPrompt", "debugInstalled", "debugPlatform"
  ]
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
    
    console.log('[PWA Install] Controller connected', {
      isInstalled: this.isInstalled,
      isMobile: this.isMobile,
      isIOS: this.isIOS,
      isAndroid: this.isAndroid,
      wasDismissed: this.wasDismissedRecently(),
      isSecureContext: window.isSecureContext,
      protocol: window.location.protocol
    })
    
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
    console.log('[PWA Install] Install prompt available!', event.detail)
    this.installPrompt = event.detail.prompt
    
    // Update debug info if panel is visible
    if (this.hasDebugPanelTarget && !this.debugPanelTarget.classList.contains('hidden')) {
      this.updateDebugInfo()
    }
    
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
    console.log('[PWA Install] Install button clicked, prompt available:', !!this.installPrompt)
    
    if (!this.installPrompt) {
      console.log('[PWA Install] No install prompt available yet. This can happen if:')
      console.log('  - The browser hasn\'t triggered beforeinstallprompt yet')
      console.log('  - The app is already installed')
      console.log('  - The site is not served over HTTPS (except localhost)')
      console.log('  - The manifest.json is invalid or missing required fields')
      console.log('  - The service worker is not registered')
      
      // Show a helpful message to the user
      if (this.hasButtonTarget) {
        const originalText = this.buttonTarget.innerHTML
        
        // Check if we're in a secure context
        if (!window.isSecureContext) {
          this.buttonTarget.innerHTML = '<span class="text-xs">HTTPS required</span>'
        } else {
          // The browser may need more engagement before showing the prompt
          this.buttonTarget.innerHTML = '<span class="text-xs">Not available yet</span>'
        }
        
        setTimeout(() => {
          this.buttonTarget.innerHTML = originalText
        }, 3000)
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

  // Debug methods
  toggleDebug() {
    if (this.hasDebugPanelTarget) {
      this.debugPanelTarget.classList.toggle('hidden')
      if (!this.debugPanelTarget.classList.contains('hidden')) {
        this.updateDebugInfo()
      }
    }
  }

  hideDebug() {
    if (this.hasDebugPanelTarget) {
      this.debugPanelTarget.classList.add('hidden')
    }
  }

  async updateDebugInfo() {
    // HTTPS status
    if (this.hasDebugHttpsTarget) {
      const isSecure = window.isSecureContext
      this.debugHttpsTarget.textContent = isSecure ? 'Yes' : 'No'
      this.debugHttpsTarget.className = isSecure ? 'text-emerald-400' : 'text-red-400'
    }

    // Service Worker status
    if (this.hasDebugSwTarget) {
      if ('serviceWorker' in navigator) {
        try {
          const registration = await navigator.serviceWorker.getRegistration()
          if (registration) {
            const state = registration.active ? 'Active' : 
                         registration.installing ? 'Installing' : 
                         registration.waiting ? 'Waiting' : 'Unknown'
            this.debugSwTarget.textContent = state
            this.debugSwTarget.className = registration.active ? 'text-emerald-400' : 'text-yellow-400'
          } else {
            this.debugSwTarget.textContent = 'Not registered'
            this.debugSwTarget.className = 'text-red-400'
          }
        } catch (e) {
          this.debugSwTarget.textContent = 'Error'
          this.debugSwTarget.className = 'text-red-400'
        }
      } else {
        this.debugSwTarget.textContent = 'Not supported'
        this.debugSwTarget.className = 'text-red-400'
      }
    }

    // Install Prompt status
    if (this.hasDebugPromptTarget) {
      const hasPrompt = !!this.installPrompt
      this.debugPromptTarget.textContent = hasPrompt ? 'Available' : 'Not available'
      this.debugPromptTarget.className = hasPrompt ? 'text-emerald-400' : 'text-yellow-400'
    }

    // Installed status
    if (this.hasDebugInstalledTarget) {
      this.debugInstalledTarget.textContent = this.isInstalled ? 'Yes' : 'No'
      this.debugInstalledTarget.className = this.isInstalled ? 'text-emerald-400' : 'text-slate-300'
    }

    // Platform
    if (this.hasDebugPlatformTarget) {
      let platform = 'Desktop'
      if (this.isIOS) platform = 'iOS'
      else if (this.isAndroid) platform = 'Android'
      else if (this.isMobile) platform = 'Mobile'
      this.debugPlatformTarget.textContent = platform
    }
  }
}
