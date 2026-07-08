class_name Projectile
extends Node2D
## Pooled projectile (friendly bolt/splash/homing, or hostile enemy shot). Collisions resolved in World.

var active := false
var vel := Vector2.ZERO
var spd := 0.0
var dmg := 0.0
var pierce := 0
var life := 2.2
var radius := 6.0
var color := Color.WHITE
var type := "bolt"          # bolt | homing | hostile
var hostile := false
var is_crit := false
var splash := 0.0
var trail := true
var turn := 0.0
var target = null
var hit_list: Array = []

func reset(pos: Vector2, v: Vector2, damage: float, opts := {}) -> void:
	position = pos
	vel = v
	spd = v.length()
	dmg = damage
	pierce = int(opts.get("pierce", 0))
	life = float(opts.get("life", 2.2))
	radius = float(opts.get("radius", 6.0))
	color = opts.get("color", Color.WHITE)
	type = opts.get("type", "bolt")
	hostile = bool(opts.get("hostile", false))
	is_crit = bool(opts.get("crit", false))
	splash = float(opts.get("splash", 0.0))
	turn = float(opts.get("turn", 0.0))
	trail = bool(opts.get("trail", true))
	target = null
	hit_list.clear()
	rotation = vel.angle()
	visible = true
	queue_redraw()

func on_release() -> void:
	visible = false

func tick(dt: float, world) -> void:
	life -= dt
	if life <= 0.0:
		active = false
		return
	if type == "homing":
		if target == null or not target.active or target.dead:
			target = world.nearest_enemy(position, 520.0, [])
		if target != null:
			var desired = (target.position - position).normalized() * spd
			vel = vel.lerp(desired, clampf(turn * dt, 0.0, 1.0))
	position += vel * dt
	rotation = vel.angle()
	if trail and world.quality != "low" and (world.frame & 1) == 0:
		world.vfx.spark(position, color, 1, 0.18, 2.0, true)

func _draw() -> void:
	if type == "hostile":
		draw_circle(Vector2.ZERO, radius, color)
		draw_circle(Vector2(-1, -1), radius * 0.4, Color(1, 1, 1, 0.6))
	else:
		# elongated energy bolt along +x
		draw_line(Vector2(-radius, 0), Vector2(radius + 3, 0), color, radius, true)
		draw_circle(Vector2(radius + 3, 0), radius * 0.6, Color(1, 1, 1, 0.7))
