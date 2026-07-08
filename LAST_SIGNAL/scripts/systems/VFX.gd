class_name VFX
extends Node2D
## World-space effects: particles, floating damage numbers, expanding rings, screen shake,
## plus weapon visuals (orbiting drones, laser beam, auras). Drawn in one node for efficiency.

var world
var particles: Array = []
var dmg_numbers: Array = []
var rings: Array = []
var shake_mag := 0.0
var shake_t := 0.0
var offset := Vector2.ZERO
var _font: Font

const CAP_PARTICLES := 600
const CAP_DMG := 100

func _ready() -> void:
	_font = ThemeDB.fallback_font
	z_index = 50

func _low() -> bool:
	return world != null and world.quality == "low"

func spark(pos: Vector2, color: Color, count: int, life := 0.25, size := 2.0, _additive := false) -> void:
	if _low():
		count = int(ceil(count * 0.5))
	for i in count:
		if particles.size() >= CAP_PARTICLES:
			break
		var a := randf() * TAU
		var s := randf_range(10, 55)
		particles.append({"p": pos, "v": Vector2(cos(a), sin(a)) * s, "life": life * randf_range(0.7, 1.1), "ml": life, "size": size, "c": color, "drag": 0.9})

func burst(pos: Vector2, color: Color, count: int, speed := 3.0) -> void:
	if _low():
		count = int(ceil(count * 0.5))
	for i in count:
		if particles.size() >= CAP_PARTICLES:
			break
		var a := randf() * TAU
		var s := 40.0 + randf_range(0, 120) * speed * 0.02
		particles.append({"p": pos, "v": Vector2(cos(a), sin(a)) * s, "life": randf_range(0.25, 0.6), "ml": 0.6, "size": randf_range(2, 4), "c": color, "drag": 0.86})

func ring(pos: Vector2, r: float, color: Color) -> void:
	rings.append({"p": pos, "r": r * 0.35, "max": r * 1.35, "life": 0.4, "ml": 0.4, "c": color})

func dmg_num(pos: Vector2, amount: float, color: Color, crit := false) -> void:
	if not SaveSystem.settings.get("damage_numbers", true) or dmg_numbers.size() >= CAP_DMG:
		return
	dmg_numbers.append({"p": pos + Vector2(randf_range(-4, 4), -6), "vy": -42.0, "life": 0.7, "ml": 0.7, "n": int(round(amount)), "c": color, "crit": crit})

func shake(m: float) -> void:
	if not SaveSystem.settings.get("shake", true):
		return
	shake_mag = max(shake_mag, m)
	shake_t = max(shake_t, 0.25)

func hit_flash() -> void:
	pass  # full-screen hurt flash is handled by the HUD via the player_damaged signal

func tick(dt: float) -> void:
	var n := 0
	for pt in particles:
		pt.life -= dt
		if pt.life > 0.0:
			var f := pow(pt.drag, dt * 60.0)
			pt.v *= f
			pt.p += pt.v * dt
			particles[n] = pt
			n += 1
	particles.resize(n)
	var m := 0
	for r in rings:
		r.life -= dt
		r.r = lerp(r.max * 0.3, r.max, 1.0 - r.life / r.ml)
		if r.life > 0.0:
			rings[m] = r
			m += 1
	rings.resize(m)
	var k := 0
	for d in dmg_numbers:
		d.life -= dt
		d.p.y += d.vy * dt
		d.vy *= pow(0.9, dt * 60.0)
		if d.life > 0.0:
			dmg_numbers[k] = d
			k += 1
	dmg_numbers.resize(k)
	if shake_t > 0.0:
		shake_t -= dt
		var mag := shake_mag * maxf(0.0, shake_t / 0.25)
		offset = Vector2(randf_range(-mag, mag), randf_range(-mag, mag))
		if shake_t <= 0.0:
			offset = Vector2.ZERO
			shake_mag = 0.0
	else:
		offset = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	_draw_weapon_visuals()
	for pt in particles:
		var a: float = clampf(pt.life / pt.ml, 0.0, 1.0)
		var c: Color = pt.c
		draw_circle(pt.p, pt.size * (0.35 + 0.65 * a), Color(c.r, c.g, c.b, a))
	for r in rings:
		var a: float = max(0.0, r.life / r.ml) * 0.6
		draw_arc(r.p, r.r, 0, TAU, 24, Color(r.c.r, r.c.g, r.c.b, a), 2.0)
	if _font:
		for d in dmg_numbers:
			var a: float = clampf(d.life / d.ml * 1.6, 0.0, 1.0)
			var col: Color = d.c
			var size := 20 if d.crit else 15
			draw_string(_font, d.p, str(d.n), HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color(col.r, col.g, col.b, a))

func _draw_weapon_visuals() -> void:
	if world == null or world.player == null:
		return
	var pl = world.player
	# orbiting drones
	if pl.weapon_state.has("drone_companion"):
		var st = pl.weapon_state["drone_companion"]
		if st.has("drones"):
			for dr in st.drones:
				draw_circle(dr.pos, 5, GameData.COL.steel)
				draw_circle(dr.pos, 2.5, GameData.COL.cyan)
	# laser beam
	if pl.weapon_state.has("laser_beam") and pl.weapons.has("laser_beam"):
		var w: WeaponData = GameData.weapons["laser_beam"]
		var lvl: int = pl.weapons["laser_beam"]
		var st = pl.weapon_state["laser_beam"]
		var ang: float = st.get("angle", 0.0)
		var length: float = w.ev("length", lvl) * pl.stats.area_mul
		var width: float = w.ev("width", lvl)
		var dir := Vector2(cos(ang), sin(ang))
		var col := GameData.COL.pink
		draw_line(pl.position, pl.position + dir * length, Color(col.r, col.g, col.b, 0.85), width, true)
		draw_line(pl.position, pl.position + dir * length, Color(1, 1, 1, 0.5), width * 0.4, true)
