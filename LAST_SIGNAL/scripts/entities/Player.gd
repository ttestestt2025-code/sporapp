class_name Player
extends Node2D
## The Signal Keeper. Manual movement + auto weapons. Manual (grid-based) collisions handled in World.

var world                      # World ref
var character := "keeper"
var radius := 12.0

var max_hp := 100.0
var hp := 100.0
var stats := {}
var level := 1
var xp := 0.0
var xp_next := GameData.xp_cost(1)
var pending_levels := 0
var kills := 0

var invuln := 0.0
var dead := false
var move_dir := Vector2.RIGHT
var facing := 1
var walk_t := 0.0
var regen_accum := 0.0
var revives := 0
var revives_max := 0
var shield := 0
var shield_max := 0
var shield_recharge_t := 0.0

var weapons := {}              # id -> level
var passives := {}             # id -> level
var weapon_state := {}         # id -> Dictionary
var _tex: Texture2D = null

func setup(world_ref, character_id: String) -> void:
	world = world_ref
	character = character_id
	_tex = GameData.get_texture("res://assets/sprites/player/signal_keeper.png")
	compute_stats(true)
	var start := "energy_mine" if character == "scavenger" else "energy_rifle"
	add_weapon(start)
	hp = max_hp
	shield = shield_max

func compute_stats(init := false) -> void:
	var b := {
		"flat_hp": 0.0, "max_hp_mul": 1.0, "power_mul": 1.0, "cd_mul": 1.0, "move_mul": 1.0,
		"area_mul": 1.0, "proj_speed_mul": 1.0, "pickup_mul": 1.0, "regen_add": 0.0,
		"crit_chance_add": 0.0, "crit_dmg_add": 0.0, "armor_add": 0.0, "dr_add": 0.0,
		"frag_mul": 1.0, "scrap_mul": 1.0, "count_add": 0.0, "shield_add": 0.0, "luck_add": 0.0,
	}
	# meta upgrades
	b.power_mul += 0.05 * SaveSystem.meta_level("power")
	b.flat_hp += 10.0 * SaveSystem.meta_level("vitality")
	b.move_mul += 0.04 * SaveSystem.meta_level("servos")
	b.armor_add += 1.0 * SaveSystem.meta_level("plating")
	b.luck_add += 0.05 * SaveSystem.meta_level("fortune")
	b.scrap_mul += 0.08 * SaveSystem.meta_level("avarice")
	b.frag_mul += 0.05 * SaveSystem.meta_level("insight")
	b.regen_add += 0.3 * SaveSystem.meta_level("recovery")
	b.pickup_mul += 0.20 * SaveSystem.meta_level("magnetics")
	var meta_revives := SaveSystem.meta_level("reboot")
	# character
	if character == "scavenger":
		b.scrap_mul += 0.10
		b.max_hp_mul -= 0.10
	# passives
	has_volatile = false
	for id in passives.keys():
		var p: PassiveData = GameData.passives[id]
		var lvl: int = passives[id]
		if p.flag == "volatile":
			has_volatile = true
			continue
		if p.stat == "none" or not b.has(p.stat):
			continue
		if p.mode == "mul_reduce":
			b[p.stat] *= (1.0 - p.per_level * lvl)
		else:
			b[p.stat] += p.per_level * lvl
	# finalize
	var prev_max := max_hp
	max_hp = round((100.0 + b.flat_hp) * b.max_hp_mul)
	revives_max = meta_revives
	shield_max = int(b.shield_add)
	stats = {
		"move": 150.0 * b.move_mul,
		"power": b.power_mul,
		"cd_mul": clampf(b.cd_mul, 0.35, 1.0),
		"area_mul": b.area_mul,
		"proj_speed_mul": b.proj_speed_mul,
		"pickup_radius": 42.0 * b.pickup_mul,
		"regen": b.regen_add,
		"armor": b.armor_add,
		"dr": clampf(b.dr_add, 0.0, 0.75),
		"crit_chance": 0.05 + b.crit_chance_add,
		"crit_dmg": 1.5 + b.crit_dmg_add,
		"frag_mul": b.frag_mul,
		"scrap_mul": b.scrap_mul,
		"count_add": int(b.count_add),
		"luck": 1.0 + b.luck_add,
	}
	if init:
		revives = revives_max
		hp = max_hp
	elif max_hp > prev_max:
		hp = min(max_hp, hp + (max_hp - prev_max))
	Events.player_stats_changed.emit()

var has_volatile := false

