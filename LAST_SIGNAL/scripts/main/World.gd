class_name World
extends Node2D
## Gameplay orchestrator: owns pools, systems, stage flow, combat resolution, and run lifecycle.

const ENEMY_CAP := 500
const PROJ_CAP := 700
const PICKUP_CAP := 1500
const VIEW_H := 620.0
const WORLD_SIZE := 6000.0

var mode := "normal"
var character := "keeper"
var stage_index := 0
var stage: StageData
var player: Player
var vfx: VFX
var grid := SpatialGrid.new(72)
var spawner := Spawner.new()

var enemies: Pool
var projectiles: Pool
var pickups: Pool
var mines: Array = []
var pulses: Array = []

var camera: Camera2D
var enemies_layer: Node2D
var proj_layer: Node2D
var pickup_layer: Node2D

var boss = null
var boss_spawned := false
var state := "playing"       # playing | cleared | dead | won
var clear_t := 0.0
var advance_pending := false
var leveling := false
var paused := false
var stage_time := 0.0
var total_time := 0.0
var run_scrap := 0.0
var frame := 0
var quality := "high"
var view_size := Vector2(1280, 720)
var bounds_min := Vector2.ZERO
var bounds_max := Vector2.ZERO
var touch_move := Vector2.ZERO
var _in_volatile := false
var _touch_id := -1
var _touch_origin := Vector2.ZERO

var hud
var upgrade_ui
var pause_ui
var _fps_accum := 0.0
var _fps_frames := 0

func setup(p_mode: String, p_char: String, p_stage: int) -> void:
	mode = p_mode
	character = p_char
	stage_index = p_stage
	stage = GameData.stages[stage_index]

func _ready() -> void:
	quality = "high"
	if SaveSystem.settings.get("quality", "auto") == "low":
		quality = "low"
	var half := WORLD_SIZE * 0.5 - 40.0
	bounds_min = Vector2(-half, -half)
	bounds_max = Vector2(half, half)

	enemies_layer = Node2D.new(); add_child(enemies_layer)
	proj_layer = Node2D.new(); add_child(proj_layer)
	pickup_layer = Node2D.new(); pickup_layer.z_index = -1; add_child(pickup_layer)

	vfx = VFX.new(); vfx.world = self; add_child(vfx)

	var make_enemy := func():
		var e := Enemy.new()
		enemies_layer.add_child(e)
		return e
	var make_proj := func():
		var pr := Projectile.new()
		proj_layer.add_child(pr)
		return pr
	var make_pickup := func():
		var pk := Pickup.new()
		pickup_layer.add_child(pk)
		return pk
	enemies = Pool.new(make_enemy, ENEMY_CAP)
	projectiles = Pool.new(make_proj, PROJ_CAP)
	pickups = Pool.new(make_pickup, PICKUP_CAP)

	player = Player.new()
	player.setup(self, character)
	player.z_index = 10
	add_child(player)

	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	_update_view()
	get_viewport().size_changed.connect(_update_view)
	camera.position = player.position

	spawner.setup(self, stage)

	# UI overlays (built in code)
	hud = HUD.new(); add_child(hud); hud.setup(self)
	upgrade_ui = UpgradeSelect.new(); add_child(upgrade_ui); upgrade_ui.setup(self); upgrade_ui.hide()
	pause_ui = PauseMenu.new(); add_child(pause_ui); pause_ui.setup(self); pause_ui.hide()

	if not SaveSystem.data.get("seen_tutorial", false) and stage_index == 0 and mode != "endless":
		var tut := Tutorial.new(); add_child(tut); tut.setup(self)

	if stage_index == 0 and mode != "endless":
		SaveSystem.data.stats.runs = int(SaveSystem.data.stats.runs) + 1
		SaveSystem.save_game()
	Events.run_started.emit()
	Events.stage_changed.emit(stage_index, stage.display_name)
	AudioManager.play_music(stage.music)

func _update_view() -> void:
	var vp := get_viewport_rect().size
	var z: float = vp.y / VIEW_H
	if vp.x / z < 760.0:
		z = vp.x / 760.0
	camera.zoom = Vector2(z, z)
	view_size = vp / z

