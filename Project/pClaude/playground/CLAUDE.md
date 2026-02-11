# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Digital Photo Viewer — a web-based screensaver slideshow for iPad. Express.js backend with vanilla HTML/CSS/JS frontend.

## Build & Run

```bash
npm install          # Install dependencies
node server.js       # Start server on :3000
```

- Slideshow viewer: `http://localhost:3000/`
- Admin upload: `http://localhost:3000/admin.html`

## Architecture

- `server.js` — Express server with multer for uploads, REST API for photos
- `public/index.html` — Full-screen slideshow with crossfade + Ken Burns effect
- `public/admin.html` — Drag-and-drop upload UI with photo management
- `public/js/slideshow.js` — Slideshow logic (auto-advance, Wake Lock, tap to pause)
- `public/js/admin.js` — Upload and delete logic
- `uploads/` — Stored photos (gitignored)

## API

- `GET /api/photos` — list uploaded photos
- `POST /api/upload` — upload photos (multipart, field name: `photos`)
- `DELETE /api/photos/:filename` — delete a photo
