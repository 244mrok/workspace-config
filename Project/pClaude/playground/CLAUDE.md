# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Digital Photo Viewer — a web-based screensaver slideshow for iPad. Express.js backend with vanilla HTML/CSS/JS frontend. Supports two photo sources: Google Photos (via Picker API) and local file uploads. Both are merged into a single slideshow. Protected by Google SSO with email whitelisting.

## Setup

### Authentication (required)

Set environment variables for access control:

```bash
export ALLOWED_ADMIN_EMAILS="admin@gmail.com"          # Can upload/manage photos
export ALLOWED_VIEWER_EMAILS="viewer@gmail.com"        # Can view slideshow only
export SESSION_SECRET="random-secret-string"           # Signs session cookie
export BASE_URL="https://your-app.onrender.com"        # For OAuth redirect URIs (falls back to localhost:3000)
```

Add authorized redirect URIs in Google Cloud Console:
- `http://localhost:3000/login/callback` (local dev)
- `http://localhost:3000/auth/callback` (Google Photos Picker)
- `https://your-app.onrender.com/login/callback` (production)
- `https://your-app.onrender.com/auth/callback` (production)

### Google Photos integration (optional)

1. Create a Google Cloud project with the Photos Picker API enabled
2. Create OAuth 2.0 credentials (Web application type)
3. Set environment variables:
   ```bash
   export GOOGLE_CLIENT_ID="your-client-id"
   export GOOGLE_CLIENT_SECRET="your-client-secret"
   ```

## Build & Run

```bash
npm install          # Install dependencies (requires Node.js 18+)
node server.js       # Start server on :3000
```

- Slideshow viewer: `http://localhost:3000/`
- Admin panel: `http://localhost:3000/admin.html`
- Login page: `http://localhost:3000/login`

## Architecture

- `server.js` — Express server with session auth, OAuth2, Google Photos Picker API, local uploads (multer), and image proxy
- `auth.js` — Google SSO login, email whitelist, role resolution, requireAuth middleware
- `public/login.html` — Sign-in page with Google SSO button
- `public/index.html` — Full-screen slideshow with crossfade + Ken Burns effect (`object-fit: contain`)
- `public/admin.html` — Google Photos connection, photo picker, drag-and-drop upload, and photo grid
- `public/js/slideshow.js` — Slideshow logic (auto-advance, Wake Lock, tap to pause, 401 redirect)
- `public/js/admin.js` — OAuth flow, picker session management, local upload, delete, user display
- `uploads/` — Local uploaded photos (gitignored)
- `data/tokens.json` — OAuth refresh token (gitignored, auto-created)
- `data/config.json` — Picker session ID and media item IDs (gitignored)

## API

### Login (public)
- `GET /login` — Login page
- `GET /login/google` — Redirect to Google SSO
- `GET /login/callback` — Google SSO callback
- `POST /login/logout` — Clear session
- `GET /api/me` — Current user info + role

### Viewer (viewer or admin)
- `GET /` — Slideshow page
- `GET /api/photos` — List all photos from both sources
- `GET /api/photo/:id` — Image proxy for Google Photos
- `GET /uploads/*` — Local uploaded photos

### Admin only
- `GET /admin.html` — Admin panel
- `GET /auth/url` — Generate Google Photos OAuth consent URL
- `GET /auth/callback` — Google Photos OAuth redirect handler
- `GET /auth/status` — Check Google Photos connection status + photo count
- `POST /auth/disconnect` — Remove stored tokens and config
- `POST /api/picker/session` — Create a Picker session (returns `pickerUri`)
- `GET /api/picker/session/:id` — Poll session status (`mediaItemsSet`)
- `POST /api/picker/confirm` — Save session and populate photo cache
- `POST /api/upload` — Upload local photos (multipart, field name: `photos`)
- `DELETE /api/photos/:id` — Remove a photo (local file or Google Photos selection)

## Key Design Decisions

- **Google SSO with email whitelist**: Two roles (admin, viewer) controlled by `ALLOWED_ADMIN_EMAILS` and `ALLOWED_VIEWER_EMAILS` env vars. Uses `cookie-session` with 30-day lifetime for iPad persistence.
- **Two separate OAuth flows**: Login uses `openid email profile` scopes (online access), Photos Picker uses `photospicker.mediaitems.readonly` (offline access with refresh token). Both share the same Google Cloud credentials.
- **Server-side image proxy**: Google Photos `baseUrl` requires Authorization header, so `<img>` tags point to `/api/photo/:id` which proxies bytes. Slideshow JS needs zero changes.
- **In-memory cache with 50-min TTL**: `baseUrl` expires after ~60 min. Server caches metadata and refreshes from Picker API when stale.
- **Picker session expiry**: After session expires, admin re-picks photos (~10 seconds). Acceptable for personal use.