func hp_mult() -> float:
	var diff: Dictionary = GameData.DIFFICULTY[mode]
	var m: float = 1.0 + stage_time * 0.010 + stage_index * 0.6
	if mode == "endless":
		m += total_time * 0.02
	return m * float(diff.hp)

func get_move_input() -> Vector2:
	if touch_move != Vector2.ZERO:
		return touch_move
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

# ---------------- spawners ----------------
func spawn_enemy(id: String, pos: Vector2):
	if not GameData.enemies.has(id):
		return null
	var e = enemies.obtain()
	if e == null:
		return null
	e.reset(GameData.enemies[id], pos, hp_mult())
	return e

func spawn_boss() -> void:
	boss_spawned = true
	var bd: Dictionary = stage.boss
	var diff: Dictionary = GameData.DIFFICULTY[mode]
	var a := randf() * TAU
	var e = enemies.obtain()
	if e == null:
		return
	var ed := EnemyData.new()  # placeholder data holder for xp field
	ed.xp = 0
	e.reset(ed, player.position + Vector2(cos(a), sin(a)) * 300.0, float(diff.hp), {"boss": true, "boss_def": bd})
	boss = e
	AudioManager.play_music("boss")
	hud.set_banner(bd.name + " detected")
	vfx.shake(8.0)
	Events.boss_spawned.emit(e)

func spawn_projectile(pos: Vector2, vel: Vector2, dmg: float, opts := {}) -> void:
	var pr = projectiles.obtain()
	if pr != null:
		pr.reset(pos, vel, dmg, opts)

func spawn_enemy_projectile(pos: Vector2, angle: float, speed: float, dmg: float) -> void:
	var pr = projectiles.obtain()
	if pr != null:
		pr.reset(pos, Vector2(cos(angle), sin(angle)) * speed, dmg,
			{"hostile": true, "type": "hostile", "color": GameData.COL.pink, "radius": 7.0, "life": 5.0, "trail": false})

func spawn_pickup(pos: Vector2, kind: String, value: float, color: Color, big := false) -> void:
	var pk = pickups.obtain()
	if pk != null:
		pk.reset(pos, kind, value, color)
		pk.big = big

func spawn_mine(pos: Vector2, radius: float, dmg: float, crit := false) -> void:
	mines.append({"pos": pos, "radius": radius, "dmg": dmg, "arm": 0.4, "life": 12.0, "crit": crit})

func spawn_pulse(pos: Vector2, radius: float, dmg: float, telegraph: float, color: Color) -> void:
	pulses.append({"pos": pos, "radius": radius, "dmg": dmg, "t": telegraph, "tele": telegraph, "color": color})

func damage_player_aoe(pos: Vector2, radius: float, dmg: float) -> void:
	if player.position.distance_to(pos) < radius + player.radius:
		player.hurt(dmg)

# ---------------- queries ----------------
func nearest_enemy(pos: Vector2, maxd: float, exclude: Array):
	var best = null
	var bd := maxd * maxd
	for e in enemies.active:
		if e.dead or (exclude.size() > 0 and exclude.has(e)):
			continue
		var d := pos.distance_squared_to(e.position)
		if d < bd:
			bd = d
			best = e
	return best

func nearest_n(pos: Vector2, n: int) -> Array:
	var arr: Array = []
	for e in enemies.active:
		if not e.dead:
			arr.append(e)
	arr.sort_custom(func(a, b): return pos.distance_squared_to(a.position) < pos.distance_squared_to(b.position))
	if arr.size() > n:
		arr.resize(n)
	return arr

# ---------------- damage helpers ----------------
func _hit_enemy(e, dmg: float, at: Vector2, color: Color, crit: bool, silent := false) -> void:
	vfx.spark(at, color, 3, 0.2, 2.0, true)
	vfx.dmg_num(at, dmg, color, crit)
	if not silent:
		AudioManager.play_sfx("boss_hit" if e.is_boss else "hit")

