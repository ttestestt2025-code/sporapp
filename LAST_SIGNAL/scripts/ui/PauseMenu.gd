class_name PauseMenu
extends Control
## Pause overlay: Resume, Settings, Abandon Run.

var world

func setup(world_ref) -> void:
	world = world_ref
	UI.fullrect(self)
	z_index = 95
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new(); dim.color = Color(0.02, 0.03, 0.05, 0.8); UI.fullrect(dim); add_child(dim)
	var center := CenterContainer.new(); UI.fullrect(center); add_child(center)
	var panel := PanelContainer.new(); panel.add_theme_stylebox_override("panel", UI.panel_style()); center.add_child(panel)
	var vb := VBoxContainer.new(); vb.add_theme_constant_override("separation", 12); panel.add_child(vb)
	vb.add_child(UI.label("PAUSED", 30, GameData.COL.cyan))
	var resume := UI.button("Resume", GameData.COL.cyan); resume.pressed.connect(func(): world.toggle_pause()); vb.add_child(resume)
	var settings := UI.button("Settings", GameData.COL.steel); settings.pressed.connect(func(): add_child(SettingsMenu.new())); vb.add_child(settings)
	var quit := UI.button("Abandon Run", GameData.COL.red); quit.pressed.connect(func(): AudioManager.play_sfx("ui_click"); world.quit_run()); vb.add_child(quit)
