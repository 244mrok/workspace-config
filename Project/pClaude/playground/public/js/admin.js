(function () {
  const dropZone = document.getElementById("drop-zone");
  const fileInput = document.getElementById("file-input");
  const progressBar = document.getElementById("progress-bar");
  const progressFill = progressBar.querySelector(".fill");
  const photoGrid = document.getElementById("photo-grid");
  const emptyState = document.getElementById("empty-state");

  // --- Drag and drop ---
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

  // --- Upload ---
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

        const btn = document.createElement("button");
        btn.className = "delete-btn";
        btn.textContent = "\u00d7";
        btn.title = "Delete photo";
        btn.addEventListener("click", (e) => {
          e.stopPropagation();
          deletePhoto(photo.filename);
        });

        card.appendChild(img);
        card.appendChild(btn);
        photoGrid.appendChild(card);
      });
    } catch (_) {
      alert("Failed to load photos");
    }
  }

  // --- Delete ---
  async function deletePhoto(filename) {
    try {
      const res = await fetch(`/api/photos/${encodeURIComponent(filename)}`, {
        method: "DELETE",
      });
      if (res.ok) {
        loadPhotos();
      } else {
        alert("Delete failed");
      }
    } catch (_) {
      alert("Delete failed — network error");
    }
  }

  // --- Init ---
  loadPhotos();
})();
