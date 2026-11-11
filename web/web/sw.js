// Minimal service worker: it only makes the guest portal installable.
// It caches nothing; every request goes straight to the network.
self.addEventListener('install', function() {
  self.skipWaiting();
});

self.addEventListener('activate', function(event) {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', function() {
  // Network passthrough: no respondWith, no cache.
});
