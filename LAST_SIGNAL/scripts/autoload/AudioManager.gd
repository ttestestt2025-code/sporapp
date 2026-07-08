extends Node
## Music + throttled SFX playback from synthesized .wav assets. Silent-safe if assets are missing.

const MUSIC_DIR := "res://audio/music/"
const SFX_DIR := "res://audio/sfx/"
const THROTTLE := {
	"shoot": 0.05, "hit": 0.035, "enemy_die": 0.045, "pickup": 0.05,
	"scrap": 0.06, "boss_hit": 0.05, "player_hurt": 0.2, "nova": 0.14,
}

var _music: AudioStreamPlayer
var _sfx_players: Array = []
var _sfx_index := 0
var _current_track := ""
var _last_played: Dictionary = {}
var _stream_cache: Dictionary = {}

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = "Master"
	add_child(_music)
	_music.finished.connect(_on_music_finished)
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)
	apply_settings()

func apply_settings() -> void:
	_update_music_volume()

func _update_music_volume() -> void:
	var s := SaveSystem.settings
	var v: float = float(s.get("master", 0.9)) * float(s.get("music", 0.55))
	_music.volume_db = linear_to_db(max(0.0001, v))

func _stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]
	var st: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_stream_cache[path] = st
	return st

func play_music(track: String) -> void:
	if track == _current_track and _music.playing:
		return
	_current_track = track
	var st := _stream(MUSIC_DIR + track + ".wav")
	if st == null:
		_music.stop()
		return
	if st is AudioStreamWAV:
		(st as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music.stream = st
	_update_music_volume()
	_music.play()

func stop_music() -> void:
	_current_track = ""
	_music.stop()

func _on_music_finished() -> void:
	# Fallback loop for non-looping streams.
	if _current_track != "" and _music.stream != null:
		_music.play()

func play_sfx(name: String, volume_scale: float = 1.0) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var gap: float = THROTTLE.get(name, 0.03)
	if _last_played.has(name) and now - _last_played[name] < gap:
		return
	_last_played[name] = now
	var st := _stream(SFX_DIR + name + ".wav")
	if st == null:
		return
	var s := SaveSystem.settings
	var v: float = float(s.get("master", 0.9)) * float(s.get("sfx", 0.85)) * volume_scale
	var p: AudioStreamPlayer = _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	p.stream = st
	p.volume_db = linear_to_db(max(0.0001, v))
	p.pitch_scale = randf_range(0.95, 1.05)
	p.play()
