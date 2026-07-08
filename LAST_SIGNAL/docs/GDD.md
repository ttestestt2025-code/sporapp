# LAST SIGNAL — Game Design Document

**Version:** 1.0
**Engine:** Godot 4.3+
**Genre:** 2D Arcade Survivor / Bullet-Heaven / Roguelite
**Session length:** ~15 min for a full 3-stage clear
**Perspective:** Top-down 2D

---

## 1. High Concept

The world has gone dark. An unknown catastrophe shattered civilization and twisted its survivors into **the Corrupted**. One relay still stands: humanity's **Last Signal** station. You are **The Signal Keeper** — the last operator — and you must hold the perimeter against endless waves of corrupted creatures long enough to **restore the final transmission** that might bring humanity back from the edge.

**Fantasy:** one operator, one failing station, an ocean of monsters — and you become a walking weapons platform.

### Design Pillars
1. **Auto-combat, manual movement** — the player reads the battlefield and repositions; weapons fire themselves.
2. **Build a machine of war** — every level-up forks your run; no two loadouts feel alike.
3. **Readable chaos** — hundreds of enemies, but the threat is always legible (neon-on-dark, high contrast).
4. **Respect the player** — short runs, instant restart, permanent meta-progress, 60 FPS on low-end hardware.

---

## 2. Core Loop

```
Enter zone → auto-attack the Corrupted → collect Energy Fragments → level up
     ↑                                                                │
     │                                                                ▼
Stronger build ← pick 1 of 3 upgrades ← LEVEL UP ─────────────────────┘
     │
     ▼
Survive 5:00 → Stage Boss → next stage (×3) → Signal restored (Victory)
     │
     ▼ (death or victory)
Spend Scrap at the Station (meta-shop) → unlock upgrades / weapons / characters → stronger run
```

---

## 3. The Signal Keeper (Player)

Base stats:

| Stat | Base | Notes |
|---|---|---|
| Max HP | 100 | Death at 0 |
| Move speed | 150 px/s | |
| Power (damage mult) | 1.00 | Global |
| Cooldown mult | 1.00 | Lower = faster |
| Area mult | 1.00 | |
| Projectile speed mult | 1.00 | |
| Pickup radius | 42 px | |
| Armor | 0 | Flat reduction/hit |
| Crit chance | 5% | |
| Crit damage | ×1.5 | |
| HP regen | 0/s | |
| Luck | 1.00 | Rarity rolls |
| Fragment gain (XP) | 1.00 | |
| Scrap gain (meta) | 1.00 | |

**Core kit (starting abilities):**
- **Energy Rifle** — the starting weapon; auto-fires bolts at the nearest enemy.
- **Pulse Wave** — a periodic defensive shockwave that damages and knocks back nearby enemies (unlockable/starting utility).
- **Defensive Shield** — a rechargeable shield that absorbs one hit every N seconds (via the Reactive Shield line / Signal Keeper passive).

**I-frames:** 0.5 s after taking damage.

**Second character (meta-unlock): The Scavenger** — starts with the Energy Mine, +10% Scrap, -10% Max HP. A glass-cannon economy build.

---

## 4. Weapons

Auto-firing. Max **6 weapon slots**. 8 levels each. Values scale level 1 → 8.

| Weapon | Behavior | Target | Base DMG | Base CD | Scaling |
|---|---|---|---|---|---|
| **Energy Rifle** (start) | Fires a bolt | Nearest | 10→46 | 0.85s | +proj at L3/L6, +pierce |
| **Plasma Rifle** | Heavy plasma slug, splash on hit | Nearest | 16→60 | 1.2s | +splash radius, +proj |
| **Shock Wave** | Expanding ring from the player | Self AoE | 14→58 | 2.1s | +radius, +knockback |
| **Pulse Wave** | Rhythmic close burst + slow | Self AoE | 12→48 | 1.8s | +radius, +slow |
| **Drone Companion** | Orbiting drone auto-fires at foes | Orbit/auto | 8→30 | fire 0.6s | +drones, +fire rate |
| **Energy Mine** | Drops proximity mines that detonate | Placed | 30→120 | 1.7s | +mines, +radius |
| **Laser Beam** | Sweeping continuous beam, pierces | Rotating/aim | 6→26 /tick | beam | +width, +length, +tick |
| **Nano Swarm** | Homing nanite shards | Homing | 7→28 | 1.1s | +shards, +turn rate |

