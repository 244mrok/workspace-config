const express = require("express");
const multer = require("multer");
const { v4: uuidv4 } = require("uuid");
const path = require("path");
const fs = require("fs");

const app = express();
const PORT = process.env.PORT || 3000;
const UPLOADS_DIR = path.join(__dirname, "uploads");

// Ensure uploads directory exists
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR);
}

// Multer storage config — unique filenames, preserve extension
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, UPLOADS_DIR),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `${uuidv4()}${ext}`);
  },
});

const ALLOWED_EXTENSIONS = new Set([".jpg", ".jpeg", ".png", ".webp", ".heic"]);

const upload = multer({
  storage,
  fileFilter: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    if (ALLOWED_EXTENSIONS.has(ext)) {
      cb(null, true);
    } else {
      cb(new Error(`File type ${ext} not allowed`));
    }
  },
  limits: { fileSize: 50 * 1024 * 1024 }, // 50 MB per file
});

// Static files
app.use(express.static(path.join(__dirname, "public")));
app.use("/uploads", express.static(UPLOADS_DIR));

// GET /api/photos — list all uploaded photos
app.get("/api/photos", (_req, res) => {
  const files = fs.readdirSync(UPLOADS_DIR).filter((f) => {
    const ext = path.extname(f).toLowerCase();
    return ALLOWED_EXTENSIONS.has(ext);
  });
  // Sort by modification time (newest first)
  files.sort((a, b) => {
    const statA = fs.statSync(path.join(UPLOADS_DIR, a));
    const statB = fs.statSync(path.join(UPLOADS_DIR, b));
    return statB.mtimeMs - statA.mtimeMs;
  });
  const photos = files.map((f) => ({
    filename: f,
    url: `/uploads/${encodeURIComponent(f)}`,
  }));
  res.json(photos);
});

// POST /api/upload — upload one or more photos
app.post("/api/upload", upload.array("photos", 50), (req, res) => {
  const uploaded = req.files.map((f) => ({
    filename: f.filename,
    url: `/uploads/${encodeURIComponent(f.filename)}`,
  }));
  res.json({ uploaded });
});

// DELETE /api/photos/:filename — remove a photo
app.delete("/api/photos/:filename", (req, res) => {
  const filename = req.params.filename;
  const filePath = path.join(UPLOADS_DIR, filename);

  // Prevent path traversal
  if (path.dirname(filePath) !== UPLOADS_DIR) {
    return res.status(400).json({ error: "Invalid filename" });
  }

  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: "Photo not found" });
  }

  fs.unlinkSync(filePath);
  res.json({ deleted: filename });
});

// Multer error handling
app.use((err, _req, res, _next) => {
  if (err instanceof multer.MulterError) {
    return res.status(400).json({ error: err.message });
  }
  if (err) {
    return res.status(400).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Photo viewer running at http://localhost:${PORT}`);
  console.log(`Slideshow:  http://localhost:${PORT}/`);
  console.log(`Admin:      http://localhost:${PORT}/admin.html`);
});
