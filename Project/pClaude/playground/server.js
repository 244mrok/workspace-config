const express = require("express");
const cookieSession = require("cookie-session");
const { OAuth2Client } = require("google-auth-library");
const multer = require("multer");
const { v4: uuidv4 } = require("uuid");
const path = require("path");
const fs = require("fs");
const auth = require("./auth");

const app = express();
app.use(express.json());

// --- Session ---
app.use(
  cookieSession({
    name: "session",
    keys: [process.env.SESSION_SECRET || "dev-secret-change-me"],
    maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days
  })
);

const PORT = process.env.PORT || 3000;
const DATA_DIR = path.join(__dirname, "data");
const UPLOADS_DIR = path.join(__dirname, "uploads");
const TOKENS_PATH = path.join(DATA_DIR, "tokens.json");
const CONFIG_PATH = path.join(DATA_DIR, "config.json");

const PICKER_API = "https://photospicker.googleapis.com/v1";
// Drive API is used for random photos (Photos Library API is restricted for new projects)
const CACHE_TTL_MS = 50 * 60 * 1000; // 50 minutes

// Ensure directories exist
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR);
}

// --- Multer (local uploads) ---
const ALLOWED_EXTENSIONS = new Set([".jpg", ".jpeg", ".png", ".webp", ".heic"]);

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, UPLOADS_DIR),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `${uuidv4()}${ext}`);
  },
});

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
  limits: { fileSize: 50 * 1024 * 1024 },
});

// --- OAuth2 Client (for Photos Picker) ---
function createOAuth2Client() {
  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
  if (!clientId || !clientSecret) {
    throw new Error(
      "GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET env vars are required"
    );
  }
  return new OAuth2Client(clientId, clientSecret, auth.getPickerRedirectUri());
}

// --- Token Storage ---
function loadTokens() {
  if (fs.existsSync(TOKENS_PATH)) {
    return JSON.parse(fs.readFileSync(TOKENS_PATH, "utf-8"));
  }
  return null;
}

function saveTokens(tokens) {
  fs.writeFileSync(TOKENS_PATH, JSON.stringify(tokens, null, 2));
}

function deleteTokens() {
  if (fs.existsSync(TOKENS_PATH)) {
    fs.unlinkSync(TOKENS_PATH);
  }
}

// --- Config Storage (picker session + media item IDs) ---
function loadConfig() {
  if (fs.existsSync(CONFIG_PATH)) {
    return JSON.parse(fs.readFileSync(CONFIG_PATH, "utf-8"));
  }
  return null;
}

function saveConfig(config) {
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2));
}

function deleteConfig() {
  if (fs.existsSync(CONFIG_PATH)) {
    fs.unlinkSync(CONFIG_PATH);
  }
}

// --- In-Memory Photo Cache ---
let photoCache = {
  items: [], // { id, baseUrl, mimeType, filename }
  fetchedAt: 0,
};

// --- Auth Helper ---
async function getAuthedClient() {
  const tokens = loadTokens();
  if (!tokens) return null;

  const client = createOAuth2Client();
  client.setCredentials(tokens);

  // Listen for token refresh events and save
  client.on("tokens", (newTokens) => {
    const merged = { ...tokens, ...newTokens };
    saveTokens(merged);
  });

  return client;
}

async function getAccessToken() {
  const client = await getAuthedClient();
  if (!client) return null;
  const { token } = await client.getAccessToken();
  return token;
}

// --- Picker API Helpers ---
async function createPickerSession(accessToken) {
  const res = await fetch(`${PICKER_API}/sessions`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({}),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Failed to create picker session: ${res.status} ${text}`);
  }
  return res.json();
}

async function getPickerSession(sessionId, accessToken) {
  const res = await fetch(`${PICKER_API}/sessions/${sessionId}`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Failed to get picker session: ${res.status} ${text}`);
  }
  return res.json();
}

