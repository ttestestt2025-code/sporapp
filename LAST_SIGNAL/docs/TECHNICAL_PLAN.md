# LAST SIGNAL — Technical Plan

**Engine:** Godot 4.3+ · **Language:** GDScript (typed) · **Renderer:** GL Compatibility (best for web + low-end + mobile)

---

## 1. Goals

- Modular, cleanly separated systems that are easy to expand.
- Data-driven content: weapons, upgrades, enemies, and stages are `Resource` objects, so adding content is data, not new plumbing.
- Decoupled via a global signal bus (`Events`) — systems talk through signals, not hard references.
- Performance-first: object pooling for all transient entities, a spatial grid for area queries, capped particle counts, and the GL Compatibility renderer for a stable 60 FPS on low-end devices.
- Runs offline; no external runtime dependencies.

---

## 2. Project Layout

```
LAST_SIGNAL/                 (Godot project root == repo root)
├── project.godot            engine config + autoloads
├── icon.svg
├── export_presets.cfg       Web + Android export presets
├── scenes/
│   └── main/Main.tscn       single entry scene; a state machine builds everything in code
├── scripts/
│   ├── autoload/            Events, GameData, SaveSystem, AudioManager (singletons)
│   ├── core/                Pool, SpatialGrid, RNG/util, Palette
│   ├── data/                WeaponData, UpgradeData, EnemyData, StageData (Resource classes) + registry builder
│   ├── entities/            Player, Enemy, Projectile, Pickup, Boss, DamageNumber
│   ├── weapons/             WeaponRunner (interprets WeaponData by type)
│   ├── systems/             Spawner, WaveDirector, UpgradeManager, VFX, CameraRig
│   ├── ui/                  MainMenu, HUD, UpgradeSelect, PauseMenu, SettingsMenu, GameOver, Victory, Station, Tutorial
│   └── main/                Main.gd (root state machine), World.gd (gameplay scene)
├── assets/                  sprites, backgrounds, ui, icons, branding (PNG, dark sci-fi pixel art)
├── audio/                   music/ + sfx/ (original synthesized .wav)
├── docs/                    GDD, TECHNICAL_PLAN, QA_REPORT, ASSET_LICENSE
└── marketing/               description, store page, trailer script, social, screenshots
```

Scenes are intentionally minimal (`Main.tscn` is a bare root + script). Entities, UI, and the world are **constructed in code**, which keeps the project self-contained, diff-friendly, and reliable to build without hand-wiring dozens of `.tscn` files. A team can later extract any runtime-built node into its own scene without changing the architecture.

---

## 3. Autoload Singletons

| Autoload | Responsibility |
|---|---|
| **Events** | Global signal bus: `enemy_killed`, `player_leveled_up`, `player_damaged`, `fragment_collected`, `boss_spawned`, `boss_killed`, `run_ended`, `stage_changed`, `upgrade_selected`, etc. |
| **GameData** | Builds & holds the content registry (all `WeaponData`, `UpgradeData`, `EnemyData`, `StageData`); sets up the InputMap in code; exposes balance constants. |
| **SaveSystem** | Loads/saves the JSON profile in `user://last_signal_save.json` (Scrap, station upgrades, unlocks, stats, settings). Robust with try/guards. |
| **AudioManager** | Music & SFX buses; plays synthesized tracks per scene and throttled SFX. |

InputMap actions (`move_up/down/left/right`, `pause`, `confirm`, `restart`, `ui_1..3`) are registered in code by `GameData` so there is no fragile serialized input in `project.godot`.

---

## 4. Core Systems

- **Pool** (`core/pool.gd`): generic free-list pool; every projectile, enemy, pickup, particle, and damage number is pooled to eliminate per-frame allocation.
- **SpatialGrid** (`core/grid.gd`): uniform hash grid rebuilt each physics tick; used for projectile↔enemy and enemy↔player broad-phase and for weapon area queries.
- **WeaponRunner** (`weapons/weapon_runner.gd`): reads a `WeaponData.type` (`bolt`, `splash`, `ring`, `orbit`, `mine`, `beam`, `homing`) and fires accordingly, applying player multipliers.
- **Spawner + WaveDirector** (`systems/`): time-driven weighted spawning per `StageData`, elite cadence, boss trigger at stage duration, difficulty scaling.
- **UpgradeManager** (`systems/`): rolls 3 weighted upgrade cards, applies picks, enforces slot/level caps, provides fallbacks.
- **VFX** (`systems/vfx.gd`): pooled particles, damage numbers, screen shake, hit sparks — all respect Settings toggles.
- **CameraRig**: smooth follow with a constant world-visible height for fairness across resolutions.

