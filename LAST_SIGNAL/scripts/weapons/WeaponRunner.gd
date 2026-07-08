class_name WeaponRunner
extends RefCounted
## Interprets each owned WeaponData by `type` and fires it, applying the player's derived multipliers.

static func _roll(base: float, player) -> Array:
	var crit: bool = randf() < player.stats.crit_chance
	var d: float = base * player.stats.power * (player.stats.crit_dmg if crit else 1.0)
	return [d, crit]

static func update(world, player, dt: float) -> void:
	for id in player.weapons.keys():
		var w: WeaponData = GameData.weapons[id]
		var lvl: int = player.weapons[id]
		var st: Dictionary = player.weapon_state[id]
		match w.type:
			"bolt": _bolt(world, player, w, lvl, st, dt)
			"splash": _splash(world, player, w, lvl, st, dt)
			"ring": _ring(world, player, w, lvl, st, dt)
			"pulse": _pulse(world, player, w, lvl, st, dt)
			"orbit": _orbit(world, player, w, lvl, st, dt)
			"mine": _mine(world, player, w, lvl, st, dt)
			"beam": _beam(world, player, w, lvl, st, dt)
			"homing": _homing(world, player, w, lvl, st, dt)

static func _bolt(world, player, w, lvl, st, dt) -> void:
	st.cd -= dt
	if st.cd > 0.0:
		return
	var count: int = int(w.v(w.count, lvl)) + player.stats.count_add
	var pierce: int = int(w.v(w.pierce, lvl))
	var speed: float = w.speed * player.stats.proj_speed_mul
	var radius: float = w.proj_radius * sqrt(player.stats.area_mul)
	var targets: Array = world.nearest_n(player.position, count)
	for i in count:
		var ang: float
		if i < targets.size():
			ang = (targets[i].position - player.position).angle()
		elif targets.size() > 0:
			ang = (targets[0].position - player.position).angle() + randf_range(-0.4, 0.4)
		else:
			ang = randf() * TAU
		var rd := _roll(w.v(w.dmg, lvl), player)
		world.spawn_projectile(player.position, Vector2(cos(ang), sin(ang)) * speed, rd[0],
			{"pierce": pierce, "radius": radius, "color": w.color, "type": "bolt", "crit": rd[1]})
	st.cd = w.v(w.cd, lvl) * player.stats.cd_mul
	AudioManager.play_sfx("shoot")

static func _splash(world, player, w, lvl, st, dt) -> void:
	st.cd -= dt
	if st.cd > 0.0:
		return
	var count: int = int(w.v(w.count, lvl)) + player.stats.count_add
	var speed: float = w.speed * player.stats.proj_speed_mul
	var splash: float = w.ev("radius", lvl) * player.stats.area_mul
	var targets: Array = world.nearest_n(player.position, count)
	for i in count:
		var ang: float = (targets[i].position - player.position).angle() if i < targets.size() else randf() * TAU
		var rd := _roll(w.v(w.dmg, lvl), player)
		world.spawn_projectile(player.position, Vector2(cos(ang), sin(ang)) * speed, rd[0],
			{"radius": w.proj_radius, "color": w.color, "type": "bolt", "crit": rd[1], "splash": splash})
	st.cd = w.v(w.cd, lvl) * player.stats.cd_mul
	AudioManager.play_sfx("shoot")

static func _ring(world, player, w, lvl, st, dt) -> void:
	st.cd -= dt
	if st.cd > 0.0:
		return
	var r: float = w.ev("radius", lvl) * player.stats.area_mul
	var rd := _roll(w.v(w.dmg, lvl), player)
	world.damage_area(player.position, r, rd[0], {"knock": w.ev("knock", lvl), "color": w.color, "crit": rd[1]})
	world.vfx.ring(player.position, r, w.color)
	world.vfx.burst(player.position, w.color, 14, 3.0)
	st.cd = w.v(w.cd, lvl) * player.stats.cd_mul
	AudioManager.play_sfx("nova")