func add_weapon(id: String) -> bool:
	if not GameData.weapons.has(id):
		return false
	var w: WeaponData = GameData.weapons[id]
	if weapons.has(id):
		if weapons[id] >= w.max_level:
			return false
		weapons[id] += 1
	else:
		if weapons.size() >= 6:
			return false
		weapons[id] = 1
		weapon_state[id] = {"cd": 0.0, "angle": randf() * TAU, "tick": 0.0, "drones": []}
	Events.weapon_changed.emit(id, weapons[id])
	return true

func add_passive(id: String) -> bool:
	if not GameData.passives.has(id):
		return false
	var p: PassiveData = GameData.passives[id]
	if passives.has(id):
		if passives[id] >= p.max_level:
			return false
		passives[id] += 1
	else:
		if passives.size() >= 6:
			return false
		passives[id] = 1
	compute_stats(false)
	return true

func gain_xp(n: float) -> void:
	xp += n * stats.frag_mul
	while xp >= xp_next:
		xp -= xp_next
		level += 1
		xp_next = GameData.xp_cost(level)
		pending_levels += 1
		Events.player_leveled_up.emit(level)

func heal(n: float) -> void:
	hp = min(max_hp, hp + n)
	Events.player_healed.emit(n)

func hurt(dmg: float) -> void:
	if invuln > 0.0 or dead:
		return
	if shield > 0:
		shield -= 1
		invuln = 0.4
		shield_recharge_t = 8.0
		world.vfx.ring(global_position, 30.0, GameData.COL.cyan)
		AudioManager.play_sfx("hit")
		return
	var d: float = max(1.0, dmg * (1.0 - stats.dr) - stats.armor)
	hp -= d
	invuln = 0.5
	Events.player_damaged.emit(hp, max_hp)
	world.vfx.shake(6.0)
	world.vfx.hit_flash()
	world.vfx.burst(global_position, GameData.COL.hp, 8, 3.0)
	AudioManager.play_sfx("player_hurt")
	if hp <= 0.0:
		if revives > 0:
			revives -= 1
			hp = round(max_hp * 0.5)
			invuln = 1.5
			world.vfx.ring(global_position, 60.0, GameData.COL.yellow)
		else:
			dead = true
			hp = 0.0
			Events.player_died.emit()

func tick(dt: float) -> void:
	if invuln > 0.0:
		invuln -= dt
	var ax: Vector2 = world.get_move_input()
	var moving := ax.length() > 0.05
	if moving:
		position += ax * stats.move * dt
		move_dir = ax.normalized()
		if absf(ax.x) > 0.01:
			facing = -1 if ax.x < 0 else 1
		walk_t += dt
	position = position.clamp(world.bounds_min, world.bounds_max)
	if stats.regen > 0.0 and hp < max_hp:
		regen_accum += stats.regen * dt
		if regen_accum >= 1.0:
			var h := floor(regen_accum)
			heal(h)
			regen_accum -= h
	if shield < shield_max:
		shield_recharge_t -= dt
		if shield_recharge_t <= 0.0:
			shield += 1
			shield_recharge_t = 8.0
	WeaponRunner.update(world, self, dt)
	queue_redraw()

func _draw() -> void:
	# invulnerability blink
	if invuln > 0.0 and int(invuln * 20) % 2 == 0:
		modulate.a = 0.45
	else:
		modulate.a = 1.0
	var bob := sin(walk_t * 14.0) * 2.0
	if _tex != null:
		var sz := _tex.get_size()
		draw_texture(_tex, Vector2(-sz.x * 0.5, -sz.y * 0.5 + bob))
	else:
		# graybox Signal Keeper: armored operator with a signal core
		draw_circle(Vector2(0, 4 + bob), 11, Color(0, 0, 0, 0.35))            # shadow
		var body := Color("#2a3d52")
		draw_colored_polygon(PackedVector2Array([Vector2(-9, 12 + bob), Vector2(9, 12 + bob), Vector2(6, -6 + bob), Vector2(-6, -6 + bob)]), body)
		draw_circle(Vector2(0, -8 + bob), 6, Color("#3a5570"))                # head
		draw_circle(Vector2(facing * 1.5, -8 + bob), 3.0, GameData.COL.cyan)  # visor
		var pulse := 3.0 + sin(walk_t * 8.0) * 0.7
		draw_circle(Vector2(0, 2 + bob), pulse, GameData.COL.cyan)            # signal core
		draw_circle(Vector2(0, 2 + bob), pulse * 0.5, GameData.COL.white)
	if shield > 0:
		draw_arc(Vector2.ZERO, 18, 0, TAU, 24, GameData.COL.cyan, 2.0)
