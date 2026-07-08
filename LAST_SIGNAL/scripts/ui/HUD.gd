class_name HUD
extends Control
## In-run overlay: XP/HP bars, timer, stage, score, Scrap, build chips, boss bar, banner, hurt flash, touch joystick.

var world
var _xp_bg: ColorRect
var _xp_fill: ColorRect
var _hp_bg: ColorRect
var _hp_fill: ColorRect
var _hp_label: Label
var _lvl_label: Label
var _timer_label: Label
var _stage_label: Label
var _scrap_label: Label
var _kills_label: Label
var _boss_root: Control
var _boss_fill: ColorRect
var _boss_label: Label
var _banner: Label
var _hurt: ColorRect
var _chips: HBoxContainer

var _banner_t := 0.0
var _hurt_a := 0.0
var _joy_active := false
var _joy_origin := Vector2.ZERO
var _joy_cur := Vector2.ZERO

func setup(world_ref) -> void:
	world = world_ref
	UI.fullrect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 40

	_hurt = ColorRect.new(); _hurt.color = Color(1, 0.1, 0.2, 0.0); UI.fullrect(_hurt); _hurt.mouse_filter = MOUSE_FILTER_IGNORE; add_child(_hurt)

	_xp_bg = _rect(Color(0, 0, 0, 0.45)); add_child(_xp_bg)
	_xp_fill = _rect(GameData.COL.xp); add_child(_xp_fill)
	_lvl_label = _lbl(12, GameData.COL.ink); add_child(_lvl_label)

	_hp_bg = _rect(Color(0, 0, 0, 0.5)); add_child(_hp_bg)
	_hp_fill = _rect(GameData.COL.hp); add_child(_hp_fill)
	_hp_label = _lbl(11, GameData.COL.ink); add_child(_hp_label)

	_timer_label = _lbl(26, GameData.COL.ink); add_child(_timer_label)
	_stage_label = _lbl(12, GameData.COL.ink2); add_child(_stage_label)
	_scrap_label = _lbl(14, GameData.COL.scrap); _scrap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; add_child(_scrap_label)
	_kills_label = _lbl(12, GameData.COL.ink2); _kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; add_child(_kills_label)

	_chips = HBoxContainer.new(); _chips.add_theme_constant_override("separation", 4); add_child(_chips)

	_boss_root = Control.new(); _boss_root.visible = false; add_child(_boss_root)
	var bbg := _rect(Color(0, 0, 0, 0.55)); bbg.size = Vector2(520, 14); _boss_root.add_child(bbg)
	_boss_fill = _rect(GameData.COL.purple); _boss_fill.size = Vector2(520, 14); _boss_root.add_child(_boss_fill)
	_boss_label = _lbl(12, GameData.COL.ink); _boss_root.add_child(_boss_label)

	_banner = _lbl(30, GameData.COL.cyan); _banner.modulate.a = 0.0; add_child(_banner)

	Events.player_damaged.connect(func(_c, _m): _hurt_a = 0.5 if SaveSystem.settings.get("flashes", true) else 0.0)
	Events.weapon_changed.connect(func(_a, _b): _rebuild_chips())
	Events.player_stats_changed.connect(_rebuild_chips)
	_rebuild_chips()

func _rect(c: Color) -> ColorRect:
	var r := ColorRect.new(); r.color = c; r.mouse_filter = MOUSE_FILTER_IGNORE; return r

func _lbl(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = MOUSE_FILTER_IGNORE
	return l

func set_banner(text: String) -> void:
	_banner.text = text
	_banner_t = 2.6

func set_joystick(active: bool, origin: Vector2, cur: Vector2) -> void:
	_joy_active = active; _joy_origin = origin; _joy_cur = cur
	queue_redraw()

func _rebuild_chips() -> void:
	if world == null or _chips == null:
		return
	for c in _chips.get_children():
		c.queue_free()
	for id in world.player.weapons.keys():
		_chips.add_child(_chip(GameData.weapons[id].display_name.substr(0, 1), GameData.weapons[id].color, world.player.weapons[id]))
	for id in world.player.passives.keys():
		_chips.add_child(_chip(GameData.passives[id].display_name.substr(0, 1), GameData.passives[id].color, world.player.passives[id]))

func _chip(letter: String, color: Color, level: int) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI._sb(color, Color(color.r, color.g, color.b, 0.0), 0, 4))
	var l := Label.new()
	l.text = "%s%d" % [letter, level]
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0, 0, 0, 0.75))
	p.add_child(l)
	return p

func refresh() -> void:
	if world == null:
		return
	var vp := get_viewport_rect().size
	var pl = world.player
	# XP bar
	_xp_bg.position = Vector2.ZERO; _xp_bg.size = Vector2(vp.x, 8)
	_xp_fill.position = Vector2.ZERO; _xp_fill.size = Vector2(vp.x * clampf(pl.xp / pl.xp_next, 0, 1), 8)
	_lvl_label.text = "LV %d" % pl.level; _lvl_label.position = Vector2(8, 12)
	# HP bar
	_hp_bg.position = Vector2(8, 30); _hp_bg.size = Vector2(210, 16)
	_hp_fill.position = Vector2(8, 30); _hp_fill.size = Vector2(210 * clampf(pl.hp / pl.max_hp, 0, 1), 16)
	_hp_label.text = "%d / %d" % [ceil(pl.hp), pl.max_hp]; _hp_label.position = Vector2(90, 31)
	# chips
	_chips.position = Vector2(8, 52)
	# timer + stage
	_timer_label.text = Util.fmt_time(world.stage_time); _timer_label.size.x = 200; _timer_label.position = Vector2(vp.x * 0.5 - 100, 8)
	_stage_label.text = "%s  ·  Sector %d/%d" % [world.stage.display_name, world.stage_index + 1, GameData.stages.size()]
	_stage_label.size.x = 400; _stage_label.position = Vector2(vp.x * 0.5 - 200, 44)
	# scrap + kills
	_scrap_label.text = "◆ %s" % Util.fmt_num(world.run_scrap); _scrap_label.size.x = 160; _scrap_label.position = Vector2(vp.x - 172, 10)
	_kills_label.text = "☠ %s" % Util.fmt_num(pl.kills); _kills_label.size.x = 160; _kills_label.position = Vector2(vp.x - 172, 30)
	# boss bar
	if world.boss != null and world.boss.active:
		_boss_root.visible = true
		var bw := minf(vp.x * 0.7, 520.0)
		_boss_root.position = Vector2((vp.x - bw) * 0.5, vp.y - 40)
		_boss_root.get_child(0).size = Vector2(bw, 14)
		_boss_fill.size = Vector2(bw * clampf(world.boss.hp / world.boss.max_hp, 0, 1), 14)
		_boss_label.text = world.boss.bdef.name
		_boss_label.size.x = bw; _boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _boss_label.position = Vector2(0, -20)
	else:
		_boss_root.visible = false
	# banner
	if _banner_t > 0.0:
		_banner_t -= get_physics_process_delta_time()
		_banner.modulate.a = clampf(_banner_t, 0, 1)
		_banner.size.x = vp.x; _banner.position = Vector2(0, vp.y * 0.28)
	# hurt flash
	if _hurt_a > 0.0:
		_hurt_a = max(0.0, _hurt_a - get_physics_process_delta_time() * 1.6)
		_hurt.color.a = _hurt_a

func _draw() -> void:
	if _joy_active:
		draw_circle(_joy_origin, 66, Color(1, 1, 1, 0.12))
		draw_circle(_joy_cur, 24, Color(1, 1, 1, 0.28))
