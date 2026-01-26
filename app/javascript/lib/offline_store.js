// Offline Store - IndexedDB wrapper for offline data storage
const DB_NAME = 'meddir-offline';
const DB_VERSION = 1;

// Store names
const STORES = {
  MEDICAL_FOLDERS: 'medical_folders',
  DOCUMENTS: 'documents',
  PENDING_SYNC: 'pending_sync',
  METADATA: 'metadata'
};

class OfflineStore {
  constructor() {
    this.db = null;
    this.isReady = false;
    this.readyPromise = this.init();
  }

  async init() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION);

      request.onerror = () => {
        console.error('[OfflineStore] Failed to open database:', request.error);
        reject(request.error);
      };

      request.onsuccess = () => {
        this.db = request.result;
        this.isReady = true;
        console.log('[OfflineStore] Database opened successfully');
        resolve(this.db);
      };

      request.onupgradeneeded = (event) => {
        const db = event.target.result;
        this.createStores(db);
      };
    });
  }

  createStores(db) {
    // Medical Folders store
    if (!db.objectStoreNames.contains(STORES.MEDICAL_FOLDERS)) {
      const foldersStore = db.createObjectStore(STORES.MEDICAL_FOLDERS, { keyPath: 'id' });
      foldersStore.createIndex('user_id', 'user_id', { unique: false });
      foldersStore.createIndex('updated_at', 'updated_at', { unique: false });
      foldersStore.createIndex('synced', 'synced', { unique: false });
    }

    // Documents store
    if (!db.objectStoreNames.contains(STORES.DOCUMENTS)) {
      const docsStore = db.createObjectStore(STORES.DOCUMENTS, { keyPath: 'id' });
      docsStore.createIndex('medical_folder_id', 'medical_folder_id', { unique: false });
      docsStore.createIndex('updated_at', 'updated_at', { unique: false });
      docsStore.createIndex('synced', 'synced', { unique: false });
    }

    // Pending Sync store - for operations made while offline
    if (!db.objectStoreNames.contains(STORES.PENDING_SYNC)) {
      const syncStore = db.createObjectStore(STORES.PENDING_SYNC, { 
        keyPath: 'id', 
        autoIncrement: true 
      });
      syncStore.createIndex('type', 'type', { unique: false });
      syncStore.createIndex('created_at', 'created_at', { unique: false });
      syncStore.createIndex('entity_type', 'entity_type', { unique: false });
    }

    // Metadata store - for sync timestamps and app state
    if (!db.objectStoreNames.contains(STORES.METADATA)) {
      db.createObjectStore(STORES.METADATA, { keyPath: 'key' });
    }

    console.log('[OfflineStore] Stores created');
  }

  async ensureReady() {
    if (!this.isReady) {
      await this.readyPromise;
    }
  }

  // ============ Generic CRUD Operations ============

  async getAll(storeName) {
    await this.ensureReady();
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(storeName, 'readonly');
      const store = transaction.objectStore(storeName);
      const request = store.getAll();

      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  async get(storeName, id) {
    await this.ensureReady();
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(storeName, 'readonly');
      const store = transaction.objectStore(storeName);
      const request = store.get(id);

      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  async put(storeName, data) {
    await this.ensureReady();
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(storeName, 'readwrite');
      const store = transaction.objectStore(storeName);
      const request = store.put(data);

      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  async delete(storeName, id) {
    await this.ensureReady();
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(storeName, 'readwrite');
      const store = transaction.objectStore(storeName);
      const request = store.delete(id);

      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  async clear(storeName) {
    await this.ensureReady();
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(storeName, 'readwrite');
      const store = transaction.objectStore(storeName);
      const request = store.clear();

      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  async getByIndex(storeName, indexName, value) {
    await this.ensureReady();
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(storeName, 'readonly');
      const store = transaction.objectStore(storeName);
      const index = store.index(indexName);
      const request = index.getAll(value);

      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  // ============ Medical Folders ============

  async getAllFolders() {
    return this.getAll(STORES.MEDICAL_FOLDERS);
  }

  async getFolder(id) {
    return this.get(STORES.MEDICAL_FOLDERS, id);
  }

  async saveFolder(folder) {
    const data = {
      ...folder,
      synced: true,
      cached_at: new Date().toISOString()
    };
    return this.put(STORES.MEDICAL_FOLDERS, data);
  }

  async saveFolderOffline(folder) {
    // Generate temporary ID for new folder
    const tempId = folder.id || `temp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const data = {
      ...folder,
      id: tempId,
      synced: false,
      created_offline: true,
      cached_at: new Date().toISOString()
    };
    
    await this.put(STORES.MEDICAL_FOLDERS, data);
    
    // Add to pending sync
    await this.addPendingOperation({
      type: 'create',
      entity_type: 'medical_folder',
      entity_id: tempId,
      data: folder
    });
    
    return data;
  }

  async updateFolderOffline(id, updates) {
    const folder = await this.getFolder(id);
    if (!folder) {
      throw new Error('Folder not found');
    }

    const data = {
      ...folder,
      ...updates,
      synced: false,
      updated_at: new Date().toISOString()
    };

    await this.put(STORES.MEDICAL_FOLDERS, data);

    // Add to pending sync if not already pending creation
    if (!folder.created_offline) {
      await this.addPendingOperation({
        type: 'update',
        entity_type: 'medical_folder',
        entity_id: id,
        data: updates
      });
    }

    return data;
  }

  async deleteFolder(id) {
    const folder = await this.getFolder(id);
    
    // Delete associated documents
    const documents = await this.getDocumentsByFolder(id);
    for (const doc of documents) {
      await this.delete(STORES.DOCUMENTS, doc.id);
    }

    await this.delete(STORES.MEDICAL_FOLDERS, id);

    // Add to pending sync if it was a synced folder
    if (folder && !folder.created_offline) {
      await this.addPendingOperation({
        type: 'delete',
        entity_type: 'medical_folder',
        entity_id: id
      });
    }
  }

  // ============ Documents ============

  async getAllDocuments() {
    return this.getAll(STORES.DOCUMENTS);
  }

  async getDocument(id) {
    return this.get(STORES.DOCUMENTS, id);
  }

  async getDocumentsByFolder(folderId) {
    return this.getByIndex(STORES.DOCUMENTS, 'medical_folder_id', folderId);
  }

  async saveDocument(document) {
    const data = {
      ...document,
      synced: true,
      cached_at: new Date().toISOString()
    };
    return this.put(STORES.DOCUMENTS, data);
  }

  async saveDocumentOffline(document, fileBlob = null) {
    const tempId = document.id || `temp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const data = {
      ...document,
      id: tempId,
      synced: false,
      created_offline: true,
      cached_at: new Date().toISOString()
    };

    // Store file blob separately if provided
    if (fileBlob) {
      data.file_blob = fileBlob;
      data.file_name = fileBlob.name;
      data.file_type = fileBlob.type;
      data.file_size = fileBlob.size;
    }

    await this.put(STORES.DOCUMENTS, data);

    // Add to pending sync
    await this.addPendingOperation({
      type: 'create',
      entity_type: 'document',
      entity_id: tempId,
      data: document,
      has_file: !!fileBlob
    });

    return data;
  }

  async updateDocumentOffline(id, updates) {
    const document = await this.getDocument(id);
    if (!document) {
      throw new Error('Document not found');
    }

    const data = {
      ...document,
      ...updates,
      synced: false,
      updated_at: new Date().toISOString()
    };

    await this.put(STORES.DOCUMENTS, data);

    if (!document.created_offline) {
      await this.addPendingOperation({
        type: 'update',
        entity_type: 'document',
        entity_id: id,
        data: updates
      });
    }

    return data;
  }

  async deleteDocument(id) {
    const document = await this.getDocument(id);
    await this.delete(STORES.DOCUMENTS, id);

    if (document && !document.created_offline) {
      await this.addPendingOperation({
        type: 'delete',
        entity_type: 'document',
        entity_id: id
      });
    }
  }

  // ============ Pending Sync Operations ============

  async addPendingOperation(operation) {
    const data = {
      ...operation,
      created_at: new Date().toISOString(),
      attempts: 0
    };
    return this.put(STORES.PENDING_SYNC, data);
  }

  async getPendingOperations() {
    const operations = await this.getAll(STORES.PENDING_SYNC);
    return operations.sort((a, b) => new Date(a.created_at) - new Date(b.created_at));
  }

  async getPendingOperationsByType(entityType) {
    return this.getByIndex(STORES.PENDING_SYNC, 'entity_type', entityType);
  }

  async removePendingOperation(id) {
    return this.delete(STORES.PENDING_SYNC, id);
  }

  async updatePendingOperation(id, updates) {
    const operation = await this.get(STORES.PENDING_SYNC, id);
    if (operation) {
      await this.put(STORES.PENDING_SYNC, { ...operation, ...updates });
    }
  }

  async getPendingCount() {
    const operations = await this.getAll(STORES.PENDING_SYNC);
    return operations.length;
  }

  // ============ Metadata ============

  async setMetadata(key, value) {
    return this.put(STORES.METADATA, { key, value, updated_at: new Date().toISOString() });
  }

  async getMetadata(key) {
    const data = await this.get(STORES.METADATA, key);
    return data ? data.value : null;
  }

  async getLastSyncTime() {
    return this.getMetadata('last_sync');
  }

  async setLastSyncTime(time = new Date().toISOString()) {
    return this.setMetadata('last_sync', time);
  }

  // ============ Bulk Operations ============

  async syncFoldersFromServer(folders) {
    for (const folder of folders) {
      await this.saveFolder(folder);
    }
    await this.setLastSyncTime();
  }

  async syncDocumentsFromServer(documents) {
    for (const doc of documents) {
      await this.saveDocument(doc);
    }
  }

  async getUnsyncedData() {
    const folders = await this.getByIndex(STORES.MEDICAL_FOLDERS, 'synced', false);
    const documents = await this.getByIndex(STORES.DOCUMENTS, 'synced', false);
    const pending = await this.getPendingOperations();

    return { folders, documents, pending };
  }

  // Mark entities as synced after successful server sync
  async markAsSynced(entityType, tempId, serverId) {
    const storeName = entityType === 'medical_folder' ? STORES.MEDICAL_FOLDERS : STORES.DOCUMENTS;
    
    // Get the entity
    const entity = await this.get(storeName, tempId);
    if (!entity) return;

    // Delete old entry and save with new server ID
    await this.delete(storeName, tempId);
    
    const synced = {
      ...entity,
      id: serverId,
      synced: true,
      created_offline: false
    };
    delete synced.file_blob; // Remove blob after upload
    
    await this.put(storeName, synced);

    // Update any references in documents if folder was synced
    if (entityType === 'medical_folder') {
      const documents = await this.getByIndex(STORES.DOCUMENTS, 'medical_folder_id', tempId);
      for (const doc of documents) {
        await this.put(STORES.DOCUMENTS, { ...doc, medical_folder_id: serverId });
      }
    }
  }

  // ============ Storage Management ============

  async getStorageInfo() {
    const folders = await this.getAllFolders();
    const documents = await this.getAllDocuments();
    const pending = await this.getPendingOperations();
    const lastSync = await this.getLastSyncTime();

    return {
      folders: folders.length,
      documents: documents.length,
      pending: pending.length,
      lastSync
    };
  }

  async clearAllData() {
    await this.clear(STORES.MEDICAL_FOLDERS);
    await this.clear(STORES.DOCUMENTS);
    await this.clear(STORES.PENDING_SYNC);
    await this.clear(STORES.METADATA);
  }
}

// Export singleton instance
const offlineStore = new OfflineStore();
export default offlineStore;
export { STORES };
