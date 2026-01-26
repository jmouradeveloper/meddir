// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// PWA support - register service worker and manage offline functionality
import pwa from "lib/pwa"
import offlineStore from "lib/offline_store"
import syncManager from "lib/sync_manager"
import documentCache from "lib/document_cache"

// Expose PWA utilities globally for access from Stimulus controllers
window.MedDir = {
  pwa,
  offlineStore,
  syncManager,
  documentCache
}
