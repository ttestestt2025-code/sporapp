# LAST SIGNAL — Asset License & Provenance

All assets in this project are **original** works generated for LAST SIGNAL. There are **no third-party or externally-licensed assets**. The project is safe to use, modify, and ship as an original commercial indie title.

Status legend: **Project-owned** = created for this project and owned by the project; free to use/modify/distribute.

---

## Visual Assets

| Asset | Path | Source / Tool | Generation method | License status |
|---|---|---|---|---|
| Key art | `assets/branding/key_art.png` | AI image generation (Gemini image model) | Text-to-image, prompt-authored for this project | Project-owned |
| Logo wordmark | `assets/branding/logo.png` | AI image generation (GPT Image) | Text-to-image | Project-owned |
| App icon | `assets/branding/app_icon.png` | AI image generation (Gemini image model) | Text-to-image | Project-owned |
| Signal Keeper sprite | `assets/sprites/player/signal_keeper.png` | AI image generation (Gemini flash image) | Text-to-image → chroma-key to transparency → autocrop → nearest-neighbor downscale (Pillow) | Project-owned |
| Corrupted Walker sprite | `assets/sprites/enemies/corrupted_walker.png` | AI image generation | Same sprite pipeline | Project-owned |
| Shadow Crawler sprite | `assets/sprites/enemies/shadow_crawler.png` | AI image generation | Same sprite pipeline | Project-owned |
| Mutated Brute sprite | `assets/sprites/enemies/mutated_brute.png` | AI image generation | Same sprite pipeline | Project-owned |
| Sparker sprite | `assets/sprites/enemies/sparker.png` | AI image generation | Same sprite pipeline | Project-owned |
| Ruptor sprite | `assets/sprites/enemies/ruptor.png` | AI image generation | Same sprite pipeline | Project-owned |
| Project icon | `icon.svg` | Hand-authored SVG | Vector, written for this project | Project-owned |
| Bosses, projectiles, pickups, VFX | (in-engine) | Godot `_draw` / GPUParticles | Procedurally drawn at runtime (no image files) | Project-owned |

**Sprite pipeline detail:** sprites were generated on a flat magenta (`#ff00ff`) background, then keyed to transparency (magenta-ness threshold), auto-cropped to content, and downscaled with nearest-neighbor to preserve crisp pixel edges. The renderer falls back to procedurally-drawn shapes if any sprite is missing, so the game is always playable.

---

## Audio Assets

| Asset | Path | Source / Tool | Generation method | License status |
|---|---|---|---|---|
| Music (menu, stage1–3, boss, victory) | `audio/music/*.wav` | `tools/generate_audio.py` (numpy) | Procedural synthesis — oscillators, envelopes, a step sequencer over minor/phrygian scales | Project-owned |
| SFX (14 effects) | `audio/sfx/*.wav` | `tools/generate_audio.py` (numpy) | Procedural synthesis — pitch-swept oscillators + filtered noise with AD envelopes | Project-owned |

All audio is deterministic and reproducible by running `python3 tools/generate_audio.py` from the project root.

---

## Code

| Item | Source | License status |
|---|---|---|
| All GDScript (`scripts/**`) | Original, written for this project | Project-owned |
| Data tables & balance | Original | Project-owned |
| Audio generator (`tools/generate_audio.py`) | Original | Project-owned |

## Engine

- **Godot Engine 4.3** — MIT License (© Juan Linietsky, Ariel Manzur, and contributors). Not redistributed in this repository; download from godotengine.org.
