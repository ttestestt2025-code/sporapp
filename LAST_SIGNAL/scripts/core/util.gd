class_name Util
extends RefCounted
## Stateless helpers: RNG sugar, weighted selection, formatting.

static func rr(a: float, b: float) -> float:
	return a + randf() * (b - a)

static func ri(a: int, b: int) -> int:
	return randi_range(a, b)

static func chance(p: float) -> bool:
	return randf() < p

static func pick(arr: Array):
	return arr[randi() % arr.size()] if arr.size() > 0 else null

static func weighted_pick(items: Array, weight_fn: Callable):
	var total := 0.0
	for it in items:
		total += maxf(0.0, weight_fn.call(it))
	if total <= 0.0:
		return items[randi() % items.size()]
	var r := randf() * total
	for it in items:
		r -= maxf(0.0, weight_fn.call(it))
		if r <= 0.0:
			return it
	return items[items.size() - 1]

static func shuffle(arr: Array) -> Array:
	for i in range(arr.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var t = arr[i]; arr[i] = arr[j]; arr[j] = t
	return arr

static func fmt_time(sec: float) -> String:
	var s := int(maxf(0.0, sec))
	return "%d:%02d" % [s / 60, s % 60]

static func fmt_num(n: float) -> String:
	if n >= 1000000.0:
		return "%.1fM" % (n / 1000000.0)
	if n >= 10000.0:
		return "%dk" % int(n / 1000.0)
	if n >= 1000.0:
		return "%.1fk" % (n / 1000.0)
	return str(int(n))
