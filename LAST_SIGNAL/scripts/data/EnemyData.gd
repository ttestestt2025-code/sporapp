class_name EnemyData
extends Resource
## Declarative enemy archetype. Enemy.gd switches on `behavior`.

@export var id: String
@export var display_name: String
@export var hp: float = 10.0
@export var speed: float = 46.0
@export var damage: float = 6.0
@export var radius: float = 11.0
@export var xp: float = 1.0
@export var behavior: String = "chase"   # chase | weave | ranged | bomber | boss
@export var color: Color = Color.WHITE
@export var shape: String = "blob"        # blob | crawler | brute | sparker | ruptor | boss
@export var elite: bool = false
@export var extra: Dictionary = {}        # ranged/bomber params
@export var texture_path: String = ""
