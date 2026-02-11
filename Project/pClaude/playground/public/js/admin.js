(function () {
  const connectBtn = document.getElementById("connect-btn");
  const disconnectBtn = document.getElementById("disconnect-btn");
  const pickBtn = document.getElementById("pick-btn");
  const statusDisconnected = document.getElementById("status-disconnected");
  const statusConnected = document.getElementById("status-connected");
  const connectedText = document.getElementById("connected-text");
  const pickerSection = document.getElementById("picker-section");
  const pickerStatus = document.getElementById("picker-status");
  const photosSection = document.getElementById("photos-section");
  const photoGrid = document.getElementById("photo-grid");
  const emptyState = document.getElementById("empty-state");

  let pollTimer = null;

  // --- Check auth status on load ---
  async function checkStatus() {
    try {
      const res = await fetch("/auth/status");
      const data = await res.json();

      if (data.connected) {
        statusDisconnected.style.display = "none";
        statusConnected.style.display = "block";
        pickerSection.style.display = "block";
        photosSection.style.display = "block";

        if (data.photoCount > 0) {
          connectedText.textContent = `Connected — ${data.photoCount} photo${data.photoCount !== 1 ? "s" : ""} in slideshow`;
        } else {
          connectedText.textContent = "Connected to Google Photos";
        }

        loadPhotos();
      } else {
        statusDisconnected.style.display = "block";
        statusConnected.style.display = "none";
        pickerSection.style.display = "none";
        photosSection.style.display = "none";
      }
    } catch (_) {
      statusDisconnected.style.display = "block";
    }
  }

  // --- Connect ---
  connectBtn.addEventListener("click", async () => {
    try {
      const res = await fetch("/auth/url");
      const data = await res.json();
      window.location.href = data.url;
    } catch (_) {
      alert("Failed to start Google Photos connection");
    }
  });

  // --- Disconnect ---
  disconnectBtn.addEventListener("click", async () => {
    if (!confirm("Disconnect from Google Photos? The slideshow will stop.")) {
      return;
    }
    try {
      await fetch("/auth/disconnect", { method: "POST" });
      checkStatus();
    } catch (_) {
      alert("Failed to disconnect");
    }
  });

  // --- Pick photos ---
  pickBtn.addEventListener("click", async () => {
    pickBtn.disabled = true;
    pickerStatus.textContent = "Creating picker session...";

    // Open window immediately (before await) to avoid popup blocker
    const pickerWindow = window.open("about:blank", "google-photos-picker",
      "width=1024,height=700,menubar=no,toolbar=no");

    try {
      const res = await fetch("/api/picker/session", { method: "POST" });
      if (!res.ok) {
        const err = await res.json();
        if (pickerWindow) pickerWindow.close();
        throw new Error(err.error || "Failed to create session");
      }
      const session = await res.json();

      // Navigate the already-opened window to the picker URI
      if (pickerWindow) {
        pickerWindow.location.href = session.pickerUri;
      } else {
        // Fallback: redirect current page if popup was still blocked
        pickerStatus.innerHTML = 'Popup blocked. <a href="' + session.pickerUri + '" target="_blank">Click here to open the picker</a>';
        pickBtn.disabled = false;
        return;
      }

      pickerStatus.textContent = "Waiting for photo selection... (pick photos in the Google Photos window)";

      // Poll session status
      pollTimer = setInterval(async () => {
        try {
          const pollRes = await fetch(`/api/picker/session/${session.id}`);
          const pollData = await pollRes.json();

          if (pollData.mediaItemsSet) {
            clearInterval(pollTimer);
            pollTimer = null;
            pickerStatus.textContent = "Saving selection...";

            // Confirm the selection
            const confirmRes = await fetch("/api/picker/confirm", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ sessionId: session.id }),
            });
            const confirmData = await confirmRes.json();

            if (confirmData.ok) {
              pickerStatus.textContent = `Done! ${confirmData.photoCount} photo${confirmData.photoCount !== 1 ? "s" : ""} selected.`;
              setTimeout(() => { pickerStatus.textContent = ""; }, 3000);
              checkStatus();
            } else {
              pickerStatus.textContent = "Failed to save selection: " + (confirmData.error || "Unknown error");
            }

            pickBtn.disabled = false;
          }

          // Check if the popup was closed without selecting
          if (pickerWindow && pickerWindow.closed && !pollData.mediaItemsSet) {
            // Keep polling for a bit — user might have finished selecting before closing
          }
        } catch (_) {
          // Polling error — keep trying
        }
      }, 2000);

      // Stop polling after 10 minutes (safety)
      setTimeout(() => {
        if (pollTimer) {
          clearInterval(pollTimer);
          pollTimer = null;
          pickBtn.disabled = false;
          pickerStatus.textContent = "Session timed out. Try again.";
        }
      }, 10 * 60 * 1000);
    } catch (err) {
      pickerStatus.textContent = "Error: " + err.message;
      pickBtn.disabled = false;
    }
  });

  // --- Load photo grid ---
  async function loadPhotos() {
    try {
      const res = await fetch("/api/photos");
      const photos = await res.json();

      photoGrid.innerHTML = "";

      if (photos.length === 0) {
        emptyState.style.display = "block";
        return;
      }

      emptyState.style.display = "none";

      photos.forEach((photo) => {
        const card = document.createElement("div");
        card.className = "photo-card";

        const img = document.createElement("img");
        img.src = photo.url;
        img.alt = photo.filename;
        img.loading = "lazy";

        card.appendChild(img);
        photoGrid.appendChild(card);
      });
    } catch (_) {
      // Silent fail
    }
  }

  // --- Handle auth callback params ---
  const params = new URLSearchParams(window.location.search);
  if (params.get("auth") === "success") {
    // Clean URL
    window.history.replaceState({}, "", "/admin.html");
  } else if (params.get("auth") === "error") {
    alert("Google Photos connection failed. Please try again.");
    window.history.replaceState({}, "", "/admin.html");
  }

  // --- Init ---
  checkStatus();
})();