*(Nano Swarm is an 8th weapon to widen build variety; the five spec weapons — Plasma Rifle, Shock Wave, Drone Companion, Energy Mine, Laser Beam — are all present with distinct behavior and upgrade levels.)*

**Visual effects:** each weapon has a distinct neon palette, muzzle flash, impact spark, and screen-shake weight. VFX are code-driven (GPUParticles2D / custom draw) for performance and zero external asset dependencies.

---

## 5. Upgrades (≥ 25)

On level-up, the player is offered **3 random cards** (weighted by rarity × Luck). Cards are: a **new weapon**, a **+level to an owned weapon**, or a **passive** (max 5 each). If the build is full/maxed, cards fall back to **Repair** (heal) or **Scrap Cache** (currency).

**Weapons as upgrades (8):** Energy Rifle, Plasma Rifle, Shock Wave, Pulse Wave, Drone Companion, Energy Mine, Laser Beam, Nano Swarm.

**Passive upgrades (17):**

| # | Passive | Effect / level |
|---|---|---|
| 1 | Overclock | -6% cooldowns |
| 2 | Power Cell | +8% damage |
| 3 | Servo Legs | +8% move speed |
| 4 | Targeting AI | +4% crit chance |
| 5 | Hollow Points | +15% crit damage |
| 6 | Nanoweave | +12% max HP |
| 7 | Repair Nanites | +0.4 HP/s |
| 8 | Capacitor | +1 projectile (multi-proj weapons), L-scaled |
| 9 | Magnetic Coil | +30% pickup radius |
| 10 | Amplifier | +10% area |
| 11 | Railgun Coils | +12% projectile speed |
| 12 | Salvager | +15% fragment (XP) gain |
| 13 | Scrap Magnet | +15% Scrap gain |
| 14 | Reinforced Plating | +1 armor |
| 15 | Kinetic Dampener | +6% damage reduction |
| 16 | Reactive Shield | +1 shield charge / faster recharge |
| 17 | Volatile Rounds | kills trigger a small plasma burst |

**Total distinct upgrades: 8 + 17 = 25** (plus the two fallback cards = 27 acquirable effects).

---

## 6. Progression: Fragments & Leveling

- Enemies drop **Energy Fragments**: minor (1), charged (5), core (25) — distinct shapes + colors (colorblind-safe).
- XP to next level: `cost(n) = round(5 + n*10 + n^1.55)`.
- Level-up → pause → 3 upgrade cards → resume.
- **Data Caches** (from elites): grant 1–3 random weapon/passive levels instantly.

---

## 7. Enemies

Enemy HP & spawn rate scale with time and stage: `hp_mult = 1 + t*0.010 + stage_index*0.6` (× difficulty).

| Enemy | Role | HP | Speed | Dmg | Behavior |
|---|---|---|---|---|---|
| **Corrupted Walker** | Fodder melee | 12 | 46 | 6 | Walks toward the Keeper |
| **Shadow Crawler** | Fast swarm | 8 | 96 | 5 | Fast, weaving, comes in packs |
| **Mutated Brute** | Tank | 70 | 34 | 14 | Slow, high HP; elite drops Data Cache |
| **Sparker** (support) | Ranged | 18 | 42 | 8 | Stops to fire energy bolts |
| **Ruptor** (kamikaze) | Bomber | 20 | 72 | 20 | Explodes on contact/death |

*(Sparker and Ruptor widen the roster beyond the three spec enemies to make stages feel alive; all three spec enemies — Corrupted Walker, Shadow Crawler, Mutated Brute — are core.)*