func damage_area(pos: Vector2, radius: float, dmg: float, opts := {}) -> int:
	var hits := 0
	for e in grid.query_circle(pos.x, pos.y, radius):
		if e.dead:
			continue
		var rr: float = radius + e.radius
		if pos.distance_squared_to(e.position) < rr * rr:
			var kb := Vector2.ZERO
			if opts.has("knock"):
				kb = (e.position - pos).normalized() * float(opts.knock)
			e.apply_damage(dmg, self, kb, opts.get("crit", false))
			if opts.has("slow"):
				e.slow(1.0 - float(opts.slow), float(opts.get("slow_dur", 1.0)))
			_hit_enemy(e, dmg, e.position, opts.get("color", Color.WHITE), opts.get("crit", false), opts.get("no_num", false))
			hits += 1
	return hits

func damage_beam(origin: Vector2, dir: Vector2, length: float, width: float, dmg: float, color: Color, crit: bool) -> void:
	var half_w := width * 0.5
	for e in enemies.active:
		if e.dead:
			continue
		var rel = e.position - origin
		var t: float = clampf(rel.dot(dir), 0.0, length)
		var closest := origin + dir * t
		if closest.distance_squared_to(e.position) < (half_w + e.radius) * (half_w + e.radius):
			e.apply_damage(dmg, self, dir * 40.0, crit)
			_hit_enemy(e, dmg, e.position, color, crit, true)

# ---------------- events ----------------
func on_enemy_killed(e) -> void:
	player.kills += 1
	var col: Color = GameData.COL.hp if e.xp >= 25 else (GameData.COL.cyan if e.xp >= 5 else GameData.COL.green)
	spawn_pickup(e.position, "fragment", e.xp, col)
	if randf() < 0.06:
		spawn_pickup(e.position, "scrap", randi_range(3, 9), GameData.COL.scrap)
	if randf() < 0.012:
		spawn_pickup(e.position, "heal", 20, GameData.COL.green)
	if e.elite:
		spawn_pickup(e.position, "cache", 0, GameData.COL.cyan)
	vfx.burst(e.position, e.color, 18 if e.elite else 8, 4.0 if e.elite else 2.0)
	AudioManager.play_sfx("enemy_die")
	Events.enemy_killed.emit(e)
	if player.has_volatile and not _in_volatile:
		_in_volatile = true
		damage_area(e.position, 46.0, 10.0 + player.level * 1.5, {"color": GameData.COL.orange, "no_num": true})
		vfx.burst(e.position, GameData.COL.orange, 8, 2.0)
		_in_volatile = false

func on_boss_killed(e) -> void:
	AudioManager.play_sfx("boss_die")
	vfx.shake(12.0); vfx.burst(e.position, e.color, 50, 6.0); vfx.ring(e.position, 130.0, e.color)
	SaveSystem.data.stats.boss_kills = int(SaveSystem.data.stats.boss_kills) + 1
	run_scrap += 150 * (stage_index + 1)
	boss = null
	_clear_all_enemies()
	spawn_pickup(e.position, "cache", 0, GameData.COL.cyan, true)
	Events.boss_killed.emit(e)
	if mode == "endless":
		boss_spawned = false
		stage_time = 0.0
		hud.set_banner("The horde regathers")
		return
	if stage_index < GameData.stages.size() - 1:
		state = "cleared"
		clear_t = 0.0
		hud.set_banner("SECTOR CLEARED")
	else:
		end_run(true)

func collect_pickup(pk) -> void:
	match pk.type:
		"fragment":
			player.gain_xp(pk.value)
			AudioManager.play_sfx("pickup")
		"scrap":
			run_scrap += round(pk.value * player.stats.scrap_mul)
			AudioManager.play_sfx("scrap")
		"heal":
			player.heal(pk.value)
			vfx.dmg_num(player.position + Vector2(0, -12), pk.value, GameData.COL.green)
			AudioManager.play_sfx("scrap")
		"cache":
			AudioManager.play_sfx("cache")
			player.pending_levels += (2 if pk.big else randi_range(1, 2))
			run_scrap += (200 if pk.big else 60)
			vfx.burst(pk.position, GameData.COL.cyan, 24, 4.0)
			if pk.big and state == "cleared":
				advance_pending = true

