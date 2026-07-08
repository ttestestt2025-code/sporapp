class_name Enemy
extends Node2D
## Pooled enemy with data-driven behavior. Bosses use a phase list from StageData.boss.

var active := false
var data: EnemyData
var is_boss := false
var bdef := {}
var hp := 10.0
var max_hp := 10.0
var spd := 46.0
var dmg := 6.0
var radius := 11.0
var xp := 1.0
var behavior := "chase"
var color := Color.WHITE
var shape := "blob"
var elite := false
var _tex: Texture2D = null

var t := 0.0
var seed_off := 0.0
var flash := 0.0
var slow_t := 0.0
var slow_mul := 1.0
var knock := Vector2.ZERO
var contact_cd := 0.0
var dead := false
var _orb_cd := 0.0

# ranged / bomber
var fire_t := 0.0
# boss
var phase := {}
var phase_key := ""
var atk_t: Array = []
var spin_acc := 0.0
var dash := {}

func reset(d: EnemyData, pos: Vector2, hp_mul: float, opts := {}) -> void:
	data = d
	position = pos
	is_boss = opts.get("boss", false)
	bdef = opts.get("boss_def", {})
	if is_boss:
		max_hp = float(bdef.hp) * hp_mul
		spd = float(bdef.speed)
		dmg = float(bdef.contact)
		radius = float(bdef.radius)
		color = bdef.color
		shape = "boss"
		behavior = "boss"
		elite = false
		xp = 0.0
	else:
		max_hp = d.hp * hp_mul
		spd = d.speed
		dmg = d.damage
		radius = d.radius
		color = d.color
		shape = d.shape
		behavior = d.behavior
		elite = d.elite
		xp = d.xp
		_tex = GameData.get_texture(d.texture_path)
	hp = max_hp
	t = 0.0
	seed_off = randf() * 100.0
	flash = 0.0
	slow_t = 0.0
	slow_mul = 1.0
	knock = Vector2.ZERO
	contact_cd = 0.0
	dead = false
	_orb_cd = 0.0
	fire_t = (d.extra.get("fire_cd", 2.0) * randf()) if (d and d.behavior == "ranged") else 0.0
	phase = {}
	phase_key = ""
	atk_t = []
	spin_acc = 0.0
	dash = {}
	visible = true
	modulate = Color.WHITE
	queue_redraw()

func on_release() -> void:
	visible = false

func slow(mul: float, dur: float) -> void:
	if mul < slow_mul:
		slow_mul = mul
	slow_t = max(slow_t, dur)

func tick(dt: float, world) -> void:
	t += dt
	if _orb_cd > 0.0:
		_orb_cd -= dt
	if flash > 0.0:
		flash -= dt
		queue_redraw()
	if slow_t > 0.0:
		slow_t -= dt
		if slow_t <= 0.0:
			slow_mul = 1.0
	if contact_cd > 0.0:
		contact_cd -= dt
	if knock != Vector2.ZERO:
		position += knock * dt
		knock = knock.lerp(Vector2.ZERO, 1.0 - pow(0.001, dt))
		if knock.length() < 2.0:
			knock = Vector2.ZERO
	var p: Vector2 = world.player.position
	var to_p := p - position
	var d := to_p.length()
	var dir := to_p / d if d > 0.001 else Vector2.RIGHT
	var sp := spd * slow_mul
	match behavior:
		"chase":
			position += dir * sp * dt
		"weave":
			var perp := dir.orthogonal() * sin(t * 6.0 + seed_off) * 0.6
			position += (dir + perp).normalized() * sp * dt
		"ranged":
			_ranged(dt, world, p, d, dir, sp)
		"bomber":
			position += dir * sp * dt
		"boss":
			_boss(dt, world, p, d, dir)
		_:
			position += dir * sp * dt

func _ranged(dt, world, p, d, dir, sp) -> void:
	var range_ := float(data.extra.get("range", 300))
	if d > range_:
		position += dir * sp * dt
	elif d < range_ * 0.6:
		position -= dir * sp * dt
	else:
		position += dir.orthogonal() * sp * 0.5 * dt
	fire_t -= dt
	if fire_t <= 0.0 and d < range_ * 1.25:
		fire_t = float(data.extra.get("fire_cd", 2.0))
		var n := int(data.extra.get("burst", 1))
		var base = (p - position).angle()
		for i in n:
			world.spawn_enemy_projectile(position, base + (i - (n - 1) * 0.5) * 0.14, float(data.extra.get("proj_speed", 170)), float(data.extra.get("proj_dmg", 8)))
		world.vfx.spark(position, color, 4, 0.25)

