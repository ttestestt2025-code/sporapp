class_name Tutorial
extends Control
## First-run tutorial overlay. Pauses the world until dismissed, then never shows again.

var world

func setup(world_ref) -> void:
	world = world_ref
	UI.fullrect(self)
	z_index = 92
	mouse_filter = Control.MOUSE_FILTER_STOP
	world.paused = true
	var dim := ColorRect.new(); dim.color = Color(0.02, 0.03, 0.05, 0.82); UI.fullrect(dim); add_child(dim)
	var center := CenterContainer.new(); UI.fullrect(center); add_child(center)
	var panel := PanelContainer.new(); panel.add_theme_stylebox_override("panel", UI.panel_style()); center.add_child(panel)
	var vb := VBoxContainer.new(); vb.add_theme_constant_override("separation", 10); panel.add_child(vb)
	vb.add_child(UI.label("BRIEFING", 28, GameData.COL.cyan))
	var lines := [
		"You are the Signal Keeper. Move with WASD / arrows (or drag on touch).",
		"Your weapons fire automatically — focus on positioning and survival.",
		"Destroy the Corrupted to collect Energy Fragments and level up.",
		"On level-up, choose one of three upgrades to build your loadout.",
		"Survive each sector, defeat its boss, and restore the Last Signal.",
	]
	for l in lines:
		vb.add_child(UI.label(l, 14, GameData.COL.ink2))
	vb.add_child(_spacer(8))
	var go := UI.button("Begin", GameData.COL.cyan)
	go.pressed.connect(_dismiss)
	vb.add_child(go)

func _dismiss() -> void:
	AudioManager.play_sfx("ui_click")
	SaveSystem.data.seen_tutorial = true
	SaveSystem.save_game()
	world.paused = false
	queue_free()

func _spacer(h: int) -> Control:
	var c := Control.new(); c.custom_minimum_size = Vector2(0, h); return c
