# LAST SIGNAL

> A post-apocalyptic 2D arcade survivor / bullet-heaven roguelite. You are **The Signal Keeper** — the last operator of humanity's final communication station. Hold the perimeter against endless waves of the Corrupted, grow into a walking weapons platform, defeat the bosses, and **restore the Last Signal**.

**Engine:** Godot 4.3+ · **Language:** GDScript (typed) · **Renderer:** GL Compatibility (web + low-end friendly)

![Key Art](assets/branding/key_art.png)

---

## Features

- **Auto-combat survivor gameplay** — move to survive; weapons fire themselves.
- **8 weapons**, each with 8 upgrade levels and distinct behavior: Energy Rifle, Plasma Rifle, Shock Wave, Pulse Wave, Drone Companion, Energy Mine, Laser Beam, Nano Swarm.
- **25 upgrades** (8 weapons + 17 passives) offered 3-at-a-time on level up, weighted by rarity and Luck.
- **5 enemy archetypes** + **3 bosses** — Corrupted Walker, Shadow Crawler, Mutated Brute, Sparker, Ruptor; Corrupted Colossus, Facility Warden, and the final **Signal Devourer**.
- **3 stages** with distinct palettes and escalation: Abandoned City, Destroyed Research Facility, Corrupted Communication Tower.
- **Meta-progression** — earn Scrap, buy 10 permanent Station upgrades, unlock Endless mode and the Scavenger character. Saved to `user://`.
- **Full UI** — main menu, HUD (health, XP, weapons, timer, score, Scrap, boss bar), 3-card upgrade select, pause, settings, first-run tutorial, results screens.
- **Accessibility** — colorblind-safe fragment shapes, toggles for screen shake / damage numbers / flashes, volume sliders, difficulty modes, one-hand touch controls.
- **Original assets** — AI-generated dark sci-fi pixel art + procedurally synthesized music and SFX. No third-party asset dependencies.
- **Performance-first** — object pooling, spatial-hash collisions, adaptive particle budget; targets a stable 60 FPS on low-end hardware.

---

## Controls

| Action | Keyboard | Touch |
|---|---|---|
| Move | WASD / Arrow keys | Drag anywhere (virtual joystick) |
| Attack | Automatic | Automatic |
| Pause | Esc / P | Pause button |
| Choose upgrade | 1 / 2 / 3 or click | Tap a card |

---

## Run & Build

This repository **is** the Godot project (the repo root contains `project.godot`).

### Play in the editor
1. Install **Godot 4.3+** (standard build) from <https://godotengine.org>.
2. *(Optional, for sound)* generate the procedural audio: `python3 tools/generate_audio.py` (needs numpy). Audio is git-ignored as a generated asset; the game runs silent without it.
3. Open the Godot Project Manager → **Import** → select this repo's `project.godot`.
4. First open auto-imports assets. Press **F5** (Play) to run.

### Export a Web build
```bash
# One-time: install export templates in the editor
#   Editor → Manage Export Templates → Download and Install
godot --headless --path . --export-release "Web" build/web/index.html
# Serve it (any static server works — this build is single-threaded, no special headers needed):
python3 -m http.server --directory build/web 8080
# open http://localhost:8080/index.html
```

### Export an Android APK
```bash
# One-time setup in the editor:
#   Editor → Manage Export Templates → Download and Install
#   Editor → Editor Settings → Export → Android → set Java SDK / Android SDK paths
#   Project → Install Android Build Template
godot --headless --path . --export-debug "Android" build/android/last_signal.apk
```
Export presets for **Web** and **Android** are included in `export_presets.cfg`.

> **Note on this repository:** the game was authored and validated with a headless Godot 4.3 toolchain — it **imports with zero script errors** and passes a **headless runtime smoke test** (see `docs/QA_REPORT.md`), and a **Web build was produced successfully**. Because the authoring environment has no GPU/GL, final on-device visual QA and the signed Android build should be produced on your machine using the steps above.

---

## Project Structure

```
LAST_SIGNAL/
├── project.godot          engine config + autoloads
├── export_presets.cfg     Web + Android export presets
├── icon.svg
├── scenes/main/Main.tscn  single entry scene (state machine builds the rest in code)
├── scripts/
│   ├── autoload/          Events, GameData, SaveSystem, AudioManager
│   ├── core/              util, pool, grid
│   ├── data/              WeaponData, PassiveData, EnemyData, StageData
│   ├── entities/          Player, Enemy, Projectile, Pickup
│   ├── weapons/           WeaponRunner
│   ├── systems/           Spawner, UpgradeManager, VFX
│   ├── ui/                MainMenu, HUD, UpgradeSelect, PauseMenu, SettingsMenu, GameOver, Victory, Station, Tutorial, UI
│   └── main/              Main, World
├── assets/                sprites (dark sci-fi pixel art) + branding
├── audio/                 music/ + sfx/ (original synthesized WAV)
├── tools/generate_audio.py  reproducible audio generator
├── docs/                  GDD, TECHNICAL_PLAN, QA_REPORT, ASSET_LICENSE
└── marketing/             store page, trailer script, social, screenshots
```

See `docs/GDD.md` for full design and `docs/TECHNICAL_PLAN.md` for architecture.

---

## Credits & License

- **Design, code, art direction, audio:** generated by the HyperAgent autonomous game studio.
- **Art:** AI-generated dark sci-fi pixel art (see `docs/ASSET_LICENSE.md` for provenance).
- **Audio:** original, procedurally synthesized with `tools/generate_audio.py`.

Code and assets in this repository are original works produced for this project. See `docs/ASSET_LICENSE.md` for per-asset license status.
