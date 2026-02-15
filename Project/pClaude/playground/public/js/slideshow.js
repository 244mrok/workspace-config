(function () {
  const ADVANCE_INTERVAL = 6000; // ms between slides
  const POLL_INTERVAL = 30000; // ms between photo list refreshes
  const KB_VARIANTS = 4;

  let photos = [];
  let currentIndex = -1;
  let paused = false;
  let advanceTimer = null;
  let wakeLock = null;
  let userEmail = null;

  function storageKey() {
    return userEmail ? `photos_${userEmail}` : null;
  }

  function savePhotosToLocal(list) {
    const key = storageKey();
    if (key && list.length > 0) {
      localStorage.setItem(key, JSON.stringify(list));
    }
  }

  function loadPhotosFromLocal() {
    const key = storageKey();
    if (!key) return null;
    try {
      const data = localStorage.getItem(key);
      return data ? JSON.parse(data) : null;
    } catch (_) {
      return null;
    }
  }

  const container = document.getElementById("slideshow");
  const pauseIndicator = document.getElementById("pause-indicator");
  const emptyMessage = document.getElementById("empty-message");

  // --- Wake Lock ---
  async function requestWakeLock() {
    if ("wakeLock" in navigator) {
      try {
        wakeLock = await navigator.wakeLock.request("screen");
        wakeLock.addEventListener("release", () => { wakeLock = null; });
      } catch (_) {
        // Wake lock request failed (e.g. tab not visible)
      }
    }
  }

  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible" && !paused) {
      requestWakeLock();
    }
  });

  // --- Fetch photos ---
  async function fetchPhotos() {
    try {
      const res = await fetch("/api/photos");
      if (res.status === 401 || res.status === 403) {
        window.location.href = "/login";
        return;
      }
      let data = await res.json();

      // If server returned empty, try restoring from localStorage
      if (data.length === 0) {
        const saved = loadPhotosFromLocal();
        if (saved && saved.length > 0) {
          await fetch("/api/photos/restore", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ items: saved.filter((p) => p.source === "google") }),
          });
          const res2 = await fetch("/api/photos");
          if (res2.ok) {
            data = await res2.json();
          }
        }
      }

      if (data.length > 0) {
        savePhotosToLocal(data);
      }

      photos = data;
      if (photos.length === 0) {
        emptyMessage.style.display = "flex";
        container.innerHTML = "";
      } else {
        emptyMessage.style.display = "none";
      }
    } catch (_) {
      // Silently retry next poll
    }
  }

  // --- Slideshow ---
  function showNext() {
    if (photos.length === 0) return;

    currentIndex = (currentIndex + 1) % photos.length;
    const photo = photos[currentIndex];

    const slide = document.createElement("div");
    slide.className = `slide kb-${Math.floor(Math.random() * KB_VARIANTS) + 1}`;

    const img = document.createElement("img");
    img.src = photo.url;
    img.alt = "";
    img.draggable = false;
    slide.appendChild(img);

    container.appendChild(slide);

    // Trigger reflow then activate
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        slide.classList.add("active");
      });
    });

    // Remove old slides after transition
    const oldSlides = container.querySelectorAll(".slide:not(:last-child)");
    oldSlides.forEach((old) => {
      setTimeout(() => old.remove(), 2000);
    });

    scheduleNext();
  }

  function scheduleNext() {
    clearTimeout(advanceTimer);
    if (!paused) {
      advanceTimer = setTimeout(showNext, ADVANCE_INTERVAL);
    }
  }

  // --- Tap to pause/resume ---
  document.addEventListener("click", () => {
    paused = !paused;
    pauseIndicator.classList.toggle("visible", paused);

    if (paused) {
      clearTimeout(advanceTimer);
      if (wakeLock) {
        wakeLock.release();
        wakeLock = null;
      }
    } else {
      // Hide indicator after a moment
      setTimeout(() => {
        if (!paused) pauseIndicator.classList.remove("visible");
      }, 800);
      requestWakeLock();
      scheduleNext();
    }
  });

  // --- Init ---
  async function init() {
    // Get user email for localStorage key
    try {
      const meRes = await fetch("/api/me");
      if (meRes.ok) {
        const me = await meRes.json();
        userEmail = me.email;
      }
    } catch (_) {}

    await fetchPhotos();
    if (photos.length > 0) {
      showNext();
    }
    await requestWakeLock();

    // Poll for new photos
    setInterval(async () => {
      await fetchPhotos();
      // If slideshow hasn't started yet but now has photos, kick it off
      if (photos.length > 0 && currentIndex === -1) {
        showNext();
      }
    }, POLL_INTERVAL);

    // Keep-alive ping to prevent Render from spinning down the server
    setInterval(() => {
      fetch("/api/me").catch(() => {});
    }, 5 * 60 * 1000); // every 5 minutes
  }

  init();
})();
