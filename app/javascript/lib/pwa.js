// PWA Manager - Service Worker registration and management
class PWAManager {
  constructor() {
    this.registration = null;
    this.isOnline = navigator.onLine;
    this.pendingSyncCount = 0;
    
    this.init();
  }

  async init() {
    // Register service worker
    if ('serviceWorker' in navigator) {
      try {
        this.registration = await navigator.serviceWorker.register('/service-worker.js', {
          scope: '/'
        });
        
        console.log('[PWA] Service Worker registered:', this.registration.scope);
        
        // Handle updates
        this.registration.addEventListener('updatefound', () => {
          this.handleUpdateFound();
        });
        
        // Listen for messages from service worker
        navigator.serviceWorker.addEventListener('message', (event) => {
          this.handleServiceWorkerMessage(event);
        });
        
      } catch (error) {
        console.error('[PWA] Service Worker registration failed:', error);
      }
    }
    
    // Setup online/offline detection
    this.setupNetworkDetection();
    
    // Setup install prompt
    this.setupInstallPrompt();
  }

  handleUpdateFound() {
    const newWorker = this.registration.installing;
    
    newWorker.addEventListener('statechange', () => {
      if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
        // New version available
        this.showUpdateNotification();
      }
    });
  }

  handleServiceWorkerMessage(event) {
    const { data } = event;
    
    if (data.type === 'SYNC_REQUIRED') {
      // Trigger sync from the app
      window.dispatchEvent(new CustomEvent('pwa:sync-required'));
    }
  }

  setupNetworkDetection() {
    window.addEventListener('online', () => {
      this.isOnline = true;
      document.body.classList.remove('offline');
      document.body.classList.add('online');
      window.dispatchEvent(new CustomEvent('pwa:online'));
      console.log('[PWA] Back online');
    });

    window.addEventListener('offline', () => {
      this.isOnline = false;
      document.body.classList.remove('online');
      document.body.classList.add('offline');
      window.dispatchEvent(new CustomEvent('pwa:offline'));
      console.log('[PWA] Gone offline');
    });

    // Set initial state
    if (this.isOnline) {
      document.body.classList.add('online');
    } else {
      document.body.classList.add('offline');
    }
  }

  setupInstallPrompt() {
    let deferredPrompt = null;

    window.addEventListener('beforeinstallprompt', (event) => {
      // Prevent the mini-infobar from appearing on mobile
      event.preventDefault();
      deferredPrompt = event;
      
      // Show install button/notification
      window.dispatchEvent(new CustomEvent('pwa:install-available', { 
        detail: { prompt: deferredPrompt } 
      }));
    });

    window.addEventListener('appinstalled', () => {
      deferredPrompt = null;
      window.dispatchEvent(new CustomEvent('pwa:installed'));
      console.log('[PWA] App installed');
    });
    
    // Expose install method
    this.install = async () => {
      if (!deferredPrompt) {
        console.log('[PWA] Install prompt not available');
        return false;
      }
      
      deferredPrompt.prompt();
      const { outcome } = await deferredPrompt.userChoice;
      deferredPrompt = null;
      
      return outcome === 'accepted';
    };
  }

  showUpdateNotification() {
    // Dispatch event for UI to handle
    window.dispatchEvent(new CustomEvent('pwa:update-available', {
      detail: {
        update: () => {
          if (this.registration.waiting) {
            this.registration.waiting.postMessage({ type: 'SKIP_WAITING' });
          }
          window.location.reload();
        }
      }
    }));
  }

  // Cache a specific document
  async cacheDocument(url) {
    if (this.registration && this.registration.active) {
      this.registration.active.postMessage({
        type: 'CACHE_DOCUMENT',
        url: url
      });
    }
  }

  // Clear document cache
  async clearDocumentCache() {
    if (this.registration && this.registration.active) {
      this.registration.active.postMessage({
        type: 'CLEAR_DOCUMENT_CACHE'
      });
    }
  }

  // Get cache status
  async getCacheStatus() {
    return new Promise((resolve) => {
      if (!this.registration || !this.registration.active) {
        resolve({ caches: {}, totalSize: 0 });
        return;
      }
      
      const messageChannel = new MessageChannel();
      messageChannel.port1.onmessage = (event) => {
        resolve(event.data);
      };
      
      this.registration.active.postMessage(
        { type: 'GET_CACHE_STATUS' },
        [messageChannel.port2]
      );
    });
  }

  // Check if app is running as installed PWA
  isStandalone() {
    return window.matchMedia('(display-mode: standalone)').matches ||
           window.navigator.standalone === true;
  }
}

// Export singleton instance
const pwa = new PWAManager();
export default pwa;
