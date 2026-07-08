extends Node
## Headless runtime smoke test (dev-only; removed from the shipped build).
## Spins up a real World, loads a full build, spawns enemies, triggers a boss + level-up,
## and drives the run to catch runtime errors. Run via the AutoTest scene headless.

var world
var t := 0.0
var phase := 0

func _ready() -> void:
	print("[autotest] boot")
	SaveSystem.data.seen_tutorial = true
	world = World.new()
	world.setup("normal", "keeper", 0)
	add_child(world)
	print("[autotest] world created; player hp=", world.player.hp, " max=", world.player.max_hp)

func _process(delta: float) -> void:
	t += delta
	match phase:
		0:
			if t > 0.6:
				phase = 1
				for id in GameData.weapon_ids:
					world.player.weapons[id] = 3
					world.player.weapon_state[id] = {"cd": 0.0, "angle": 0.0, "tick": 0.0, "drones": []}
				world.player.compute_stats(false)
				print("[autotest] full build loaded; weapons=", world.player.weapons.size())
		1:
			if t > 3.0:
				phase = 2
				print("[autotest] t=3 enemies=", world.enemies.count(), " proj=", world.projectiles.count(), " kills=", world.player.kills, " hp=", int(world.player.hp), " quality=", world.quality)
				world.stage_time = world.stage.duration
		2:
			if t > 5.0:
				phase = 3
				print("[autotest] boss_active=", world.boss != null, " pulses=", world.pulses.size(), " mines=", world.mines.size())
				world.player.pending_levels = 3
		3:
			if t > 6.0:
				phase = 4
				print("[autotest] leveling=", world.leveling, " cards=", world.upgrade_ui._cards.size())
				if world.leveling and world.upgrade_ui._cards.size() > 0:
					world.on_upgrade_pick(world.upgrade_ui._cards[0])
				if world.boss != null:
					world.on_boss_killed(world.boss)
		4:
			if t > 7.5:
				phase = 5
				print("[autotest] state=", world.state, " stage_index=", world.stage_index, " scrap=", world.run_scrap)
				# exercise death path
				world.player.hurt(999999.0)
				print("[autotest] after lethal hit: player.dead=", world.player.dead)
		5:
			if t > 8.5:
				phase = 6
				print("[autotest] DONE OK")
				get_tree().quit()
