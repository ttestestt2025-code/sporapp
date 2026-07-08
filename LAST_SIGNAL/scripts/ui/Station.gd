class_name Station
extends Control
## Meta-progression shop — spend Scrap on permanent upgrades.

var _scrap_label: Label
var _grid: GridContainer

func _ready() -> void:
	UI.fullrect(self)
	var bg := ColorRect.new(); bg.color = Color("#080d15"); UI.fullrect(bg); add_child(bg)

	var title := UI.label("THE STATION", 30, GameData.COL.scrap)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); title.offset_top = 18; title.offset_bottom = 54
	add_child(title)

	_scrap_label = UI.label("◆ " + Util.fmt_num(SaveSystem.data.scrap), 18, GameData.COL.scrap)
	_scrap_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); _scrap_label.offset_top = 54; _scrap_label.offset_bottom = 80
	add_child(_scrap_label)

	var center := CenterContainer.new(); UI.fullrect(center); center.offset_top = 90; add_child(center)
	_grid = GridContainer.new(); _grid.columns = 2; _grid.add_theme_constant_override("h_separation", 12); _grid.add_theme_constant_override("v_separation", 10)
	center.add_child(_grid)
	_rebuild()

	var back := UI.button("‹  Back", GameData.COL.steel, Vector2(140, 40), 15)
	back.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT); back.offset_left = 16; back.offset_top = -56; back.offset_bottom = -16
	back.pressed.connect(func(): AudioManager.play_sfx("ui_click"); Events.request_scene.emit("menu", {}))
	add_child(back)

func _rebuild() -> void:
	for c in _grid.get_children():
		c.queue_free()
	for item in GameData.meta_upgrades:
		_grid.add_child(_make_card(item))
	_scrap_label.text = "◆ " + Util.fmt_num(SaveSystem.data.scrap)

func _make_card(item: Dictionary) -> Control:
	var lvl := SaveSystem.meta_level(item.id)
	var maxed: bool = lvl >= int(item.max)
	var cost := int(round(item.base * pow(item.growth, lvl)))
	var afford: bool = SaveSystem.data.scrap >= cost and not maxed

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI._sb(Color("#111826"), Color(item.color.r, item.color.g, item.color.b, 0.6), 1, 8))
	panel.custom_minimum_size = Vector2(320, 74)
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 10); panel.add_child(h)
	var info := VBoxContainer.new(); info.custom_minimum_size = Vector2(200, 0); h.add_child(info)
	info.add_child(UI.label(item.name, 15, GameData.COL.ink))
	info.add_child(UI.label(item.desc + "   (%d/%d)" % [lvl, item.max], 12, GameData.COL.ink2))
	var buy := UI.button(("MAX" if maxed else "◆ %d" % cost), item.color, Vector2(96, 40), 13)
	buy.disabled = not afford
	buy.pressed.connect(func():
		if SaveSystem.data.scrap >= cost and not maxed:
			SaveSystem.add_scrap(-cost)
			SaveSystem.set_meta_level(item.id, lvl + 1)
			AudioManager.play_sfx("cache")
			_rebuild())
	h.add_child(buy)
	return panel
