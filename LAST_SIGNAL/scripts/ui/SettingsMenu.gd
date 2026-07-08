class_name SettingsMenu
extends Control
## Reusable settings overlay: volumes, accessibility toggles, difficulty, quality. Frees itself on close.

func _ready() -> void:
	UI.fullrect(self)
	z_index = 100
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	UI.fullrect(dim)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel_style())
	panel.custom_minimum_size = Vector2(420, 0)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	vb.add_child(UI.label("SETTINGS", 26, GameData.COL.cyan))
	var s := SaveSystem.settings

	vb.add_child(_slider("Master Volume", s.get("master", 0.9), func(v):
		s.master = v; AudioManager.apply_settings(); SaveSystem.save_settings()))
	vb.add_child(_slider("Music", s.get("music", 0.55), func(v):
		s.music = v; AudioManager.apply_settings(); SaveSystem.save_settings()))
	vb.add_child(_slider("Sound FX", s.get("sfx", 0.85), func(v):
		s.sfx = v; SaveSystem.save_settings()))

	vb.add_child(_toggle("Screen Shake", s.get("shake", true), func(v): s.shake = v; SaveSystem.save_settings()))
	vb.add_child(_toggle("Damage Numbers", s.get("damage_numbers", true), func(v): s.damage_numbers = v; SaveSystem.save_settings()))
	vb.add_child(_toggle("Flashes / Particles", s.get("flashes", true), func(v): s.flashes = v; SaveSystem.save_settings()))

	vb.add_child(_options("Difficulty", ["normal", "hard"], s.get("difficulty", "normal"), func(val): s.difficulty = val; SaveSystem.save_settings()))
	vb.add_child(_options("Quality", ["auto", "low", "high"], s.get("quality", "auto"), func(val): s.quality = val; SaveSystem.save_settings()))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var reset := UI.button("Reset Save", GameData.COL.red, Vector2(180, 40), 15)
	reset.pressed.connect(func(): SaveSystem.reset_progress(); AudioManager.play_sfx("ui_click"))
	row.add_child(reset)
	var close := UI.button("Close", GameData.COL.cyan, Vector2(180, 40), 15)
	close.pressed.connect(func(): AudioManager.play_sfx("ui_click"); queue_free())
	row.add_child(close)
	vb.add_child(row)

func _slider(text: String, value: float, cb: Callable) -> Control:
	var vb := VBoxContainer.new()
	vb.add_child(UI.label(text, 13, GameData.COL.ink2))
	var sl := HSlider.new()
	sl.min_value = 0.0; sl.max_value = 1.0; sl.step = 0.01; sl.value = value
	sl.custom_minimum_size = Vector2(360, 20)
	sl.value_changed.connect(func(v): cb.call(v))
	vb.add_child(sl)
	return vb

func _toggle(text: String, value: bool, cb: Callable) -> Control:
	var cb_node := CheckButton.new()
	cb_node.text = text
	cb_node.button_pressed = value
	cb_node.add_theme_color_override("font_color", GameData.COL.ink)
	cb_node.toggled.connect(func(v): AudioManager.play_sfx("ui_click"); cb.call(v))
	return cb_node

func _options(text: String, values: Array, current: String, cb: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(UI.label(text + ":", 13, GameData.COL.ink2))
	for val in values:
		var b := UI.button(str(val).capitalize(), GameData.COL.steel, Vector2(90, 34), 13)
		if val == current:
			b.add_theme_stylebox_override("normal", UI._sb(Color(GameData.COL.cyan.r, GameData.COL.cyan.g, GameData.COL.cyan.b, 0.3), GameData.COL.cyan))
		b.pressed.connect(func():
			AudioManager.play_sfx("ui_click"); cb.call(val); queue_free(); get_parent().add_child(SettingsMenu.new()))
		row.add_child(b)
	return row
