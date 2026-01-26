// Sync Manager - Handle background synchronization of offline data
import offlineStore from "lib/offline_store";
import documentCache from "lib/document_cache";

class SyncManager {
  constructor() {
    this.isSyncing = false;
    this.syncQueue = [];
    this.retryDelay = 5000; // 5 seconds
    this.maxRetries = 3;
    
    this.init();
  }

  init() {
    // Listen for online event
    window.addEventListener('online', () => {
      console.log('[SyncManager] Online - starting sync');
      this.syncAll();
    });

    // Listen for PWA sync events
    window.addEventListener('pwa:sync-required', () => {
      this.syncAll();
    });

    // Register for background sync if supported
    this.registerBackgroundSync();

    // Initial sync check if online
    if (navigator.onLine) {
      // Delay initial sync to allow page load
      setTimeout(() => this.syncAll(), 2000);
    }
  }

  async registerBackgroundSync() {
    if ('serviceWorker' in navigator && 'SyncManager' in window) {
      try {
        const registration = await navigator.serviceWorker.ready;
        await registration.sync.register('sync-pending-operations');
        console.log('[SyncManager] Background sync registered');
      } catch (error) {
        console.log('[SyncManager] Background sync not supported:', error);
      }
    }
  }

  // ============ Main Sync Methods ============

  async syncAll() {
    if (this.isSyncing) {
      console.log('[SyncManager] Sync already in progress');
      return;
    }

    if (!navigator.onLine) {
      console.log('[SyncManager] Offline - skipping sync');
      return;
    }

    this.isSyncing = true;
    this.dispatchEvent('sync-started');

    try {
      // First, push local changes to server
      await this.pushPendingOperations();

      // Then, fetch latest data from server
      await this.pullFromServer();

      await offlineStore.setLastSyncTime();
      this.dispatchEvent('sync-completed');
      console.log('[SyncManager] Sync completed successfully');

    } catch (error) {
      console.error('[SyncManager] Sync failed:', error);
      this.dispatchEvent('sync-failed', { error: error.message });
    } finally {
      this.isSyncing = false;
    }
  }

  async pushPendingOperations() {
    const operations = await offlineStore.getPendingOperations();
    
    if (operations.length === 0) {
      console.log('[SyncManager] No pending operations');
      return;
    }

    console.log(`[SyncManager] Processing ${operations.length} pending operations`);

    for (const operation of operations) {
      try {
        await this.processOperation(operation);
        await offlineStore.removePendingOperation(operation.id);
      } catch (error) {
        console.error('[SyncManager] Operation failed:', operation, error);
        
        // Increment attempts
        const attempts = (operation.attempts || 0) + 1;
        
        if (attempts >= this.maxRetries) {
          // Mark as failed, don't retry
          await offlineStore.updatePendingOperation(operation.id, {
            attempts,
            failed: true,
            error: error.message
          });
        } else {
          await offlineStore.updatePendingOperation(operation.id, { attempts });
        }
      }
    }
  }

  async processOperation(operation) {
    const { type, entity_type, entity_id, data, has_file } = operation;

    switch (entity_type) {
      case 'medical_folder':
        return this.syncFolder(type, entity_id, data);
      case 'document':
        return this.syncDocument(type, entity_id, data, has_file);
      default:
        throw new Error(`Unknown entity type: ${entity_type}`);
    }
  }

  // ============ Folder Sync ============

  async syncFolder(type, entityId, data) {
    const csrfToken = this.getCsrfToken();

    switch (type) {
      case 'create': {
        const response = await fetch('/medical_folders.json', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken
          },
          body: JSON.stringify({ medical_folder: data })
        });

        if (!response.ok) {
          throw new Error(`Failed to create folder: ${response.status}`);
        }

        const serverFolder = await response.json();
        await offlineStore.markAsSynced('medical_folder', entityId, serverFolder.id);
        return serverFolder;
      }