func _clear_all_enemies() -> void:
	for e in enemies.active:
		e.active = false
		e.dead = true
		e.visible = false

# ---------------- run flow ----------------
func advance_stage() -> void:
	stage_index += 1
	stage = GameData.stages[stage_index]
	stage_time = 0.0
	boss_spawned = false
	boss = null
	state = "playing"
	advance_pending = false
	clear_t = 0.0
	_clear_all_enemies()
	projectiles.clear_all()
	mines.clear(); pulses.clear()
	spawner.setup(self, stage)
	player.heal(player.max_hp * 0.25)
	AudioManager.play_music(stage.music)
	hud.set_banner(stage.display_name)
	Events.stage_changed.emit(stage_index, stage.display_name)

func end_run(win: bool) -> void:
	if state == "dead" or state == "won":
		return
	state = "won" if win else "dead"
	var bonus := int(total_time * 0.8 * player.stats.scrap_mul)
	var scrap := int(run_scrap) + bonus
	SaveSystem.add_scrap(scrap)
	var st: Dictionary = SaveSystem.data.stats
	st.kills = int(st.kills) + player.kills
	st.playtime = float(st.playtime) + total_time
	if total_time > float(st.best_time):
		st.best_time = total_time
	if win:
		st.victories = int(st.victories) + 1
		SaveSystem.data.unlocks.scavenger = true
	SaveSystem.save_game()
	AudioManager.stop_music()
	AudioManager.play_sfx("victory" if win else "game_over")
	var results := {
		"win": win, "time": total_time, "kills": player.kills, "level": player.level,
		"scrap": scrap, "total_scrap": SaveSystem.data.scrap, "stage": stage_index + 1,
		"mode": mode, "character": character,
	}
	Events.run_ended.emit(win, results)

func quit_run() -> void:
	var bonus := int(total_time * 0.8 * player.stats.scrap_mul)
	SaveSystem.add_scrap(int(run_scrap) + bonus)
	var st: Dictionary = SaveSystem.data.stats
	st.kills = int(st.kills) + player.kills
	st.playtime = float(st.playtime) + total_time
	SaveSystem.save_game()
	AudioManager.stop_music()
	Events.request_scene.emit("menu")

func toggle_pause() -> void:
	paused = not paused
	if paused:
		pause_ui.show()
	else:
		pause_ui.hide()
	AudioManager.play_sfx("ui_click")

func open_upgrade() -> void:
	leveling = true
	upgrade_ui.present(UpgradeManager.offers(self, player, 3))
	AudioManager.play_sfx("level_up")