static func _pulse(world, player, w, lvl, st, dt) -> void:
	st.cd -= dt
	if st.cd > 0.0:
		return
	var r: float = w.ev("radius", lvl) * player.stats.area_mul
	var rd := _roll(w.v(w.dmg, lvl), player)
	world.damage_area(player.position, r, rd[0],
		{"slow": w.ev("slow", lvl), "slow_dur": w.ev("slow_dur", lvl), "knock": 60.0, "color": w.color, "crit": rd[1]})
	world.vfx.ring(player.position, r, w.color)
	st.cd = w.v(w.cd, lvl) * player.stats.cd_mul
	AudioManager.play_sfx("nova")

static func _orbit(world, player, w, lvl, st, dt) -> void:
	var drones: int = int(w.v(w.count, lvl))
	var orbit_r: float = w.ev("orbit_r", lvl) * player.stats.area_mul
	var fire_cd: float = w.ev("fire_cd", lvl) * player.stats.cd_mul
	st.angle += 2.2 * dt
	if st.drones.size() != drones:
		st.drones = []
		for i in drones:
			st.drones.append({"fire_t": randf() * fire_cd, "pos": player.position})
	for i in drones:
		var a: float = st.angle + float(i) / float(drones) * TAU
		var pos: Vector2 = player.position + Vector2(cos(a), sin(a)) * orbit_r
		st.drones[i].pos = pos
		st.drones[i].fire_t -= dt
		if st.drones[i].fire_t <= 0.0:
			var tgt = world.nearest_enemy(pos, 360.0, [])
			if tgt != null:
				var ang: float = (tgt.position - pos).angle()
				var rd := _roll(w.v(w.dmg, lvl), player)
				world.spawn_projectile(pos, Vector2(cos(ang), sin(ang)) * w.speed * player.stats.proj_speed_mul, rd[0],
					{"radius": w.proj_radius, "color": GameData.COL.cyan, "type": "bolt", "crit": rd[1], "life": 1.2})
				st.drones[i].fire_t = fire_cd
			else:
				st.drones[i].fire_t = 0.2

static func _mine(world, player, w, lvl, st, dt) -> void:
	st.cd -= dt
	if st.cd > 0.0:
		return
	var mines: int = int(w.v(w.count, lvl))
	var r: float = w.ev("radius", lvl) * player.stats.area_mul
	for i in mines:
		var off := Vector2(randf_range(-40, 40), randf_range(-40, 40))
		var rd := _roll(w.v(w.dmg, lvl), player)
		world.spawn_mine(player.position + off, r, rd[0], rd[1])
	st.cd = w.v(w.cd, lvl) * player.stats.cd_mul

static func _beam(world, player, w, lvl, st, dt) -> void:
	st.angle += w.ev("sweep", lvl) * dt
	st.tick -= dt
	if st.tick > 0.0:
		return
	st.tick = w.ev("tick", lvl)
	var length: float = w.ev("length", lvl) * player.stats.area_mul
	var width: float = w.ev("width", lvl)
	var dir := Vector2(cos(st.angle), sin(st.angle))
	var rd := _roll(w.v(w.dmg, lvl), player)
	world.damage_beam(player.position, dir, length, width, rd[0], w.color, rd[1])

static func _homing(world, player, w, lvl, st, dt) -> void:
	st.cd -= dt
	if st.cd > 0.0:
		return
	var count: int = int(w.v(w.count, lvl)) + player.stats.count_add
	var pierce: int = int(w.v(w.pierce, lvl))
	var speed: float = w.speed * player.stats.proj_speed_mul
	var turn: float = w.ev("turn", lvl)
	for i in count:
		var a := randf() * TAU
		var rd := _roll(w.v(w.dmg, lvl), player)
		world.spawn_projectile(player.position, Vector2(cos(a), sin(a)) * speed, rd[0],
			{"pierce": pierce, "radius": w.proj_radius, "color": w.color, "type": "homing", "turn": turn, "crit": rd[1], "life": 3.0})
	st.cd = w.v(w.cd, lvl) * player.stats.cd_mul
	AudioManager.play_sfx("shoot")
