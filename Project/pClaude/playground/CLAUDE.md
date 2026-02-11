# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Digital Photo Viewer — a web-based screensaver slideshow for iPad, powered by Google Photos. Express.js backend with vanilla HTML/CSS/JS frontend. Uses the Google Photos Picker API to select photos, proxied through the server.

## Setup

1. Create a Google Cloud project with the Photos Picker API enabled
2. Create OAuth 2.0 credentials (Web application type) with redirect URI `http://localhost:3000/auth/callback`
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

## Architecture

- `server.js` — Express server with OAuth2, Google Photos Picker API integration, and image proxy
- `public/index.html` — Full-screen slideshow with crossfade + Ken Burns effect
- `public/admin.html` — Google Photos connection and photo picker UI
- `public/js/slideshow.js` — Slideshow logic (auto-advance, Wake Lock, tap to pause)
- `public/js/admin.js` — OAuth flow, picker session management, status display
- `data/tokens.json` — OAuth refresh token (gitignored, auto-created)
- `data/config.json` — Picker session ID and media item IDs (gitignored)

## API

- `GET /auth/url` — Generate Google OAuth consent URL
- `GET /auth/callback` — OAuth2 redirect handler
- `GET /auth/status` — Check connection status + photo count
- `POST /auth/disconnect` — Remove stored tokens and config
- `POST /api/picker/session` — Create a Picker session (returns `pickerUri`)
- `GET /api/picker/session/:id` — Poll session status (`mediaItemsSet`)
- `POST /api/picker/confirm` — Save session and populate photo cache
- `GET /api/photos` — List photos (consumed by slideshow)
- `GET /api/photo/:id` — Image proxy (fetches from Google with auth header)

## Key Design Decisions

- **Server-side image proxy**: Google Photos `baseUrl` requires Authorization header, so `<img>` tags point to `/api/photo/:id` which proxies bytes. Slideshow JS needs zero changes.
- **In-memory cache with 50-min TTL**: `baseUrl` expires after ~60 min. Server caches metadata and refreshes from Picker API when stale.
- **Picker session expiry**: After session expires, admin re-picks photos (~10 seconds). Acceptable for personal use.
