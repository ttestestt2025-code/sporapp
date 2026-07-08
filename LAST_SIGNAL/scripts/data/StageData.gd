class_name StageData
extends Resource
## Declarative stage: palette, weighted spawn windows, elite cadence, and boss definition.

@export var index: int = 0
@export var display_name: String
@export var duration: float = 300.0
@export var music: String = "stage1"
@export var palette: Dictionary = {}       # {bg, grid, accent, fog}
@export var base_rate: float = 1.1
@export var rate_grow: float = 0.028
@export var elite_every: float = 32.0
@export var elite_id: String = "mutated_brute"
@export var spawns: Array = []             # [{enemy, s, e, w}]
@export var boss: Dictionary = {}          # {id, name, hp, radius, speed, contact, color, phases:[...]}
@export var background_path: String = ""
