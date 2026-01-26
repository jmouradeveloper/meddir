import { Controller } from "@hotwired/stimulus"

// Manages the connection status indicator and offline banner
export default class extends Controller {
  static targets = ["banner", "indicator", "syncCount", "lastSync"]
  static values = {
    showBanner: { type: Boolean, default: true }
  }

  connect() {
    this.isOnline = navigator.onLine
    this.pendingCount = 0
    
    this.setupEventListeners()
    this.updateUI()
    this.checkPendingOperations()
  }

  disconnect() {
    this.removeEventListeners()
  }

  setupEventListeners() {
    // Network status events
    this.handleOnline = this.handleOnline.bind(this)
    this.handleOffline = this.handleOffline.bind(this)
    window.addEventListener('online', this.handleOnline)
    window.addEventListener('offline', this.handleOffline)

    // Sync events
    this.handleSyncStarted = this.handleSyncStarted.bind(this)
    this.handleSyncCompleted = this.handleSyncCompleted.bind(this)
    this.handleSyncFailed = this.handleSyncFailed.bind(this)
    window.addEventListener('sync:sync-started', this.handleSyncStarted)
    window.addEventListener('sync:sync-completed', this.handleSyncCompleted)
    window.addEventListener('sync:sync-failed', this.handleSyncFailed)

    // PWA events
    this.handleUpdateAvailable = this.handleUpdateAvailable.bind(this)
    window.addEventListener('pwa:update-available', this.handleUpdateAvailable)
  }

  removeEventListeners() {
    window.removeEventListener('online', this.handleOnline)
    window.removeEventListener('offline', this.handleOffline)
    window.removeEventListener('sync:sync-started', this.handleSyncStarted)
    window.removeEventListener('sync:sync-completed', this.handleSyncCompleted)
    window.removeEventListener('sync:sync-failed', this.handleSyncFailed)
    window.removeEventListener('pwa:update-available', this.handleUpdateAvailable)
  }

  // ============ Event Handlers ============

  handleOnline() {
    this.isOnline = true
    this.updateUI()
    this.showToast('Back online', 'success')
  }

  handleOffline() {
    this.isOnline = false
    this.updateUI()
    this.showToast('You are offline. Changes will sync when connected.', 'warning')
  }

  handleSyncStarted() {
    this.isSyncing = true
    this.updateUI()
  }

  handleSyncCompleted() {
    this.isSyncing = false
    this.checkPendingOperations()
    this.updateUI()
    this.updateLastSync()
  }

  handleSyncFailed(event) {
    this.isSyncing = false
    this.updateUI()
    this.showToast(`Sync failed: ${event.detail.error}`, 'error')
  }

  handleUpdateAvailable(event) {
    if (confirm('A new version is available. Reload to update?')) {
      event.detail.update()
    }
  }

  // ============ UI Updates ============

  updateUI() {
    // Update banner visibility
    if (this.hasBannerTarget) {
      if (!this.isOnline && this.showBannerValue) {
        this.bannerTarget.classList.remove('hidden')
      } else {
        this.bannerTarget.classList.add('hidden')
      }
    }

    // Update indicator
    if (this.hasIndicatorTarget) {
      this.indicatorTarget.classList.remove('bg-emerald-500', 'bg-amber-500', 'bg-red-500', 'animate-pulse')
      
      if (this.isSyncing) {
        this.indicatorTarget.classList.add('bg-amber-500', 'animate-pulse')
        this.indicatorTarget.title = 'Syncing...'
      } else if (this.isOnline) {
        this.indicatorTarget.classList.add('bg-emerald-500')
        this.indicatorTarget.title = 'Online'
      } else {
        this.indicatorTarget.classList.add('bg-red-500')
        this.indicatorTarget.title = 'Offline'
      }
    }

    // Update sync count
    if (this.hasSyncCountTarget) {
      if (this.pendingCount > 0) {
        this.syncCountTarget.textContent = this.pendingCount
        this.syncCountTarget.classList.remove('hidden')
      } else {
        this.syncCountTarget.classList.add('hidden')
      }
    }
  }

  async checkPendingOperations() {
    if (window.MedDir && window.MedDir.offlineStore) {
      this.pendingCount = await window.MedDir.offlineStore.getPendingCount()
      this.updateUI()
    }
  }

  async updateLastSync() {
    if (this.hasLastSyncTarget && window.MedDir && window.MedDir.offlineStore) {
      const lastSync = await window.MedDir.offlineStore.getLastSyncTime()
      if (lastSync) {
        const date = new Date(lastSync)
        this.lastSyncTarget.textContent = `Last sync: ${this.formatRelativeTime(date)}`
      }
    }
  }

  formatRelativeTime(date) {
    const now = new Date()
    const diff = now - date
    const minutes = Math.floor(diff / 60000)
    const hours = Math.floor(diff / 3600000)
    const days = Math.floor(diff / 86400000)

    if (minutes < 1) return 'Just now'
    if (minutes < 60) return `${minutes}m ago`
    if (hours < 24) return `${hours}h ago`
    return `${days}d ago`
  }

  showToast(message, type = 'info') {
    // Create toast element
    const toast = document.createElement('div')
    toast.className = `fixed bottom-4 right-4 z-50 max-w-sm p-4 rounded-xl shadow-lg backdrop-blur-xl transition-all transform translate-y-2 opacity-0`
    
    const colors = {
      success: 'bg-emerald-500/10 border border-emerald-500/50 text-emerald-300',
      warning: 'bg-amber-500/10 border border-amber-500/50 text-amber-300',
      error: 'bg-red-500/10 border border-red-500/50 text-red-300',
      info: 'bg-blue-500/10 border border-blue-500/50 text-blue-300'
    }
    
    toast.classList.add(...colors[type].split(' '))
    toast.innerHTML = `
      <div class="flex items-center gap-3">
        <span class="text-sm font-medium">${message}</span>
      </div>
    `
    
    document.body.appendChild(toast)
    
    // Animate in
    requestAnimationFrame(() => {
      toast.classList.remove('translate-y-2', 'opacity-0')
    })
    
    // Remove after 4 seconds
    setTimeout(() => {
      toast.classList.add('translate-y-2', 'opacity-0')
      setTimeout(() => toast.remove(), 300)
    }, 4000)
  }

  // ============ Actions ============

  async syncNow() {
    if (window.MedDir && window.MedDir.syncManager) {
      await window.MedDir.syncManager.sync()
    }
  }

  dismissBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.add('hidden')
    }
  }
}
