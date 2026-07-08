# Audio

All music and sound effects in LAST SIGNAL are **original and procedurally synthesized** — there are no external samples.

The `.wav` files are treated as generated assets (git-ignored). Reproduce the full soundtrack and SFX at any time:

```bash
python3 tools/generate_audio.py    # requires numpy
```

This writes:
- `audio/music/` — `menu`, `stage1`, `stage2`, `stage3`, `boss`, `victory` (looping)
- `audio/sfx/` — 14 effects (shoot, hit, enemy_die, player_hurt, pickup, scrap, level_up, cache, nova, boss_hit, boss_die, ui_click, game_over, victory)

The CI workflow regenerates these automatically before the Web export. The game runs fine without them (it simply plays silent).
