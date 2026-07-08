class_name Victory
extends Control
## Victory results screen — the Last Signal is restored.

func setup(r: Dictionary) -> void:
	UI.fullrect(self)
	AudioManager.play_music("victory")
	var bg := ColorRect.new(); bg.color = Color("#06131a"); UI.fullrect(bg); add_child(bg)
	var center := CenterContainer.new(); UI.fullrect(center); add_child(center)
	var vb := VBoxContainer.new(); vb.alignment = BoxContainer.ALIGNMENT_CENTER; vb.add_theme_constant_override("separation", 8); center.add_child(vb)
	vb.add_child(UI.label("SIGNAL RESTORED", 52, GameData.COL.cyan))
	vb.add_child(UI.label("The transmission goes out. Somewhere, someone answers.", 15, GameData.COL.ink2))
	vb.add_child(_stat("Clear time", Util.fmt_time(r.get("time", 0))))
	vb.add_child(_stat("Level", str(r.get("level", 1))))
	vb.add_child(_stat("Kills", Util.fmt_num(r.get("kills", 0))))
	vb.add_child(_stat("Scrap earned", "◆ %s" % Util.fmt_num(r.get("scrap", 0))))
	vb.add_child(UI.label("Unlocked: Endless Mode  ·  The Scavenger", 13, GameData.COL.purple))
	vb.add_child(_spacer(12))
	var again := UI.button("▶  Play Again", GameData.COL.cyan)
	again.pressed.connect(func(): Events.request_scene.emit("game", {"mode": "normal", "character": r.get("character", "keeper"), "stage": 0}))
	vb.add_child(again)
	var endless := UI.button("∞  Endless", GameData.COL.purple)
	endless.pressed.connect(func(): Events.request_scene.emit("game", {"mode": "endless", "character": r.get("character", "keeper"), "stage": 2}))
	vb.add_child(endless)
	var menu := UI.button("Menu", GameData.COL.steel); menu.pressed.connect(func(): Events.request_scene.emit("menu", {})); vb.add_child(menu)

func _stat(k: String, v: String) -> Control:
	var h := HBoxContainer.new(); h.alignment = BoxContainer.ALIGNMENT_CENTER; h.add_theme_constant_override("separation", 10)
	var a := UI.label(k, 15, GameData.COL.ink2); a.custom_minimum_size = Vector2(160, 0); a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var b := UI.label(v, 15, GameData.COL.ink); b.custom_minimum_size = Vector2(160, 0); b.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	h.add_child(a); h.add_child(b); return h

func _spacer(h: int) -> Control:
	var c := Control.new(); c.custom_minimum_size = Vector2(0, h); return c
