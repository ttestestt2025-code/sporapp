class_name SpatialGrid
extends RefCounted
## Uniform spatial hash for collision broad-phase. Rebuilt each physics tick.
## Stored objects must expose a `position: Vector2` property.

var cell: int
var _map: Dictionary = {}

func _init(c: int = 72) -> void:
	cell = c

func clear() -> void:
	_map.clear()

func _key(cx: int, cy: int) -> int:
	return (cx * 73856093) ^ (cy * 19349663)

func insert(o) -> void:
	var k := _key(int(o.position.x / cell), int(o.position.y / cell))
	if _map.has(k):
		_map[k].append(o)
	else:
		_map[k] = [o]

## Returns candidate objects whose cells overlap the circle (broad-phase only).
func query_circle(x: float, y: float, r: float) -> Array:
	var out: Array = []
	var minx := int((x - r) / cell)
	var maxx := int((x + r) / cell)
	var miny := int((y - r) / cell)
	var maxy := int((y + r) / cell)
	for cx in range(minx, maxx + 1):
		for cy in range(miny, maxy + 1):
			var k := _key(cx, cy)
			if _map.has(k):
				out.append_array(_map[k])
	return out
