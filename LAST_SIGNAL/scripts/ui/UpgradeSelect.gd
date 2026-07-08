class_name UpgradeSelect
extends Control
## Level-up overlay: three rarity-weighted choice cards. Click or press 1/2/3.

var world
var _cards: Array = []
var _row: HBoxContainer
var _title: Label

func setup(world_ref) -> void:
	world = world_ref
	UI.fullrect(self)
	z_index = 90
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new(); dim.color = Color(0.02, 0.03, 0.05, 0.8); UI.fullrect(dim); add_child(dim)
	var center := CenterContainer.new(); UI.fullrect(center); add_child(center)
	var vb := VBoxContainer.new(); vb.alignment = BoxContainer.ALIGNMENT_CENTER; vb.add_theme_constant_override("separation", 14); center.add_child(vb)
	_title = UI.label("LEVEL UP — choose an upgrade", 26, GameData.COL.cyan); vb.add_child(_title)
	_row = HBoxContainer.new(); _row.add_theme_constant_override("separation", 16); _row.alignment = BoxContainer.ALIGNMENT_CENTER; vb.add_child(_row)

func present(cards: Array) -> void:
	_cards = cards
	for c in _row.get_children():
		c.queue_free()
	for i in cards.size():
		_row.add_child(_make_card(cards[i], i))
	show()

func _make_card(card: Dictionary, index: int) -> Control:
	var rarity: Dictionary = GameData.RARITY.get(card.rarity, {"name": "Common", "color": Color.WHITE})
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI._sb(Color("#111826"), rarity.color, 2, 10))
	panel.custom_minimum_size = Vector2(210, 250)
	var vb := VBoxContainer.new(); vb.add_theme_constant_override("separation", 8); vb.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vb)

	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UI._sb(card.color, card.color, 0, 10))
	badge.custom_minimum_size = Vector2(64, 64)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bl := Label.new(); bl.text = card.letter; bl.add_theme_font_size_override("font_size", 34); bl.add_theme_color_override("font_color", Color(0, 0, 0, 0.75))
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(bl)
	vb.add_child(badge)

	vb.add_child(UI.label(str(rarity.name).to_upper(), 11, rarity.color))
	vb.add_child(UI.label(card.name, 16, GameData.COL.ink))
	var desc := UI.label(card.desc, 12, GameData.COL.ink2); desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; desc.custom_minimum_size = Vector2(186, 60)
	vb.add_child(desc)

	var btn := UI.button("Choose  [%d]" % (index + 1), rarity.color, Vector2(186, 40), 14)
	btn.pressed.connect(func(): _pick(card))
	vb.add_child(btn)
	return panel

func _pick(card: Dictionary) -> void:
	world.on_upgrade_pick(card)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	for i in min(3, _cards.size()):
		if event.is_action_pressed("ui_pick_%d" % (i + 1)):
			_pick(_cards[i])
			get_viewport().set_input_as_handled()
			return