func _boss(dt, world, p, d, dir) -> void:
	var frac := hp / max_hp
	var phases: Array = bdef.phases
	var chosen: Dictionary = phases[0]
	for i in phases.size():
		if frac <= float(phases[i].at):
			chosen = phases[i]
	var key := "p%d" % phases.find(chosen)
	if key != phase_key:
		phase_key = key
		phase = chosen
		spd = float(chosen.get("spd", spd))
		atk_t = []
		var atks: Array = chosen.attacks
		for i in atks.size():
			atk_t.append(float(atks[i].cd) * 0.5 + i * 0.35)
		if chosen.get("enrage", false):
			world.vfx.ring(position, radius + 12, GameData.COL.red)
	# movement (dash overrides)
	if not dash.is_empty():
		if dash.stage == "windup":
			dash.t -= dt
			if dash.t <= 0.0:
				dash.vel = (p - position).normalized() * dash.speed
				dash.stage = "go"
				dash.t = 0.45
		else:
			position += dash.vel * dt
			dash.t -= dt
			if dash.t <= 0.0:
				dash = {}
	else:
		position += dir * spd * slow_mul * dt
	# attacks
	var atks: Array = phase.attacks
	for i in atks.size():
		atk_t[i] -= dt
		if atk_t[i] <= 0.0:
			atk_t[i] = float(atks[i].cd)
			_do_attack(atks[i], world, p)

func _do_attack(a: Dictionary, world, p: Vector2) -> void:
	match a.type:
		"summon":
			for i in int(a.count):
				world.spawn_enemy(a.enemy, position + Vector2(randf_range(-30, 30), randf_range(-30, 30)))
			world.vfx.ring(position, radius, color)
		"aimed":
			var base = (p - position).angle()
			var cnt := int(a.count)
			for i in cnt:
				world.spawn_enemy_projectile(position, base + (i - (cnt - 1) * 0.5) * float(a.get("spread", 0.0)), float(a.proj_speed), float(a.proj_dmg))
		"radial":
			spin_acc += float(a.get("spin", 0.0))
			var cnt := int(a.count)
			for i in cnt:
				world.spawn_enemy_projectile(position, float(i) / cnt * TAU + spin_acc, float(a.proj_speed), float(a.proj_dmg))
			world.vfx.ring(position, radius, color)
		"dash":
			dash = {"stage": "windup", "t": float(a.windup), "speed": float(a.speed), "vel": Vector2.ZERO}
			world.vfx.spark(position, GameData.COL.yellow, 8, 0.3)
		"pulse":
			world.spawn_pulse(position, float(a.radius), float(a.dmg), float(a.get("telegraph", 1.0)), color)

func apply_damage(amount: float, world, kb := Vector2.ZERO, is_crit := false) -> void:
	if dead:
		return
	hp -= amount
	flash = 0.09
	queue_redraw()
	if kb != Vector2.ZERO:
		var m := 0.0 if is_boss else (0.22 if elite else 1.0)
		knock += kb * m
	if hp <= 0.0:
		die(world)

func die(world) -> void:
	active = false
	dead = true
	if behavior == "bomber":
		explode(world)
	if is_boss:
		world.on_boss_killed(self)
	else:
		world.on_enemy_killed(self)

func explode(world) -> void:
	world.vfx.burst(position, GameData.COL.orange, 22, 3.5)
	world.vfx.ring(position, float(data.extra.get("explode_r", 60)), GameData.COL.orange)
	world.damage_player_aoe(position, float(data.extra.get("explode_r", 60)), float(data.extra.get("explode_dmg", 22)))

func _draw() -> void:
	if _tex != null and not is_boss:
		var sz := _tex.get_size()
		draw_texture(_tex, Vector2(-sz.x * 0.5, -sz.y * 0.5))
	else:
		_draw_shape()
	if flash > 0.0:
		var a := flash / 0.09 * 0.8
		_draw_shape_solid(Color(1, 1, 1, a))
	if elite and not is_boss and hp < max_hp:
		draw_rect(Rect2(-radius, -radius - 7, radius * 2, 3), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(-radius, -radius - 7, radius * 2 * (hp / max_hp), 3), GameData.COL.hp)

func _draw_shape() -> void:
	_draw_shape_solid(color)

func _draw_shape_solid(c: Color) -> void:
	var s := radius
	match shape:
		"crawler":
			draw_circle(Vector2.ZERO, s, c)
			draw_circle(Vector2(-s * 0.35, -s * 0.2), 1.5, Color.BLACK)
			draw_circle(Vector2(s * 0.35, -s * 0.2), 1.5, Color.BLACK)
		"brute":
			draw_rect(Rect2(-s, -s, s * 2, s * 2), c)
			draw_rect(Rect2(-s, -s, s * 2, s * 0.5), Color(1, 1, 1, 0.15))
		"sparker":
			draw_circle(Vector2.ZERO, s, c)
			draw_arc(Vector2.ZERO, s + 2, 0, TAU, 12, Color(c.r, c.g, c.b, 0.5), 1.5)
		"ruptor":
			draw_circle(Vector2.ZERO, s, c)
			draw_circle(Vector2.ZERO, s * 0.5, GameData.COL.yellow)
		"boss":
			draw_circle(Vector2.ZERO, s, c)
			for i in 8:
				var a := float(i) / 8.0 * TAU + t * 0.4
				draw_circle(Vector2(cos(a), sin(a)) * s * 0.7, s * 0.16, Color(0, 0, 0, 0.35))
			draw_circle(Vector2(-s * 0.3, -s * 0.15), s * 0.14, GameData.COL.white)
			draw_circle(Vector2(s * 0.3, -s * 0.15), s * 0.14, GameData.COL.white)
		_:
			draw_circle(Vector2.ZERO, s, c)