      case 'update': {
        const response = await fetch(`/medical_folders/${entityId}.json`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken
          },
          body: JSON.stringify({ medical_folder: data })
        });

        if (!response.ok) {
          throw new Error(`Failed to update folder: ${response.status}`);
        }

        return response.json();
      }

      case 'delete': {
        const response = await fetch(`/medical_folders/${entityId}.json`, {
          method: 'DELETE',
          headers: {
            'X-CSRF-Token': csrfToken
          }
        });

        if (!response.ok && response.status !== 404) {
          throw new Error(`Failed to delete folder: ${response.status}`);
        }

        return true;
      }

      default:
        throw new Error(`Unknown operation type: ${type}`);
    }
  }

  // ============ Document Sync ============

  async syncDocument(type, entityId, data, hasFile) {
    const csrfToken = this.getCsrfToken();
    const document = await offlineStore.getDocument(entityId);

    switch (type) {
      case 'create': {
        const folderId = document?.medical_folder_id || data.medical_folder_id;
        
        // If document has a file blob, use FormData
        if (hasFile && document?.file_blob) {
          const formData = new FormData();
          formData.append('document[title]', data.title);
          if (data.document_date) formData.append('document[document_date]', data.document_date);
          if (data.notes) formData.append('document[notes]', data.notes);
          formData.append('document[file]', document.file_blob, document.file_name);

          const response = await fetch(`/medical_folders/${folderId}/documents.json`, {
            method: 'POST',
            headers: {
              'X-CSRF-Token': csrfToken
            },
            body: formData
          });

          if (!response.ok) {
            throw new Error(`Failed to create document: ${response.status}`);
          }

          const serverDoc = await response.json();
          await offlineStore.markAsSynced('document', entityId, serverDoc.id);
          return serverDoc;
        } else {
          // No file, send as JSON
          const response = await fetch(`/medical_folders/${folderId}/documents.json`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': csrfToken
            },
            body: JSON.stringify({ document: data })
          });

          if (!response.ok) {
            throw new Error(`Failed to create document: ${response.status}`);
          }

          const serverDoc = await response.json();
          await offlineStore.markAsSynced('document', entityId, serverDoc.id);
          return serverDoc;
        }
      }

      case 'update': {
        const folderId = document?.medical_folder_id || data.medical_folder_id;
        
        const response = await fetch(`/medical_folders/${folderId}/documents/${entityId}.json`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken
          },
          body: JSON.stringify({ document: data })
        });

        if (!response.ok) {
          throw new Error(`Failed to update document: ${response.status}`);
        }

        return response.json();
      }

      case 'delete': {
        const folderId = document?.medical_folder_id || data?.medical_folder_id;
        
        if (!folderId) {
          console.warn('[SyncManager] Cannot delete document without folder ID');
          return true;
        }

        const response = await fetch(`/medical_folders/${folderId}/documents/${entityId}.json`, {
          method: 'DELETE',
          headers: {
            'X-CSRF-Token': csrfToken
          }
        });

        if (!response.ok && response.status !== 404) {
          throw new Error(`Failed to delete document: ${response.status}`);
        }

        return true;
      }

      default:
        throw new Error(`Unknown operation type: ${type}`);
    }
  }

  // ============ Pull from Server ============

  async pullFromServer() {
    console.log('[SyncManager] Pulling data from server...');

    try {
      // Fetch all folders
      const foldersResponse = await fetch('/medical_folders.json', {
        headers: {
          'Accept': 'application/json'
        }
      });

      if (foldersResponse.ok) {
        const data = await foldersResponse.json();
        await offlineStore.syncFoldersFromServer(data.folders);
        console.log(`[SyncManager] Synced ${data.folders.length} folders`);

        // For each folder, fetch documents
        for (const folder of data.folders) {
          await this.pullDocumentsForFolder(folder.id);
        }
      }
    } catch (error) {
      console.error('[SyncManager] Failed to pull from server:', error);
    }
  }

  async pullDocumentsForFolder(folderId) {
    try {
      const response = await fetch(`/medical_folders/${folderId}/documents.json`, {
        headers: {
          'Accept': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        await offlineStore.syncDocumentsFromServer(data.documents);
        
        // Cache document files
        for (const doc of data.documents) {
          if (doc.file_url) {
            this.cacheDocumentFile(doc.file_url);
          }
        }
      }
    } catch (error) {
      console.error(`[SyncManager] Failed to pull documents for folder ${folderId}:`, error);
    }
  }

  // ============ Document File Caching ============

  async cacheDocumentFile(url) {
    // Use the document cache manager for better control
    await documentCache.cacheDocument(url);
  }

  async cacheAllDocumentsForFolder(folderId) {
    await documentCache.preloadFolder(folderId);
  }

  // ============ Utility Methods ============

  getCsrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.content : '';
  }

  dispatchEvent(name, detail = {}) {
    window.dispatchEvent(new CustomEvent(`sync:${name}`, { detail }));
  }

  // Get sync status
  async getStatus() {
    const pending = await offlineStore.getPendingCount();
    const lastSync = await offlineStore.getLastSyncTime();
    const storageInfo = await offlineStore.getStorageInfo();

    return {
      isSyncing: this.isSyncing,
      isOnline: navigator.onLine,
      pendingOperations: pending,
      lastSync,
      ...storageInfo
    };
  }

  // Manual sync trigger
  async sync() {
    return this.syncAll();
  }

  // Force full resync
  async fullResync() {
    await offlineStore.clearAllData();
    return this.pullFromServer();
  }
}

// Export singleton instance
const syncManager = new SyncManager();
export default syncManager;
