const express = require("express");
const { OAuth2Client } = require("google-auth-library");
const path = require("path");
const fs = require("fs");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const DATA_DIR = path.join(__dirname, "data");
const TOKENS_PATH = path.join(DATA_DIR, "tokens.json");
const CONFIG_PATH = path.join(DATA_DIR, "config.json");

const PICKER_API = "https://photospicker.googleapis.com/v1";
const CACHE_TTL_MS = 50 * 60 * 1000; // 50 minutes

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

// --- OAuth2 Client ---
const REDIRECT_URI = () =>
  `http://localhost:${PORT}/auth/callback`;

function createOAuth2Client() {
  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
  if (!clientId || !clientSecret) {
    throw new Error(
      "GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET env vars are required"
    );
  }
  return new OAuth2Client(clientId, clientSecret, REDIRECT_URI());
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

// Refresh the photo cache from the stored picker session
async function refreshCache() {
  const config = loadConfig();
  if (!config || !config.sessionId) {
    photoCache = { items: [], fetchedAt: 0 };
    return;
  }

  const accessToken = await getAccessToken();
  if (!accessToken) {
    photoCache = { items: [], fetchedAt: 0 };
    return;
  }

  try {
    const mediaItems = await fetchAllMediaItems(config.sessionId, accessToken);
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
  } catch (err) {
    console.error("Failed to refresh photo cache:", err.message);
    // Keep stale cache rather than clearing
  }
}

function isCacheStale() {
  return Date.now() - photoCache.fetchedAt > CACHE_TTL_MS;
}

// --- Static Files ---
app.use(express.static(path.join(__dirname, "public")));

// --- Auth Routes ---

// GET /auth/url — Generate OAuth consent URL
app.get("/auth/url", (_req, res) => {
  try {
    const client = createOAuth2Client();
    const url = client.generateAuthUrl({
      access_type: "offline",
      prompt: "consent",
      scope: [
        "https://www.googleapis.com/auth/photospicker.mediaitems.readonly",
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
    saveTokens(tokens);
    // Redirect to admin page with success indicator
    res.redirect("/admin.html?auth=success");
  } catch (err) {
    console.error("OAuth callback error:", err.message);
    res.redirect("/admin.html?auth=error");
  }
});

// GET /auth/status — Check connection status + photo count
app.get("/auth/status", async (_req, res) => {
  const tokens = loadTokens();
  if (!tokens) {
    return res.json({ connected: false });
  }

  const config = loadConfig();
  const photoCount = photoCache.items.length;

  res.json({
    connected: true,
    hasSession: !!(config && config.sessionId),
    photoCount,
  });
});

// POST /auth/disconnect — Remove stored tokens and config
app.post("/auth/disconnect", (_req, res) => {
  deleteTokens();
  deleteConfig();
  photoCache = { items: [], fetchedAt: 0 };
  res.json({ ok: true });
});

// --- Picker Routes ---

// POST /api/picker/session — Create a new Picker session
app.post("/api/picker/session", async (_req, res) => {
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
app.get("/api/picker/session/:id", async (req, res) => {
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
app.post("/api/picker/confirm", async (req, res) => {
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

// --- Photo Routes ---

// GET /api/photos — Returns photo list (same shape as before for slideshow compatibility)
app.get("/api/photos", async (_req, res) => {
  // Refresh cache if stale
  if (isCacheStale() && loadConfig()) {
    await refreshCache();
  }

  const photos = photoCache.items.map((item) => ({
    filename: item.filename,
    url: `/api/photo/${encodeURIComponent(item.id)}`,
  }));

  res.json(photos);
});

// GET /api/photo/:id — Image proxy: fetches bytes from Google with auth header
app.get("/api/photo/:id", async (req, res) => {
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
    const imageUrl = `${item.baseUrl}=w2048-h2048`;

    const response = await fetch(imageUrl, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!response.ok) {
      // If baseUrl expired, try refreshing cache and retrying
      if (response.status === 403 || response.status === 401) {
        await refreshCache();
        const refreshedItem = photoCache.items.find((p) => p.id === photoId);
        if (refreshedItem) {
          const retryUrl = `${refreshedItem.baseUrl}=w2048-h2048`;
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
