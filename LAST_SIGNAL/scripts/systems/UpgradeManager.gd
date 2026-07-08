class_name UpgradeManager
extends RefCounted
## Builds weighted level-up choices and applies the selected card.

static func offers(world, player, count := 3) -> Array:
	var cands: Array = []
	for id in player.weapons.keys():
		var w: WeaponData = GameData.weapons[id]
		if player.weapons[id] < w.max_level:
			cands.append(_mk("weapon", id, w.display_name, w.color, w.rarity, w.desc, player.weapons[id], false))
	for id in player.passives.keys():
		var p: PassiveData = GameData.passives[id]
		if player.passives[id] < p.max_level:
			cands.append(_mk("passive", id, p.display_name, p.color, p.rarity, p.desc, player.passives[id], false))
	if player.weapons.size() < 6:
		for id in GameData.weapon_ids:
			if not player.weapons.has(id):
				var w: WeaponData = GameData.weapons[id]
				cands.append(_mk("weapon", id, w.display_name, w.color, w.rarity, w.desc, 0, true))
	if player.passives.size() < 6:
		for id in GameData.passive_ids:
			if not player.passives.has(id):
				var p: PassiveData = GameData.passives[id]
				cands.append(_mk("passive", id, p.display_name, p.color, p.rarity, p.desc, 0, true))

	var luck: float = player.stats.luck
	var chosen: Array = []
	var pool: Array = cands.duplicate()
	while chosen.size() < count and pool.size() > 0:
		var idx := _weighted_index(pool, luck)
		chosen.append(pool[idx])
		pool.remove_at(idx)
	while chosen.size() < count:
		chosen.append(_fallback(chosen.size()))
	return chosen

static func apply(card: Dictionary, world, player) -> void:
	match card.kind:
		"weapon": player.add_weapon(card.id)
		"passive": player.add_passive(card.id)
		"heal": player.heal(player.max_hp * 0.4)
		"scrap": world.run_scrap += 120

static func _mk(kind, id, nm, color, rarity, desc, cur_level, is_new) -> Dictionary:
	var prefix := "NEW · " if is_new else "Lv %d · " % (cur_level + 1)
	return {
		"kind": kind, "id": id, "name": nm, "color": color, "rarity": rarity,
		"letter": nm.substr(0, 1), "is_new": is_new, "level": cur_level + 1,
		"desc": prefix + desc,
	}

static func _fallback(i: int) -> Dictionary:
	if i % 2 == 0:
		return {"kind": "heal", "id": "heal", "name": "Repair", "color": GameData.COL.green, "rarity": "common", "letter": "+", "is_new": false, "level": 1, "desc": "Restore 40% HP"}
	return {"kind": "scrap", "id": "scrap", "name": "Scrap Cache", "color": GameData.COL.scrap, "rarity": "common", "letter": "$", "is_new": false, "level": 1, "desc": "+120 Scrap"}

static func _weighted_index(arr: Array, luck: float) -> int:
	var total := 0.0
	var weights: Array = []
	for c in arr:
		var rw: float = GameData.RARITY.get(c.rarity, {"weight": 40.0}).weight
		var boost := luck if (c.rarity == "rare" or c.rarity == "epic" or c.rarity == "legendary") else 1.0
		var wv := rw * boost * (0.8 if c.is_new else 1.0)
		weights.append(wv)
		total += wv
	var r := randf() * total
	for i in arr.size():
		r -= weights[i]
		if r <= 0.0:
			return i
	return arr.size() - 1
