class_name MainMenu
extends Control
## Title screen: Start, Endless, Station, Settings, Quit.

func _ready() -> void:
	UI.fullrect(self)
	AudioManager.play_music("menu")

	var bg := ColorRect.new()
	bg.color = Color("#070b12")
	UI.fullrect(bg)
	add_child(bg)

	var center := CenterContainer.new()
	UI.fullrect(center)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	center.add_child(vb)

	var title := UI.label("LAST SIGNAL", 66, GameData.COL.cyan)
	vb.add_child(title)
	vb.add_child(UI.label("Hold the last transmission against the dark.", 16, GameData.COL.ink2))
	vb.add_child(_spacer(18))

	var play := UI.button("▶   Start Game", GameData.COL.cyan)
	play.pressed.connect(_on_play)
	vb.add_child(play)

	var wins := int(SaveSystem.data.stats.victories)
	var endless := UI.button("∞   Endless" if wins > 0 else "∞   Endless (win to unlock)", GameData.COL.purple)
	endless.disabled = wins <= 0
	endless.pressed.connect(func(): Events.request_scene.emit("game", {"mode": "endless", "character": "keeper", "stage": 2}))
	vb.add_child(endless)

	var station := UI.button("Station  ◆ " + Util.fmt_num(SaveSystem.data.scrap), GameData.COL.scrap)
	station.pressed.connect(func(): Events.request_scene.emit("station", {}))
	vb.add_child(station)

	var settings := UI.button("Settings", GameData.COL.steel)
	settings.pressed.connect(_on_settings)
	vb.add_child(settings)

	var quit := UI.button("Quit", GameData.COL.ink3)
	quit.pressed.connect(func(): get_tree().quit())
	vb.add_child(quit)

	var foot := UI.label("Best %s   ·   %d wins   ·   WASD / arrows to move   ·   weapons auto-fire" %
		[Util.fmt_time(SaveSystem.data.stats.best_time), wins], 12, GameData.COL.ink3)
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_top = -34
	foot.offset_bottom = -14
	add_child(foot)

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _on_play() -> void:
	AudioManager.play_sfx("ui_click")
	Events.request_scene.emit("game", {"mode": SaveSystem.settings.get("difficulty", "normal"), "character": "keeper", "stage": 0})

func _on_settings() -> void:
	AudioManager.play_sfx("ui_click")
	var s := SettingsMenu.new()
	add_child(s)
