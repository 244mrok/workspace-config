(function () {
  const ADVANCE_INTERVAL = 6000; // ms between slides
  const POLL_INTERVAL = 30000; // ms between photo list refreshes
  const KB_VARIANTS = 4;

  let photos = [];
  let currentIndex = -1;
  let paused = false;
  let advanceTimer = null;
  let wakeLock = null;

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
      const data = await res.json();
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
  }

  init();
})();