---

## 8. Bosses

A boss ends each stage at **5:00**. Telegraphed attacks, dedicated music, greater Data Cache on death.

1. **Corrupted Colossus** (Stage 1) — HP 2,600. Charges, ground slam shockwaves, spawns Walkers.
2. **Facility Warden** (Stage 2) — HP 4,600. Radial energy volleys, dash, deployable turrets (Sparkers), enrages < 30%.
3. **The Signal Devourer** (Stage 3, final) — HP 9,000. Three phases: (1) bullet fans + summons, (2) rotating laser sweeps + Ruptor waves, (3) arena-wide EMP pulses + desperation swarm. Killing it **restores the Last Signal** → Victory.

---

## 9. Stages

| Stage | Zone | Duration | Palette | Hazard / feel |
|---|---|---|---|---|
| 1 | **Abandoned City** | 5:00 | Cold slate blue, sodium-orange embers | Onboarding; drifting smoke |
| 2 | **Destroyed Research Facility** | 5:00 | Sickly green, containment red | Coolant leaks; denser spawns |
| 3 | **Corrupted Communication Tower** | 5:00 | Void violet, signal cyan | EMP surges; heaviest pressure |

Full clear = survive + defeat all three bosses (~15 min). **Endless** unlocks after victory.

---

## 10. Meta-Progression (The Station)

- **In-run currency:** none spent in-run.
- **Persistent currency:** **Scrap** = fragments-converted + kill bonus + `minutes*50` + boss bounties, × Scrap gain.

**Station upgrades (permanent):** Power (+dmg), Vitality (+HP), Servos (+move), Plating (+armor), Fortune (+luck), Avarice (+scrap), Insight (+XP), Recovery (+regen), Reboot (+auto-revive), Magnetics (+pickup).

**Unlocks:** The Scavenger character; alternate starting weapon; higher starting level.

**Save system:** JSON profile in `user://` — Scrap, station upgrade levels, unlocks, stats, settings.

---

## 11. Difficulty

- Minute 0–2: teach movement + first level-ups; sparse enemies.
- Minute 2–4: density climbs; first elite + Data Cache; build comes online.
- Minute 5: stage boss.
- Stages 2–3: +0.6 base HP mult each, faster spawns, deadlier archetypes, hazards.
- **Modes:** Normal, Hard (+40% enemy HP/dmg, +25% Scrap), Endless (infinite scaling).
- Anti-frustration: i-frames, optional auto-revive, generous late magnet, banked Scrap never lost.

---

## 12. Win / Lose

- **Lose:** HP 0 with no revive → Results (time, kills, level, Scrap earned).
- **Win:** defeat the Signal Devourer → "Signal Restored" → Endless unlocked.

---

## 13. UI

- **Main Menu:** Start Game, Station (upgrades), Settings, Quit.
- **HUD:** health bar, XP bar, weapon/passive display, run timer, score, Scrap, kills, boss bar.
- **Upgrade Selection:** 3 random cards (rarity-colored), keyboard 1–3 / click / tap.
- **Pause, Settings** (volume, screen shake, damage numbers, quality, difficulty), **Tutorial** (first-run overlay), **Game Over / Victory**.

---

## 14. Accessibility & UX
- Colorblind-safe fragment shapes; toggles for screen shake, damage numbers, flashes.
- One-hand mobile play (virtual joystick; all combat automatic).
- UI scaling, master/music/SFX sliders, pause anytime, difficulty modes.

---

## 15. Technical Targets
- 60 FPS with 300+ entities on low-end hardware (GL Compatibility renderer, object pooling, spatial partition for queries).
- Data-driven content (Resources) for weapons/upgrades/enemies/stages — easy to expand.
- Clean, modular, signal-decoupled architecture (see `TECHNICAL_PLAN.md`).

---

*All balance numbers here are mirrored in `scripts/data/*` and the `GameData` autoload — the code is the source of truth at runtime, this GDD is the design intent.*
