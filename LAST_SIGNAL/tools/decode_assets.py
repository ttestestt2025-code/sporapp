#!/usr/bin/env python3
"""Materialize LAST SIGNAL's image assets from tools/assets_b64.json.

The delivery pipeline for this repo could not push raw binary files, so the
in-game sprites, app icon, and marketing screenshots are stored base64-encoded
in tools/assets_b64.json. Run this once to write the real PNG files:

    python3 tools/decode_assets.py

The game runs fine without them (the renderer falls back to procedurally-drawn
shapes), but this restores the intended pixel art. CI runs this automatically
before exporting. Full-resolution key art and logo ship in the project archive.
"""
import json, base64, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
manifest = json.load(open(os.path.join(ROOT, "tools", "assets_b64.json")))
for rel, b64 in manifest.items():
    dest = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, "wb") as fh:
        fh.write(base64.b64decode(b64))
    print("wrote", rel)
print("done: %d image assets" % len(manifest))
