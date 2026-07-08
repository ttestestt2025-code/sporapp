class_name Spawner
extends RefCounted
## Time-driven weighted enemy spawning with elite cadence and off-screen ring placement.

var world
var stage: StageData
var spawn_acc := 0.0
var elite_t := 0.0

func setup(w, s: StageData) -> void:
	world = w
	stage = s
	spawn_acc = 0.0
	elite_t = s.elite_every

func update(dt: float, stage_time: float) -> void:
	var diff: Dictionary = GameData.DIFFICULTY[world.mode]
	var rate: float = (stage.base_rate + stage_time * stage.rate_grow) * float(diff.spawn)
	if world.mode == "endless":
		rate *= 1.0 + world.total_time * 0.01
	if world.boss != null:
		rate *= 0.35
	spawn_acc += rate * dt
	var guard := 0
	while spawn_acc >= 1.0 and guard < 40:
		spawn_acc -= 1.0
		guard += 1
		if world.enemies.count() >= world.ENEMY_CAP - 6:
			break
		var id := _pick(stage_time)
		if id != "":
			world.spawn_enemy(id, _ring_pos())
	if world.boss == null:
		elite_t -= dt
		if elite_t <= 0.0:
			elite_t = stage.elite_every
			if world.enemies.count() < world.ENEMY_CAP - 2:
				world.spawn_enemy(stage.elite_id, _ring_pos())

func _pick(t: float) -> String:
	var pool: Array = []
	for s in stage.spawns:
		if t >= s.s and t <= s.e:
			pool.append(s)
	if pool.is_empty():
		return stage.spawns[0].enemy
	return Util.weighted_pick(pool, func(s): return float(s.w)).enemy

func _ring_pos() -> Vector2:
	var rad: float = max(world.view_size.x, world.view_size.y) * 0.5 + randf_range(40, 120)
	var a := randf() * TAU
	var pos: Vector2 = world.player.position + Vector2(cos(a), sin(a)) * rad
	return pos.clamp(world.bounds_min, world.bounds_max)
