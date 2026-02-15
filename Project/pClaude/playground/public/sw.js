const CACHE_NAME = "photo-cache-v1";

self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);

  // Only cache /api/photo/* requests
  if (!url.pathname.startsWith("/api/photo/")) return;

  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) return cached;

      return fetch(event.request).then((response) => {
        if (response.ok) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        }
        return response;
      });
    })
  );
});

// Listen for cache clear messages
self.addEventListener("message", (event) => {
  if (event.data === "clear-photo-cache") {
    caches.delete(CACHE_NAME);
  }
});
