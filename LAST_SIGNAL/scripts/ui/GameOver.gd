class_name GameOver
extends Control
## Defeat results screen.

func setup(r: Dictionary) -> void:
	UI.fullrect(self)
	var bg := ColorRect.new(); bg.color = Color("#0a0407"); UI.fullrect(bg); add_child(bg)
	var center := CenterContainer.new(); UI.fullrect(center); add_child(center)
	var vb := VBoxContainer.new(); vb.alignment = BoxContainer.ALIGNMENT_CENTER; vb.add_theme_constant_override("separation", 8); center.add_child(vb)
	vb.add_child(UI.label("SIGNAL LOST", 54, GameData.COL.red))
	vb.add_child(UI.label("The station goes dark. But the Scrap you salvaged endures.", 15, GameData.COL.ink2))
	vb.add_child(_stat("Survived", Util.fmt_time(r.get("time", 0))))
	vb.add_child(_stat("Reached", "Sector %d" % r.get("stage", 1)))
	vb.add_child(_stat("Level", str(r.get("level", 1))))
	vb.add_child(_stat("Kills", Util.fmt_num(r.get("kills", 0))))
	vb.add_child(_stat("Scrap earned", "◆ %s" % Util.fmt_num(r.get("scrap", 0))))
	vb.add_child(_spacer(12))
	var retry := UI.button("↻  Try Again", GameData.COL.cyan)
	retry.pressed.connect(func(): Events.request_scene.emit("game", {"mode": r.get("mode", "normal"), "character": r.get("character", "keeper"), "stage": 2 if r.get("mode") == "endless" else 0}))
	vb.add_child(retry)
	var station := UI.button("Station", GameData.COL.scrap); station.pressed.connect(func(): Events.request_scene.emit("station", {})); vb.add_child(station)
	var menu := UI.button("Menu", GameData.COL.steel); menu.pressed.connect(func(): Events.request_scene.emit("menu", {})); vb.add_child(menu)

func _stat(k: String, v: String) -> Control:
	var h := HBoxContainer.new(); h.alignment = BoxContainer.ALIGNMENT_CENTER; h.add_theme_constant_override("separation", 10)
	var a := UI.label(k, 15, GameData.COL.ink2); a.custom_minimum_size = Vector2(160, 0); a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var b := UI.label(v, 15, GameData.COL.ink); b.custom_minimum_size = Vector2(160, 0); b.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	h.add_child(a); h.add_child(b); return h

func _spacer(h: int) -> Control:
	var c := Control.new(); c.custom_minimum_size = Vector2(0, h); return c
