extends Node
## Root state machine. Swaps top-level screens and hosts the World during a run.

var current: Node = null

func _ready() -> void:
	randomize()
	Events.request_scene.connect(_go)
	Events.run_ended.connect(func(win, results): _go("victory" if win else "gameover", results))
	_go("menu", {})

func _go(state: String, data: Dictionary) -> void:
	if current != null and is_instance_valid(current):
		current.queue_free()
	current = null
	match state:
		"menu":
			current = MainMenu.new()
			add_child(current)
		"station":
			current = Station.new()
			add_child(current)
		"game":
			var w := World.new()
			w.setup(data.get("mode", "normal"), data.get("character", "keeper"), int(data.get("stage", 0)))
			current = w
			add_child(w)
		"gameover":
			var s := GameOver.new()
			current = s
			add_child(s)
			s.setup(data)
		"victory":
			var s := Victory.new()
			current = s
			add_child(s)
			s.setup(data)
