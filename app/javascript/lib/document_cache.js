// Document Cache Manager - Handle caching of document files for offline access
class DocumentCacheManager {
  constructor() {
    this.cacheName = 'meddir-documents-v1';
    this.maxCacheSize = 500 * 1024 * 1024; // 500MB
    this.cacheQueue = [];
    this.isCaching = false;
  }

  // ============ Public API ============

  // Cache a single document
  async cacheDocument(url) {
    if (!url) return false;

    try {
      const cache = await caches.open(this.cacheName);
      const response = await fetch(url);
      
      if (response.ok) {
        await cache.put(url, response.clone());
        console.log('[DocumentCache] Cached:', url);
        return true;
      }
      return false;
    } catch (error) {
      console.error('[DocumentCache] Failed to cache:', url, error);
      return false;
    }
  }

  // Cache multiple documents (batch)
  async cacheDocuments(urls) {
    const results = [];
    for (const url of urls) {
      const result = await this.cacheDocument(url);
      results.push({ url, success: result });
      
      // Small delay between requests to avoid overwhelming the server
      await this.delay(100);
    }
    return results;
  }

  // Check if document is cached
  async isCached(url) {
    if (!url) return false;

    try {
      const cache = await caches.open(this.cacheName);
      const response = await cache.match(url);
      return !!response;
    } catch (error) {
      return false;
    }
  }

  // Get cached document
  async getDocument(url) {
    if (!url) return null;

    try {
      const cache = await caches.open(this.cacheName);
      return await cache.match(url);
    } catch (error) {
      console.error('[DocumentCache] Failed to get:', url, error);
      return null;
    }
  }

  // Remove document from cache
  async removeDocument(url) {
    if (!url) return false;

    try {
      const cache = await caches.open(this.cacheName);
      return await cache.delete(url);
    } catch (error) {
      console.error('[DocumentCache] Failed to remove:', url, error);
      return false;
    }
  }

  // Clear all cached documents
  async clearAll() {
    try {
      return await caches.delete(this.cacheName);
    } catch (error) {
      console.error('[DocumentCache] Failed to clear cache:', error);
      return false;
    }
  }

  // ============ Automatic Sync ============

  // Sync all documents from a list (called by sync manager)
  async syncDocuments(documents) {
    if (!documents || documents.length === 0) return;

    console.log(`[DocumentCache] Starting sync of ${documents.length} documents`);
    
    const urls = documents
      .filter(doc => doc.file_url)
      .map(doc => doc.file_url);

    // Check cache size before adding new files
    await this.enforceStorageLimit();

    // Queue documents for caching
    for (const url of urls) {
      this.addToQueue(url);
    }

    // Process queue
    await this.processQueue();
  }

  addToQueue(url) {
    if (!this.cacheQueue.includes(url)) {
      this.cacheQueue.push(url);
    }
  }

  async processQueue() {
    if (this.isCaching || this.cacheQueue.length === 0) return;

    this.isCaching = true;
    this.dispatchEvent('cache-started', { count: this.cacheQueue.length });

    let cached = 0;
    let failed = 0;

    while (this.cacheQueue.length > 0) {
      const url = this.cacheQueue.shift();
      
      // Skip if already cached
      if (await this.isCached(url)) {
        continue;
      }

      const success = await this.cacheDocument(url);
      if (success) {
        cached++;
      } else {
        failed++;
      }

      // Update progress
      this.dispatchEvent('cache-progress', { 
        cached, 
        failed, 
        remaining: this.cacheQueue.length 
      });

      // Small delay to not overwhelm
      await this.delay(200);
    }

    this.isCaching = false;
    this.dispatchEvent('cache-completed', { cached, failed });
    console.log(`[DocumentCache] Sync complete. Cached: ${cached}, Failed: ${failed}`);
  }

  // ============ Storage Management ============

  async getStorageInfo() {
    try {
      const cache = await caches.open(this.cacheName);
      const keys = await cache.keys();
      
      let totalSize = 0;
      const files = [];

      for (const request of keys) {
        const response = await cache.match(request);
        if (response) {
          const blob = await response.clone().blob();
          files.push({
            url: request.url,
            size: blob.size,
            type: blob.type
          });
          totalSize += blob.size;
        }
      }

      return {
        count: files.length,
        totalSize,
        totalSizeMB: (totalSize / 1024 / 1024).toFixed(2),
        files
      };
    } catch (error) {
      console.error('[DocumentCache] Failed to get storage info:', error);
      return { count: 0, totalSize: 0, totalSizeMB: '0', files: [] };
    }
  }

  async enforceStorageLimit() {
    const info = await this.getStorageInfo();
    
    if (info.totalSize < this.maxCacheSize) {
      return; // Still under limit
    }

    console.log(`[DocumentCache] Cache size (${info.totalSizeMB}MB) exceeds limit. Cleaning...`);

    // Sort files by size (largest first) and remove until under limit
    const sortedFiles = info.files.sort((a, b) => b.size - a.size);
    let currentSize = info.totalSize;

    for (const file of sortedFiles) {
      if (currentSize < this.maxCacheSize * 0.8) {
        break; // Keep 20% buffer
      }

      await this.removeDocument(file.url);
      currentSize -= file.size;
      console.log(`[DocumentCache] Removed ${file.url} (${(file.size / 1024 / 1024).toFixed(2)}MB)`);
    }
  }

  // ============ Preloading ============

  // Preload documents for a specific folder
  async preloadFolder(folderId) {
    try {
      const response = await fetch(`/medical_folders/${folderId}/documents.json`);
      if (response.ok) {
        const data = await response.json();
        const urls = data.documents
          .filter(doc => doc.file_url)
          .map(doc => doc.file_url);
        
        await this.cacheDocuments(urls);
        return urls.length;
      }
    } catch (error) {
      console.error('[DocumentCache] Failed to preload folder:', error);
    }
    return 0;
  }

  // Preload all user documents
  async preloadAll() {
    try {
      const response = await fetch('/medical_folders.json');
      if (response.ok) {
        const data = await response.json();
        
        for (const folder of data.folders) {
          await this.preloadFolder(folder.id);
        }
        
        return true;
      }
    } catch (error) {
      console.error('[DocumentCache] Failed to preload all:', error);
    }
    return false;
  }

  // ============ Utilities ============

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  dispatchEvent(name, detail = {}) {
    window.dispatchEvent(new CustomEvent(`document-cache:${name}`, { detail }));
  }
}

// Export singleton instance
const documentCache = new DocumentCacheManager();
export default documentCache;
