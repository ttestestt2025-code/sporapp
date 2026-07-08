class_name WeaponData
extends Resource
## Declarative weapon definition. WeaponRunner interprets `type` and applies player multipliers.
## Per-level arrays are indexed [level-1]; use v() for safe access.

@export var id: String
@export var display_name: String
@export var type: String            # bolt | splash | ring | orbit | mine | beam | homing | pulse
@export var color: Color = Color.WHITE
@export var max_level: int = 8
@export var rarity: String = "common"
@export var desc: String = ""
@export var dmg: Array = []          # damage per level
@export var cd: Array = []           # cooldown seconds per level
@export var count: Array = []        # projectiles/blades/mines per level
@export var pierce: Array = []       # pierce per level
@export var speed: float = 470.0
@export var proj_radius: float = 7.0
@export var extra: Dictionary = {}   # type-specific: {radius:[], chains:[], slow:[], ...}
@export var texture_path: String = ""

func v(arr: Array, level: int) -> float:
	if arr.is_empty():
		return 0.0
	return float(arr[clampi(level - 1, 0, arr.size() - 1)])

func ev(key: String, level: int, fallback: float = 0.0) -> float:
	if extra.has(key):
		return v(extra[key], level)
	return fallback
