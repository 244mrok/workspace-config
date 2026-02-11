const { OAuth2Client } = require("google-auth-library");

// --- Email Whitelist ---
function parseEmails(envVar) {
  const val = process.env[envVar];
  if (!val) return [];
  return val
    .split(",")
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);
}

const adminEmails = parseEmails("ALLOWED_ADMIN_EMAILS");
const viewerEmails = parseEmails("ALLOWED_VIEWER_EMAILS");

// Returns "admin", "viewer", or null
function getRole(email) {
  if (!email) return null;
  const lower = email.toLowerCase();
  if (adminEmails.includes(lower)) return "admin";
  if (viewerEmails.includes(lower)) return "viewer";
  return null;
}

// --- Login OAuth (separate from Photos Picker OAuth) ---
function getBaseUrl() {
  return process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
}

function getLoginRedirectUri() {
  return `${getBaseUrl()}/login/callback`;
}

function getPickerRedirectUri() {
  return `${getBaseUrl()}/auth/callback`;
}

function createLoginClient() {
  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
  if (!clientId || !clientSecret) {
    throw new Error(
      "GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET env vars are required"
    );
  }
  return new OAuth2Client(clientId, clientSecret, getLoginRedirectUri());
}

function getLoginUrl() {
  const client = createLoginClient();
  return client.generateAuthUrl({
    access_type: "online",
    scope: ["openid", "email", "profile"],
  });
}

async function verifyLoginCode(code) {
  const client = createLoginClient();
  const { tokens } = await client.getToken(code);
  client.setCredentials(tokens);

  // Fetch user info
  const res = await fetch(
    "https://www.googleapis.com/oauth2/v2/userinfo",
    { headers: { Authorization: `Bearer ${tokens.access_token}` } }
  );
  if (!res.ok) {
    throw new Error("Failed to fetch user info");
  }
  return res.json(); // { id, email, name, picture }
}

// --- Middleware ---
function requireAuth(minRole) {
  // minRole: "viewer" (viewer or admin) or "admin" (admin only)
  return (req, res, next) => {
    const session = req.session;
    if (!session || !session.email) {
      return res.status(401).json({ error: "Not authenticated" });
    }

    const role = getRole(session.email);
    if (!role) {
      return res.status(403).json({ error: "Access denied" });
    }

    if (minRole === "admin" && role !== "admin") {
      return res.status(403).json({ error: "Admin access required" });
    }

    next();
  };
}

// Page-level auth: redirects to /login instead of returning JSON
function requireAuthPage(minRole) {
  return (req, res, next) => {
    const session = req.session;
    if (!session || !session.email) {
      return res.redirect("/login");
    }

    const role = getRole(session.email);
    if (!role) {
      return res.redirect("/login?error=denied");
    }

    if (minRole === "admin" && role !== "admin") {
      return res.redirect("/login?error=denied");
    }

    next();
  };
}

function isAuthConfigured() {
  return adminEmails.length > 0 || viewerEmails.length > 0;
}

module.exports = {
  getRole,
  getLoginUrl,
  verifyLoginCode,
  requireAuth,
  requireAuthPage,
  getBaseUrl,
  getPickerRedirectUri,
  createLoginClient,
  isAuthConfigured,
};