---

## 5. Data Flow (one frame)

```
_physics_process(dt):
  WaveDirector.update(dt)            # maybe spawn enemies/boss
  Player.update(dt)                  # movement (Input), regen; WeaponRunner fires
  SpatialGrid.rebuild(enemies)
  Enemies.update(dt)                 # AI via EnemyData.behavior
  Projectiles/Pickups/Fields.update(dt)
  Combat.resolve(dt)                 # grid-based collisions, damage, death → Events
  VFX.update(dt); Camera.follow(dt)
```

UI reacts to `Events` signals (HUD updates on `player_damaged`, `fragment_collected`, etc.); on `player_leveled_up` the World pauses and the UpgradeSelect overlay is shown.

---

## 6. Entities

- **Player** (`CharacterBody2D`): movement via `Input.get_vector`, health + i-frames, XP/level, shield, holds owned weapons/passives and derived stats.
- **Enemy** (`CharacterBody2D`): behavior switch (`chase`, `weave`, `ranged`, `bomber`, `boss`) from `EnemyData`; pooled; emits `enemy_killed`.
- **Projectile / Pickup / DamageNumber** (`Area2D`/`Node2D`): pooled; collisions resolved centrally via the grid.
- **Boss**: an Enemy variant driven by a phase list in `StageData` (attack timers + hp-fraction phase gating).

---

## 7. Performance

- Object pooling everywhere; caps: enemies 500, projectiles 700, pickups 1500, particles 600.
- Spatial-grid broad-phase; precise checks only on candidates.
- GL Compatibility renderer; nearest-neighbor texture filter (crisp pixel art); pixel snap.
- Adaptive quality: particle budget scales down if frame time rises.
- Fixed 60 Hz physics tick; rendering interpolated by Godot.

---

## 8. Error Handling & Robustness

- Save/load wrapped in guards; corrupt/missing profile → safe defaults.
- All data lookups tolerate missing ids (return null + warn, never crash).
- Pools return `null` at cap instead of over-allocating.
- Autoloads have no hard ordering dependencies beyond InputMap setup in `GameData`.

---

## 9. Build & Export (run on your machine)

Because Godot itself is not present in the authoring sandbox, exports are produced by you in the Godot editor. `export_presets.cfg` ships with **Web** and **Android** presets.

1. Install **Godot 4.3+** and, in the editor, **Editor → Manage Export Templates → Download**.
2. Open the project (root `project.godot`). First open auto-imports assets.
3. **Web:** Project → Export → *Web* → Export Project → serve the folder over HTTP (Godot web builds require cross-origin isolation headers; use `godot` remote debug or any static server with COOP/COEP).
4. **Android:** install the Android Build Template + SDK/JDK (Editor → Manage Export Templates + Editor Settings → Android SDK path), then Project → Export → *Android* → Export Project (debug APK) or set keystore for release.

See `README.md` for the exact commands and the CLI headless-export one-liners.

---

## 10. Development Roadmap (milestones)

- **M1 Pre-production** — GDD, this plan, folder structure, project config. ✅
- **M2 Core gameplay** — autoloads, player, combat, projectiles, spawning, waves, XP/level.
- **M3 Content** — 8 weapons, 25+ upgrades, 5 enemy types, 3 bosses, 3 stages, meta-progression + save.
- **M4 UI/UX** — menu, HUD, upgrade select, pause, settings, tutorial, results.
- **M5 Art & Audio** — dark sci-fi pixel art integration; synthesized music/SFX.
- **M6 QA & Optimization** — static review, error handling, performance; QA_REPORT.
- **M7 Release & Marketing** — export presets, README, marketing package.
