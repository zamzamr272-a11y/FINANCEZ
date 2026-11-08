const CACHE = 'finance-shell-v4';
const SHELL = ['./', './assets/styles.css', './assets/calm.css', './assets/app.js', './assets/finance-mark.svg', './assets/finance-logo.svg', './assets/finance-logo-dark.svg', './assets/icons/finance-192.png', './assets/icons/finance-512.png', './assets/mascot.svg', './assets/fonts/Inter-300.woff', './assets/fonts/Inter-400.woff', './assets/fonts/Inter-500.woff', './assets/fonts/Inter-600.woff', './assets/fonts/Inter-700.woff', './manifest.webmanifest'];
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(SHELL)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.pathname.startsWith('/api/') || url.pathname.startsWith('/health')) return;
  event.respondWith(caches.match(request).then(cached => cached || fetch(request).then(response => {
    if (response.ok && url.origin === self.location.origin) {
      const copy = response.clone(); caches.open(CACHE).then(cache => cache.put(request, copy));
    }
    return response;
  }).catch(() => caches.match('./'))));
});
