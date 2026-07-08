extends Node
## Global signal bus. Systems communicate through these signals instead of hard references.

signal enemy_killed(enemy)
signal fragment_collected(value)
signal scrap_gained(amount)
signal player_damaged(current_hp, max_hp)
signal player_healed(amount)
signal player_leveled_up(new_level)
signal player_stats_changed()
signal player_died()
signal boss_spawned(boss)
signal boss_killed(boss)
signal stage_changed(stage_index, stage_name)
signal run_started()
signal run_ended(win, results)
signal upgrade_offered(cards)
signal upgrade_selected(card)
signal weapon_changed(id, level)
signal settings_changed()
signal request_scene(state, data)   ## high-level state switch: "menu", "game", "station", "gameover", "victory"
