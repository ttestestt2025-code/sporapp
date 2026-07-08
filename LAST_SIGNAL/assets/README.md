# Assets

The in-game sprites, app icon, and marketing screenshots are stored base64-encoded in
`tools/assets_b64.json` (the delivery pipeline could not push raw binary files). Materialize them:

```bash
python3 tools/decode_assets.py
```

This writes the real PNGs into `assets/sprites/`, `assets/branding/`, and `marketing/screenshots/`.
The game runs without them — the renderer falls back to procedurally-drawn shapes. Full-resolution
key art and logo are included in the delivered project archive.

All assets are original and project-owned; see `docs/ASSET_LICENSE.md`.
