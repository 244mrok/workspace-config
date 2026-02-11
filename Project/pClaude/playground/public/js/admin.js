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
  const dropZone = document.getElementById("drop-zone");
  const fileInput = document.getElementById("file-input");
  const progressBar = document.getElementById("progress-bar");
  const progressFill = progressBar.querySelector(".fill");

  let pollTimer = null;

  // --- Handle 401 globally ---
  function handleAuthError(res) {
    if (res.status === 401 || res.status === 403) {
      window.location.href = "/login";
      return true;
    }
    return false;
  }

  // --- Load current user ---
  async function loadUser() {
    try {
      const res = await fetch("/api/me");
      if (handleAuthError(res)) return;
      const user = await res.json();
      const userInfo = document.getElementById("user-info");
      const userName = document.getElementById("user-name");
      const logoutBtn = document.getElementById("logout-btn");
      if (userInfo && userName) {
        userName.textContent = user.name || user.email;
        userInfo.style.display = "flex";
      }
      if (logoutBtn) {
        logoutBtn.addEventListener("click", async () => {
          await fetch("/login/logout", { method: "POST" });
          window.location.href = "/login";
        });
      }
    } catch (_) {
      // ignore
    }
  }

  // --- Check auth status on load ---
  async function checkStatus() {
    try {
      const res = await fetch("/auth/status");
      if (handleAuthError(res)) return;
      const data = await res.json();

      if (data.connected) {
        statusDisconnected.style.display = "none";
        statusConnected.style.display = "block";
        pickerSection.style.display = "block";

        if (data.photoCount > 0) {
          connectedText.textContent = `Connected — ${data.photoCount} photo${data.photoCount !== 1 ? "s" : ""} from Google Photos`;
        } else {
          connectedText.textContent = "Connected to Google Photos";
        }
      } else {
        statusDisconnected.style.display = "block";
        statusConnected.style.display = "none";
        pickerSection.style.display = "none";
      }

      loadPhotos();
    } catch (_) {
      statusDisconnected.style.display = "block";
      loadPhotos();
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
      if (handleAuthError(res)) return;
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

        const btn = document.createElement("button");
        btn.className = "delete-btn";
        btn.textContent = "\u00d7";
        btn.title = "Remove from slideshow";
        btn.addEventListener("click", (e) => {
          e.stopPropagation();
          deletePhoto(photo.id);
        });

        card.appendChild(img);
        card.appendChild(btn);
        photoGrid.appendChild(card);
      });
    } catch (_) {
      // Silent fail
    }
  }

  // --- Delete photo from slideshow ---
  async function deletePhoto(id) {
    try {
      const res = await fetch(`/api/photos/${encodeURIComponent(id)}`, {
        method: "DELETE",
      });
      if (res.ok) {
        checkStatus();
      } else {
        alert("Failed to remove photo");
      }
    } catch (_) {
      alert("Failed to remove photo — network error");
    }
  }

  // --- Local upload (drag & drop + browse) ---
  dropZone.addEventListener("click", () => fileInput.click());

  dropZone.addEventListener("dragover", (e) => {
    e.preventDefault();
    dropZone.classList.add("dragover");
  });

  dropZone.addEventListener("dragleave", () => {
    dropZone.classList.remove("dragover");
  });

  dropZone.addEventListener("drop", (e) => {
    e.preventDefault();
    dropZone.classList.remove("dragover");
    if (e.dataTransfer.files.length > 0) {
      uploadFiles(e.dataTransfer.files);
    }
  });

  fileInput.addEventListener("change", () => {
    if (fileInput.files.length > 0) {
      uploadFiles(fileInput.files);
      fileInput.value = "";
    }
  });

  async function uploadFiles(files) {
    const formData = new FormData();
    for (const file of files) {
      formData.append("photos", file);
    }

    progressBar.style.display = "block";
    progressFill.style.width = "0%";

    const xhr = new XMLHttpRequest();
    xhr.open("POST", "/api/upload");

    xhr.upload.addEventListener("progress", (e) => {
      if (e.lengthComputable) {
        const pct = Math.round((e.loaded / e.total) * 100);
        progressFill.style.width = pct + "%";
      }
    });

    xhr.addEventListener("load", () => {
      progressBar.style.display = "none";
      if (xhr.status === 200) {
        loadPhotos();
      } else {
        alert("Upload failed: " + xhr.responseText);
      }
    });

    xhr.addEventListener("error", () => {
      progressBar.style.display = "none";
      alert("Upload failed — network error");
    });

    xhr.send(formData);
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
  loadUser();
  checkStatus();
})();