func on_upgrade_pick(card: Dictionary) -> void:
	UpgradeManager.apply(card, self, player)
	player.pending_levels -= 1
	AudioManager.play_sfx("ui_click")
	if player.pending_levels > 0:
		upgrade_ui.present(UpgradeManager.offers(self, player, 3))
	else:
		leveling = false
		upgrade_ui.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and state in ["playing", "cleared"] and not leveling:
		toggle_pause()
		return
	# Touch virtual joystick (mobile)
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_touch_origin = event.position
			touch_move = Vector2.ZERO
			hud.set_joystick(true, _touch_origin, _touch_origin)
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			touch_move = Vector2.ZERO
			hud.set_joystick(false, Vector2.ZERO, Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == _touch_id:
		var d: Vector2 = event.position - _touch_origin
		var clamped: Vector2 = d.limit_length(66.0)
		var mag: float = clamped.length() / 66.0
		var dead := 0.18
		touch_move = Vector2.ZERO if mag < dead else d.normalized() * ((mag - dead) / (1.0 - dead))
		hud.set_joystick(true, _touch_origin, _touch_origin + clamped)

# ---------------- main loop ----------------
func _physics_process(dt: float) -> void:
	frame += 1
	# adaptive quality
	_fps_accum += dt; _fps_frames += 1
	if _fps_accum >= 0.5:
		var fps := _fps_frames / _fps_accum
		if SaveSystem.settings.get("quality", "auto") == "auto":
			quality = "low" if fps < 45.0 else "high"
		_fps_accum = 0.0; _fps_frames = 0

	if state == "dead" or state == "won" or paused or leveling:
		return

	total_time += dt
	if state == "playing":
		stage_time += dt
		spawner.update(dt, stage_time)

	# rebuild grid
	grid.clear()
	for e in enemies.active:
		if not e.dead:
			grid.insert(e)

	player.tick(dt)
	for e in enemies.active:
		e.tick(dt, self)
	for pr in projectiles.active:
		pr.tick(dt, self)
	for pk in pickups.active:
		pk.tick(dt, self)
	_update_mines(dt)
	_update_pulses(dt)
	_resolve_combat()
	vfx.tick(dt)

	enemies.sweep(); projectiles.sweep(); pickups.sweep()

	# camera follow + shake
	camera.position = camera.position.lerp(player.position, 1.0 - pow(0.0015, dt)) + vfx.offset

	if not boss_spawned and state == "playing" and stage_time >= stage.duration:
		spawn_boss()
	if state == "cleared":
		clear_t += dt
		if (advance_pending and player.pending_levels == 0) or clear_t > 12.0:
			advance_stage()
	if player.pending_levels > 0 and not leveling:
		open_upgrade()

	hud.refresh()

func _update_mines(dt: float) -> void:
	for i in range(mines.size() - 1, -1, -1):
		var m: Dictionary = mines[i]
		m.life -= dt
		if m.arm > 0.0:
			m.arm -= dt
		else:
			var hit := false
			for e in grid.query_circle(m.pos.x, m.pos.y, m.radius):
				if not e.dead and m.pos.distance_to(e.position) < m.radius:
					hit = true
					break
			if hit or m.life <= 0.0:
				damage_area(m.pos, m.radius, m.dmg, {"knock": 120.0, "color": GameData.COL.red, "crit": m.crit})
				vfx.ring(m.pos, m.radius, GameData.COL.red)
				vfx.burst(m.pos, GameData.COL.orange, 18, 4.0)
				vfx.shake(3.0)
				AudioManager.play_sfx("nova")
				mines.remove_at(i)
				continue
		if m.life <= 0.0:
			mines.remove_at(i)

func _update_pulses(dt: float) -> void:
	for i in range(pulses.size() - 1, -1, -1):
		var p: Dictionary = pulses[i]
		p.t -= dt
		if p.t <= 0.0:
			damage_player_aoe(p.pos, p.radius, p.dmg)
			vfx.ring(p.pos, p.radius, p.color)
			vfx.shake(6.0)
			pulses.remove_at(i)

func _resolve_combat() -> void:
	var pl := player
	for pr in projectiles.active:
		if not pr.active or pr.hostile:
			continue
		for e in grid.query_circle(pr.position.x, pr.position.y, pr.radius + 34.0):
			if e.dead:
				continue
			var rr: float = pr.radius + e.radius
			if pr.position.distance_squared_to(e.position) < rr * rr:
				if pr.hit_list.has(e):
					continue
				var kb = pr.vel.normalized() * 130.0
				e.apply_damage(pr.dmg, self, kb, pr.is_crit)
				_hit_enemy(e, pr.dmg, pr.position, pr.color, pr.is_crit)
				if pr.splash > 0.0:
					damage_area(pr.position, pr.splash, pr.dmg * 0.6, {"color": pr.color, "no_num": true})
				if pr.pierce > 0:
					pr.pierce -= 1
					pr.hit_list.append(e)
				else:
					pr.active = false
					break
	for pr in projectiles.active:
		if not pr.active or not pr.hostile:
			continue
		var rr: float = pr.radius + pl.radius
		if pr.position.distance_squared_to(pl.position) < rr * rr:
			pl.hurt(pr.dmg)
			pr.active = false
	for e in grid.query_circle(pl.position.x, pl.position.y, 70.0):
		if e.dead:
			continue
		var rr: float = e.radius + pl.radius
		if e.position.distance_squared_to(pl.position) < rr * rr:
			if e.behavior == "bomber":
				e.die(self)
			elif e.contact_cd <= 0.0:
				pl.hurt(e.dmg)
				e.contact_cd = 0.5
