class_name Pickup
extends Node2D
## Pooled pickup: fragment (XP), scrap, heal, or data cache. Magnetized toward the player.

var active := false
var type := "fragment"      # fragment | scrap | heal | cache
var value := 1.0
var color := Color.WHITE
var vel := Vector2.ZERO
var magnet := false
var t := 0.0
var radius := 5.0
var big := false

func reset(pos: Vector2, kind: String, val: float, col: Color) -> void:
	position = pos
	type = kind
	value = val
	color = col
	vel = Vector2(randf_range(-50, 50), randf_range(-70, -10))
	magnet = false
	t = 0.0
	big = false
	radius = 12.0 if kind == "cache" else (6.0 if kind == "scrap" else 5.0)
	visible = true
	queue_redraw()

func on_release() -> void:
	visible = false

func tick(dt: float, world) -> void:
	t += dt
	vel = vel.lerp(Vector2.ZERO, 1.0 - pow(0.15, dt))
	position += vel * dt
	var p: Player = world.player
	var to_p := p.position - position
	var d2 := to_p.length_squared()
	var mr: float = p.stats.pickup_radius
	if type != "cache" and (magnet or d2 < mr * mr):
		magnet = true
		var d := sqrt(d2)
		var pull := 300.0 + 520.0 * (1.0 - minf(1.0, d / (mr + 60.0)))
		position += to_p.normalized() * pull * dt
	var rc := p.radius + radius + (4.0 if type == "cache" else 3.0)
	if d2 < rc * rc:
		world.collect_pickup(self)
		active = false

func _draw() -> void:
	match type:
		"fragment":
			# diamond shard (distinct shape for colorblind readability)
			var s := 5.0 if value >= 25 else (4.0 if value >= 5 else 3.0)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -s), Vector2(s, 0), Vector2(0, s), Vector2(-s, 0)]), color)
		"scrap":
			draw_circle(Vector2.ZERO, 5, color)
			draw_circle(Vector2(-1.5, -1.5), 1.5, Color(1, 1, 1, 0.5))
		"heal":
			draw_rect(Rect2(-5, -1.5, 10, 3), color)
			draw_rect(Rect2(-1.5, -5, 3, 10), color)
		"cache":
			var bob := sin(t * 4.0) * 2.0
			draw_rect(Rect2(-10, -8 + bob, 20, 16), Color("#394a63"))
			draw_rect(Rect2(-10, -2 + bob, 20, 3), GameData.COL.cyan)
			draw_rect(Rect2(-2, -6 + bob, 4, 10), GameData.COL.cyan)