async function getPickerMediaItems(sessionId, accessToken, pageToken) {
  let url = `${PICKER_API}/mediaItems?sessionId=${encodeURIComponent(sessionId)}&pageSize=100`;
  if (pageToken) {
    url += `&pageToken=${encodeURIComponent(pageToken)}`;
  }
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Failed to get media items: ${res.status} ${text}`);
  }
  return res.json();
}

// Fetch all media items from a picker session (handles pagination)
async function fetchAllMediaItems(sessionId, accessToken) {
  const allItems = [];
  let pageToken = undefined;
  do {
    const result = await getPickerMediaItems(sessionId, accessToken, pageToken);
    if (result.mediaItems) {
      allItems.push(...result.mediaItems);
    }
    pageToken = result.nextPageToken;
  } while (pageToken);
  return allItems;
}

// Refresh the photo cache from the stored picker session or library
async function refreshCache() {
  const config = loadConfig();
  if (!config) {
    photoCache = { items: [], fetchedAt: 0 };
    return;
  }

  const accessToken = await getAccessToken();
  if (!accessToken) {
    photoCache = { items: [], fetchedAt: 0 };
    return;
  }

  try {
    if (config.mode === "drive") {
      // Drive mode: baseUrls don't expire, just rebuild cache from stored IDs
      const ids = config.mediaItemIds || [];
      photoCache = {
        items: ids.map((id) => ({
          id,
          baseUrl: `https://www.googleapis.com/drive/v3/files/${id}?alt=media`,
          mimeType: "image/jpeg",
          filename: id,
        })),
        fetchedAt: Date.now(),
      };
    } else {
      // Picker mode: fetch from picker session
      if (!config.sessionId) {
        photoCache = { items: [], fetchedAt: 0 };
        return;
      }
      const mediaItems = await fetchAllMediaItems(config.sessionId, accessToken);
      const allowedIds = config.mediaItemIds
        ? new Set(config.mediaItemIds)
        : null;
      photoCache = {
        items: mediaItems
          .filter((item) => item.mediaFile && item.mediaFile.baseUrl)
          .filter((item) => !allowedIds || allowedIds.has(item.id))
          .map((item) => ({
            id: item.id,
            baseUrl: item.mediaFile.baseUrl,
            mimeType: item.mediaFile.mimeType || "image/jpeg",
            filename: item.mediaFile.filename || item.id,
          })),
        fetchedAt: Date.now(),
      };
    }
  } catch (err) {
    console.error("Failed to refresh photo cache:", err.message);
    // Keep stale cache rather than clearing
  }
}

function isCacheStale() {
  return Date.now() - photoCache.fetchedAt > CACHE_TTL_MS;
}

// --- Static Files (CSS/JS always public, pages gated below) ---
app.use("/css", express.static(path.join(__dirname, "public/css")));
app.use("/js", express.static(path.join(__dirname, "public/js")));

// Login page (always public)
app.get("/login", (_req, res) => {
  res.sendFile(path.join(__dirname, "public/login.html"));
});
app.get("/login.html", (_req, res) => res.redirect("/login"));

// --- Login Routes ---
app.get("/login/google", (_req, res) => {
  try {
    const url = auth.getLoginUrl();
    res.redirect(url);
  } catch (err) {
    res.redirect("/login?error=failed");
  }
});

app.get("/login/callback", async (req, res) => {
  const { code } = req.query;
  if (!code) {
    return res.redirect("/login?error=failed");
  }

  try {
    const userInfo = await auth.verifyLoginCode(code);
    const role = auth.getRole(userInfo.email);

    if (!role) {
      return res.redirect("/login?error=denied");
    }

    req.session.email = userInfo.email;
    req.session.name = userInfo.name;
    req.session.picture = userInfo.picture;
    res.redirect(role === "admin" ? "/admin.html" : "/");
  } catch (err) {
    console.error("Login callback error:", err.message);
    res.redirect("/login?error=failed");
  }
});

app.post("/login/logout", (req, res) => {
  req.session = null;
  res.json({ ok: true });
});

app.get("/api/me", (req, res) => {
  if (!req.session || !req.session.email) {
    return res.status(401).json({ error: "Not authenticated" });
  }
  const role = auth.getRole(req.session.email);
  res.json({
    email: req.session.email,
    name: req.session.name,
    picture: req.session.picture,
    role,
  });
});

// --- Page Routes (auth gated) ---
app.get("/", auth.requireAuthPage("viewer"), (_req, res) => {
  res.sendFile(path.join(__dirname, "public/index.html"));
});

app.get("/index.html", (_req, res) => res.redirect("/"));

app.get("/admin.html", auth.requireAuthPage("admin"), (_req, res) => {
  res.sendFile(path.join(__dirname, "public/admin.html"));
});

