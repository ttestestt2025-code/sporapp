class_name PassiveData
extends Resource
## Declarative passive upgrade. The player folds these into derived stats each time the build changes.

@export var id: String
@export var display_name: String
@export var color: Color = Color.WHITE
@export var max_level: int = 5
@export var rarity: String = "common"
@export var desc: String = ""
@export var stat: String            # stat key modified in Player.compute_stats()
@export var per_level: float = 0.0  # amount applied per level
@export var mode: String = "add"    # add | mul_reduce (multiplicative reduction, e.g. cooldowns)
@export var flag: String = ""       # optional special flag (e.g. "volatile", "shield")
