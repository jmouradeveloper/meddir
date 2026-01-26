// MedDir Service Worker - PWA with Offline Support
const CACHE_VERSION = 'v1';
const STATIC_CACHE = `meddir-static-${CACHE_VERSION}`;
const DYNAMIC_CACHE = `meddir-dynamic-${CACHE_VERSION}`;
const DOCUMENT_CACHE = `meddir-documents-${CACHE_VERSION}`;

// Assets to cache immediately on install
const STATIC_ASSETS = [
  '/',
  '/manifest.json',
  '/icon.svg',
  '/icons/icon-192x192.png',
  '/icons/icon-512x512.png',
  '/offline.html'
];

// Cache size limits
const MAX_DYNAMIC_CACHE_SIZE = 50;
const MAX_DOCUMENT_CACHE_SIZE = 100;
const MAX_DOCUMENT_CACHE_BYTES = 500 * 1024 * 1024; // 500MB

// Install event - cache static assets
self.addEventListener('install', (event) => {
  console.log('[SW] Installing Service Worker...');
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then((cache) => {
        console.log('[SW] Pre-caching static assets');
        return cache.addAll(STATIC_ASSETS);
      })
      .then(() => self.skipWaiting())
      .catch((error) => {
        console.error('[SW] Pre-caching failed:', error);
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating Service Worker...');
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((name) => {
              return name.startsWith('meddir-') && 
                     name !== STATIC_CACHE && 
                     name !== DYNAMIC_CACHE && 
                     name !== DOCUMENT_CACHE;
            })
            .map((name) => {
              console.log('[SW] Deleting old cache:', name);
              return caches.delete(name);
            })
        );
      })
      .then(() => self.clients.claim())
  );
});

// Fetch event - implement caching strategies
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }

  // Skip external requests (except fonts)
  if (url.origin !== location.origin && !url.hostname.includes('fonts.')) {
    return;
  }

  // Strategy based on request type
  if (isStaticAsset(url)) {
    event.respondWith(cacheFirst(request, STATIC_CACHE));
  } else if (isDocumentFile(url)) {
    event.respondWith(staleWhileRevalidate(request, DOCUMENT_CACHE));
  } else if (isApiRequest(url)) {
    event.respondWith(networkFirst(request, DYNAMIC_CACHE));
  } else if (isNavigationRequest(request)) {
    event.respondWith(networkFirstWithOfflineFallback(request));
  } else {
    event.respondWith(networkFirst(request, DYNAMIC_CACHE));
  }
});

// Background Sync for offline operations
self.addEventListener('sync', (event) => {
  console.log('[SW] Background sync triggered:', event.tag);
  if (event.tag === 'sync-pending-operations') {
    event.waitUntil(syncPendingOperations());
  }
});

// Push notifications (for future use)
self.addEventListener('push', (event) => {
  if (event.data) {
    const data = event.data.json();
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: '/icons/icon-192x192.png',
      badge: '/icons/icon-96x96.png'
    });
  }
});

// Message handler for communication with main app
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'CACHE_DOCUMENT') {
    event.waitUntil(cacheDocument(event.data.url));
  }

  if (event.data && event.data.type === 'CLEAR_DOCUMENT_CACHE') {
    event.waitUntil(caches.delete(DOCUMENT_CACHE));
  }

  if (event.data && event.data.type === 'GET_CACHE_STATUS') {
    event.waitUntil(getCacheStatus().then((status) => {
      event.ports[0].postMessage(status);
    }));
  }
});

// ============ Helper Functions ============

function isStaticAsset(url) {
  return url.pathname.match(/\.(css|js|woff2?|ttf|eot|svg|png|jpg|jpeg|gif|webp|ico)$/) ||
         url.pathname.startsWith('/assets/') ||
         url.pathname.startsWith('/icons/') ||
         url.hostname.includes('fonts.');
}

function isDocumentFile(url) {
  // Active Storage URLs or direct document downloads
  return url.pathname.startsWith('/rails/active_storage/') ||
         url.pathname.match(/\.(pdf|doc|docx|dicom)$/);
}

function isApiRequest(url) {
  return url.pathname.endsWith('.json') ||
         url.pathname.startsWith('/api/');
}

function isNavigationRequest(request) {
  return request.mode === 'navigate' ||
         (request.method === 'GET' && request.headers.get('accept')?.includes('text/html'));
}

// ============ Caching Strategies ============

// Cache First - for static assets
async function cacheFirst(request, cacheName) {
  const cachedResponse = await caches.match(request);
  if (cachedResponse) {
    return cachedResponse;
  }
  
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(cacheName);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    console.error('[SW] Cache first failed:', error);
    return new Response('Offline', { status: 503 });
  }
}

// Network First - for dynamic content
async function networkFirst(request, cacheName) {
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(cacheName);
      cache.put(request, networkResponse.clone());
      await trimCache(cacheName, MAX_DYNAMIC_CACHE_SIZE);
    }
    return networkResponse;
  } catch (error) {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    return new Response(JSON.stringify({ error: 'Offline', offline: true }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// Network First with Offline Fallback - for navigation
async function networkFirstWithOfflineFallback(request) {
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    // Return offline page
    const offlinePage = await caches.match('/offline.html');
    if (offlinePage) {
      return offlinePage;
    }
    return new Response('You are offline', { status: 503 });
  }
}

// Stale While Revalidate - for documents
async function staleWhileRevalidate(request, cacheName) {
  const cachedResponse = await caches.match(request);
  
  const fetchPromise = fetch(request)
    .then((networkResponse) => {
      if (networkResponse.ok) {
        const cache = caches.open(cacheName);
        cache.then((c) => c.put(request, networkResponse.clone()));
      }
      return networkResponse;
    })
    .catch(() => cachedResponse);
  
  return cachedResponse || fetchPromise;
}

// ============ Cache Management ============

async function trimCache(cacheName, maxItems) {
  const cache = await caches.open(cacheName);
  const keys = await cache.keys();
  if (keys.length > maxItems) {
    await cache.delete(keys[0]);
    await trimCache(cacheName, maxItems);
  }
}

async function cacheDocument(url) {
  try {
    const response = await fetch(url);
    if (response.ok) {
      const cache = await caches.open(DOCUMENT_CACHE);
      await cache.put(url, response);
      console.log('[SW] Document cached:', url);
    }
  } catch (error) {
    console.error('[SW] Failed to cache document:', error);
  }
}

async function getCacheStatus() {
  const cacheNames = await caches.keys();
  const status = {
    caches: {},
    totalSize: 0
  };

  for (const name of cacheNames) {
    if (name.startsWith('meddir-')) {
      const cache = await caches.open(name);
      const keys = await cache.keys();
      status.caches[name] = keys.length;
    }
  }

  return status;
}

// ============ Background Sync ============

async function syncPendingOperations() {
  console.log('[SW] Syncing pending operations...');
  
  // Get all clients
  const clients = await self.clients.matchAll();
  
  // Notify clients to sync
  clients.forEach((client) => {
    client.postMessage({
      type: 'SYNC_REQUIRED'
    });
  });
}

// Periodic background sync (if supported)
self.addEventListener('periodicsync', (event) => {
  if (event.tag === 'sync-data') {
    event.waitUntil(syncPendingOperations());
  }
});

console.log('[SW] Service Worker loaded');