// Uploads directory (viewer+)
app.use("/uploads", auth.requireAuth("viewer"), express.static(UPLOADS_DIR));

// --- Version check (public, for deploy verification) ---
app.get("/api/version", (_req, res) => {
  res.json({ version: "3.1.1", features: ["picker", "drive-random"] });
});

// Debug: check granted scopes (admin only)
app.get("/api/debug/scopes", auth.requireAuth("admin"), (_req, res) => {
  const tokens = loadTokens();
  if (!tokens) return res.json({ error: "No tokens" });
  res.json({ scope: tokens.scope });
});

// --- Google Photos Auth Routes (admin only) ---

// GET /auth/url — Generate OAuth consent URL
app.get("/auth/url", auth.requireAuth("admin"), (_req, res) => {
  try {
    const client = createOAuth2Client();
    const url = client.generateAuthUrl({
      access_type: "offline",
      prompt: "consent",
      scope: [
        "https://www.googleapis.com/auth/photospicker.mediaitems.readonly",
        "https://www.googleapis.com/auth/drive.readonly",
      ],
    });
    res.json({ url });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /auth/callback — OAuth2 redirect handler
app.get("/auth/callback", async (req, res) => {
  const { code } = req.query;
  if (!code) {
    return res.status(400).send("Missing authorization code");
  }

  try {
    const client = createOAuth2Client();
    const { tokens } = await client.getToken(code);
    console.log("OAuth tokens granted scope:", tokens.scope);
    saveTokens(tokens);
    // Redirect to admin page with success indicator
    res.redirect("/admin.html?auth=success");
  } catch (err) {
    console.error("OAuth callback error:", err.message);
    res.redirect("/admin.html?auth=error");
  }
});

// GET /auth/status — Check connection status + photo count
app.get("/auth/status", auth.requireAuth("admin"), async (_req, res) => {
  const tokens = loadTokens();
  if (!tokens) {
    return res.json({ connected: false });
  }

  const config = loadConfig();
  const photoCount = photoCache.items.length;

  res.json({
    connected: true,
    hasSession: !!(config && (config.sessionId || config.mode === "drive")),
    mode: config ? config.mode || "picker" : null,
    photoCount,
  });
});

// POST /auth/disconnect — Remove stored tokens and config
app.post("/auth/disconnect", auth.requireAuth("admin"), (_req, res) => {
  deleteTokens();
  deleteConfig();
  photoCache = { items: [], fetchedAt: 0 };
  res.json({ ok: true });
});

// --- Picker Routes ---

// POST /api/picker/session — Create a new Picker session
app.post("/api/picker/session", auth.requireAuth("admin"), async (_req, res) => {
  try {
    const accessToken = await getAccessToken();
    if (!accessToken) {
      return res.status(401).json({ error: "Not authenticated" });
    }

    const session = await createPickerSession(accessToken);
    res.json({
      id: session.id,
      pickerUri: session.pickerUri,
      expireTime: session.expireTime,
    });
  } catch (err) {
    console.error("Create picker session error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// GET /api/picker/session/:id — Poll session status
app.get("/api/picker/session/:id", auth.requireAuth("admin"), async (req, res) => {
  try {
    const accessToken = await getAccessToken();
    if (!accessToken) {
      return res.status(401).json({ error: "Not authenticated" });
    }

    const session = await getPickerSession(req.params.id, accessToken);
    res.json({
      id: session.id,
      mediaItemsSet: session.mediaItemsSet || false,
      pickerUri: session.pickerUri,
      expireTime: session.expireTime,
    });
  } catch (err) {
    console.error("Poll picker session error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/picker/confirm — Save session and populate cache
app.post("/api/picker/confirm", auth.requireAuth("admin"), async (req, res) => {
  const { sessionId } = req.body;
  if (!sessionId) {
    return res.status(400).json({ error: "sessionId required" });
  }

  try {
    const accessToken = await getAccessToken();
    if (!accessToken) {
      return res.status(401).json({ error: "Not authenticated" });
    }

    // Fetch media items from the session
    const mediaItems = await fetchAllMediaItems(sessionId, accessToken);

    // Save session config
    saveConfig({
      sessionId,
      mediaItemIds: mediaItems.map((item) => item.id),
      confirmedAt: new Date().toISOString(),
    });

    // Populate cache
    photoCache = {
      items: mediaItems
        .filter((item) => item.mediaFile && item.mediaFile.baseUrl)
        .map((item) => ({
          id: item.id,
          baseUrl: item.mediaFile.baseUrl,
          mimeType: item.mediaFile.mimeType || "image/jpeg",
          filename: item.mediaFile.filename || item.id,
        })),
      fetchedAt: Date.now(),
    };

    res.json({ ok: true, photoCount: photoCache.items.length });
  } catch (err) {
    console.error("Confirm picker error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// --- Drive API Helpers ---
const DRIVE_API = "https://www.googleapis.com/drive/v3";

async function listDrivePhotos(accessToken, pageToken) {
  const q = "mimeType contains 'image/' and trashed = false";
  let url = `${DRIVE_API}/files?q=${encodeURIComponent(q)}&pageSize=100&fields=nextPageToken,files(id,name,mimeType,thumbnailLink,webContentLink)`;
  if (pageToken) {
    url += `&pageToken=${encodeURIComponent(pageToken)}`;
  }
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Failed to list Drive photos: ${res.status} ${text}`);
  }
  const data = await res.json();
  console.log(`Drive API returned ${(data.files || []).length} files (page token: ${!!data.nextPageToken})`);
  return data;
}

// Fisher-Yates shuffle
function shuffleArray(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

// --- Random Photos Route (via Google Drive API) ---

// POST /api/library/random — Fetch random photos from Google Drive
app.post("/api/library/random", auth.requireAuth("admin"), async (_req, res) => {
  try {
    const accessToken = await getAccessToken();
    if (!accessToken) {
      return res.status(401).json({ error: "Not authenticated with Google Photos" });
    }

    // Fetch up to 500 image files from Drive (5 pages of 100)
    const allFiles = [];
    let pageToken = undefined;
    const maxPages = 5;
    for (let page = 0; page < maxPages; page++) {
      const result = await listDrivePhotos(accessToken, pageToken);
      if (result.files) {
        allFiles.push(...result.files);
      }
      pageToken = result.nextPageToken;
      if (!pageToken) break;
    }

    if (allFiles.length === 0) {
      // Try a broader query to diagnose
      const debugRes = await fetch(`${DRIVE_API}/files?pageSize=5&fields=files(id,name,mimeType)`, {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      const debugData = await debugRes.json();
      console.log("Debug - any files at all:", JSON.stringify(debugData));
      return res.status(404).json({
        error: "No image files found in Google Drive",
        hint: "Google Photos and Google Drive are separate. Photos must be in Drive.",
        debugFileCount: (debugData.files || []).length,
        debugSampleFiles: (debugData.files || []).slice(0, 3).map(f => ({ name: f.name, mimeType: f.mimeType })),
      });
    }

    // Randomly select up to 50
    const selected = shuffleArray(allFiles).slice(0, 50);

    // Save config with drive mode
    saveConfig({
      mode: "drive",
      mediaItemIds: selected.map((f) => f.id),
      confirmedAt: new Date().toISOString(),
    });

    // Populate cache — use Drive file ID as the photo ID
    photoCache = {
      items: selected.map((f) => ({
        id: f.id,
        baseUrl: `https://www.googleapis.com/drive/v3/files/${f.id}?alt=media`,
        mimeType: f.mimeType || "image/jpeg",
        filename: f.name || f.id,
      })),
      fetchedAt: Date.now(),
    };

    res.json({ ok: true, photoCount: photoCache.items.length });
  } catch (err) {
    console.error("Drive random error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// --- Local Upload Routes ---

// POST /api/upload — Upload local photos
app.post("/api/upload", auth.requireAuth("admin"), upload.array("photos", 50), (req, res) => {
  const uploaded = req.files.map((f) => ({
    filename: f.filename,
    url: `/uploads/${encodeURIComponent(f.filename)}`,
  }));
  res.json({ uploaded });
});

// DELETE /api/photos/:id — Remove a photo (Google Photos or local)
app.delete("/api/photos/:id", auth.requireAuth("admin"), (_req, res) => {
  const photoId = _req.params.id;

  // Check if it's a local file
  const localPath = path.join(UPLOADS_DIR, photoId);
  if (path.dirname(localPath) === UPLOADS_DIR && fs.existsSync(localPath)) {
    fs.unlinkSync(localPath);
    return res.json({ deleted: photoId });
  }

  // Otherwise remove from Google Photos cache
  const index = photoCache.items.findIndex((p) => p.id === photoId);
  if (index === -1) {
    return res.status(404).json({ error: "Photo not found" });
  }
  photoCache.items.splice(index, 1);

  const config = loadConfig();
  if (config) {
    config.mediaItemIds = config.mediaItemIds.filter((id) => id !== photoId);
    saveConfig(config);
  }

  res.json({ deleted: photoId, photoCount: photoCache.items.length });
});

// --- Photo Routes ---

// Helper: list local uploaded photos
function getLocalPhotos() {
  if (!fs.existsSync(UPLOADS_DIR)) return [];
  const files = fs.readdirSync(UPLOADS_DIR).filter((f) => {
    const ext = path.extname(f).toLowerCase();
    return ALLOWED_EXTENSIONS.has(ext);
  });
  files.sort((a, b) => {
    const statA = fs.statSync(path.join(UPLOADS_DIR, a));
    const statB = fs.statSync(path.join(UPLOADS_DIR, b));
    return statB.mtimeMs - statA.mtimeMs;
  });
  return files.map((f) => ({
    id: f,
    filename: f,
    url: `/uploads/${encodeURIComponent(f)}`,
    source: "local",
  }));
}

// GET /api/photos — Returns merged list (Google Photos + local uploads)
app.get("/api/photos", auth.requireAuth("viewer"), async (_req, res) => {
  // Refresh Google Photos cache if stale
  if (isCacheStale() && loadConfig()) {
    await refreshCache();
  }

  const googlePhotos = photoCache.items.map((item) => ({
    id: item.id,
    filename: item.filename,
    url: `/api/photo/${encodeURIComponent(item.id)}`,
    source: "google",
  }));

  const localPhotos = getLocalPhotos();

  res.json([...googlePhotos, ...localPhotos]);
});

// GET /api/photo/:id — Image proxy: fetches bytes from Google with auth header
app.get("/api/photo/:id", auth.requireAuth("viewer"), async (req, res) => {
  const photoId = req.params.id;
  const item = photoCache.items.find((p) => p.id === photoId);

  if (!item) {
    return res.status(404).json({ error: "Photo not found" });
  }

  try {
    const accessToken = await getAccessToken();
    if (!accessToken) {
      return res.status(401).json({ error: "Not authenticated" });
    }

    // Append size parameters to baseUrl for full resolution
    const imageUrl = `${item.baseUrl}=w2048`;

    const response = await fetch(imageUrl, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!response.ok) {
      // If baseUrl expired, try refreshing cache and retrying
      if (response.status === 403 || response.status === 401) {
        await refreshCache();
        const refreshedItem = photoCache.items.find((p) => p.id === photoId);
        if (refreshedItem) {
          const retryUrl = `${refreshedItem.baseUrl}=w2048`;
          const retryResponse = await fetch(retryUrl, {
            headers: { Authorization: `Bearer ${accessToken}` },
          });
          if (retryResponse.ok) {
            res.set("Content-Type", refreshedItem.mimeType);
            res.set("Cache-Control", "private, max-age=1800");
            const buffer = Buffer.from(await retryResponse.arrayBuffer());
            return res.send(buffer);
          }
        }
      }
      return res.status(response.status).json({ error: "Failed to fetch photo" });
    }

    res.set("Content-Type", item.mimeType);
    res.set("Cache-Control", "private, max-age=1800");
    const buffer = Buffer.from(await response.arrayBuffer());
    res.send(buffer);
  } catch (err) {
    console.error("Photo proxy error:", err.message);
    res.status(500).json({ error: "Failed to fetch photo" });
  }
});

// --- Startup ---
app.listen(PORT, async () => {
  console.log(`Photo viewer running at http://localhost:${PORT}`);
  console.log(`Slideshow:  http://localhost:${PORT}/`);
  console.log(`Admin:      http://localhost:${PORT}/admin.html`);

  // Load cache on startup if we have tokens + config
  if (loadTokens() && loadConfig()) {
    console.log("Refreshing photo cache from Google Photos...");
    await refreshCache();
    console.log(`Loaded ${photoCache.items.length} photos into cache`);
  }
});
