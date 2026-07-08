extends Node
## Persistent profile (meta-progression + settings) as JSON in user://. Guarded against corruption.

const SAVE_PATH := "user://last_signal_save.json"

var data: Dictionary = {}
var settings: Dictionary = {}

func _default_data() -> Dictionary:
	return {
		"scrap": 0,
		"meta": {},                              # station upgrade id -> level
		"unlocks": {"scavenger": false},
		"stats": {"runs": 0, "kills": 0, "best_time": 0.0, "boss_kills": 0, "victories": 0, "playtime": 0.0},
		"seen_tutorial": false,
		"version": 1,
	}

func _default_settings() -> Dictionary:
	return {
		"master": 0.9, "music": 0.55, "sfx": 0.85,
		"shake": true, "damage_numbers": true, "flashes": true,
		"difficulty": "normal", "quality": "auto",
	}

func _ready() -> void:
	load_game()

func load_game() -> void:
	data = _default_data()
	settings = _default_settings()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	# merge defensively so missing keys always exist
	if parsed.has("save"):
		_merge(data, parsed["save"])
	if parsed.has("settings"):
		_merge(settings, parsed["settings"])

func _merge(base: Dictionary, incoming: Dictionary) -> void:
	for k in incoming.keys():
		if base.has(k) and typeof(base[k]) == TYPE_DICTIONARY and typeof(incoming[k]) == TYPE_DICTIONARY:
			_merge(base[k], incoming[k])
		else:
			base[k] = incoming[k]

func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("LAST SIGNAL: could not open save file for writing")
		return
	f.store_string(JSON.stringify({"save": data, "settings": settings}, "\t"))
	f.close()

func save_settings() -> void:
	save_game()
	Events.settings_changed.emit()

# ---- convenience ----
func add_scrap(n: int) -> void:
	data.scrap = max(0, int(data.scrap) + n)
	save_game()

func meta_level(id: String) -> int:
	return int(data.meta.get(id, 0))

func set_meta_level(id: String, lvl: int) -> void:
	data.meta[id] = lvl
	save_game()

func reset_progress() -> void:
	var keep := settings
	data = _default_data()
	settings = keep
	save_game()
