class_name Pool
extends RefCounted
## Generic object pool. Pooled objects must expose a bool `active` property.
## `factory` returns a fresh object (typically a Node already added to the scene tree).

var _free: Array = []
var active: Array = []
var _factory: Callable
var _cap: int

func _init(factory: Callable, cap: int = 100000) -> void:
	_factory = factory
	_cap = cap

func count() -> int:
	return active.size()

func obtain():
	if active.size() >= _cap:
		return null
	var o = _free.pop_back() if _free.size() > 0 else _factory.call()
	o.active = true
	active.append(o)
	return o

func release(o) -> void:
	o.active = false

## Compact the active list once per frame; inactive objects return to the free list.
func sweep() -> void:
	var n := 0
	for i in active.size():
		var o = active[i]
		if o.active:
			active[n] = o
			n += 1
		else:
			if o.has_method("on_release"):
				o.on_release()
			_free.append(o)
	active.resize(n)

func clear_all() -> void:
	for o in active:
		o.active = false
		if o.has_method("on_release"):
			o.on_release()
		_free.append(o)
	active.clear()
