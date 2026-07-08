extends Node
## Content registry + balance constants + InputMap setup. The runtime source of truth for design data.

const RARITY := {
	"common":    {"name": "Common",    "color": Color("#c9d3e6"), "weight": 100.0},
	"uncommon":  {"name": "Uncommon",  "color": Color("#79f04b"), "weight": 45.0},
	"rare":      {"name": "Rare",      "color": Color("#33b6ff"), "weight": 18.0},
	"epic":      {"name": "Epic",      "color": Color("#b06bff"), "weight": 6.0},
	"legendary": {"name": "Legendary", "color": Color("#ffd24a"), "weight": 1.5},
}

const DIFFICULTY := {
	"normal":  {"hp": 1.0, "dmg": 1.0, "spawn": 1.0, "scrap": 1.0},
	"hard":    {"hp": 1.4, "dmg": 1.3, "spawn": 1.2, "scrap": 1.25},
	"endless": {"hp": 1.0, "dmg": 1.0, "spawn": 1.1, "scrap": 1.15},
}

const COL := {
	"cyan": Color("#33e1c8"), "orange": Color("#ff7a3c"), "yellow": Color("#ffd24a"),
	"red": Color("#ff4d5e"), "green": Color("#79f04b"), "purple": Color("#b06bff"),
	"pink": Color("#ff5fae"), "steel": Color("#8fb3d9"), "white": Color("#eaf2ff"),
	"hp": Color("#ff4d5e"), "xp": Color("#33e1c8"), "scrap": Color("#ffd24a"),
	"ink": Color("#eaf2ff"), "ink2": Color("#93a4c0"), "ink3": Color("#5b6b86"),
}

var weapons: Dictionary = {}       # id -> WeaponData
var passives: Dictionary = {}      # id -> PassiveData
var enemies: Dictionary = {}       # id -> EnemyData
var stages: Array = []             # StageData
var meta_upgrades: Array = []      # Station shop entries
var weapon_ids: Array = []
var passive_ids: Array = []
var _tex_cache: Dictionary = {}

func _ready() -> void:
	_setup_input()
	_build_weapons()
	_build_passives()
	_build_enemies()
	_build_stages()
	_build_meta()
	weapon_ids = weapons.keys()
	passive_ids = passives.keys()

static func xp_cost(n: int) -> int:
	return int(round(5 + n * 10 + pow(n, 1.55)))

func get_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if _tex_cache.has(path):
		return _tex_cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	_tex_cache[path] = tex
	return tex

# ---------------------------------------------------------------- input
func _setup_input() -> void:
	_add_action("move_up", [KEY_W, KEY_UP])
	_add_action("move_down", [KEY_S, KEY_DOWN])
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("pause", [KEY_ESCAPE, KEY_P])
	_add_action("confirm", [KEY_ENTER, KEY_SPACE, KEY_KP_ENTER])
	_add_action("restart", [KEY_R])
	_add_action("ui_pick_1", [KEY_1, KEY_KP_1])
	_add_action("ui_pick_2", [KEY_2, KEY_KP_2])
	_add_action("ui_pick_3", [KEY_3, KEY_KP_3])

func _add_action(name: String, keys: Array) -> void:
	if InputMap.has_action(name):
		return
	InputMap.add_action(name)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(name, e)

# ---------------------------------------------------------------- weapons
func _w(id, nm, type, color, rarity, desc, dmg, cd, count, pierce, speed, pr, extra, tex := "") -> WeaponData:
	var w := WeaponData.new()
	w.id = id; w.display_name = nm; w.type = type; w.color = color; w.rarity = rarity; w.desc = desc
	w.dmg = dmg; w.cd = cd; w.count = count; w.pierce = pierce
	w.speed = speed; w.proj_radius = pr; w.extra = extra; w.texture_path = tex
	weapons[id] = w
	return w

func _build_weapons() -> void:
	_w("energy_rifle", "Energy Rifle", "bolt", COL.cyan, "common",
		"Auto-fires energy bolts at the nearest target.",
		[10,14,18,23,29,35,41,46], [0.85,0.82,0.79,0.76,0.72,0.68,0.64,0.58],
		[1,1,2,2,2,3,3,3], [0,0,0,1,1,1,2,2], 480.0, 6.0, {})
	_w("plasma_rifle", "Plasma Rifle", "splash", COL.orange, "uncommon",
		"Heavy plasma slug that bursts on impact.",
		[16,22,28,35,42,50,55,60], [1.2,1.15,1.1,1.05,1.0,0.95,0.9,0.85],
		[1,1,1,2,2,2,3,3], [0,0,0,0,0,0,0,0], 380.0, 9.0,
		{"radius": [36,40,44,50,56,62,68,76]})
	_w("shock_wave", "Shock Wave", "ring", COL.yellow, "uncommon",
		"Releases an expanding ring that batters nearby foes.",
		[14,20,26,32,40,48,54,58], [2.1,2.0,1.9,1.8,1.7,1.6,1.5,1.4],
		[1,1,1,1,1,1,1,1], [0,0,0,0,0,0,0,0], 0.0, 0.0,
		{"radius": [90,100,110,122,135,150,165,180], "knock": [100,110,120,130,145,160,175,190]})
	_w("pulse_wave", "Pulse Wave", "pulse", COL.cyan, "common",
		"A rhythmic defensive burst that slows the horde.",
		[12,17,22,27,33,39,44,48], [1.8,1.7,1.6,1.5,1.4,1.3,1.2,1.1],
		[1,1,1,1,1,1,1,1], [0,0,0,0,0,0,0,0], 0.0, 0.0,
		{"radius": [80,90,100,110,122,135,150,165], "slow": [0.35,0.38,0.4,0.42,0.45,0.48,0.5,0.55], "slow_dur": [1.0,1.1,1.2,1.3,1.5,1.7,1.9,2.2]})
	_w("drone_companion", "Drone Companion", "orbit", COL.steel, "rare",
		"Deploys drones that orbit you and fire on foes.",
		[8,11,14,17,20,24,27,30], [0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.6],
		[1,2,2,3,3,4,4,5], [0,0,0,0,0,0,0,0], 420.0, 5.0,
		{"orbit_r": [56,62,68,74,80,86,92,100], "fire_cd": [0.7,0.66,0.62,0.58,0.54,0.5,0.46,0.4]})
	_w("energy_mine", "Energy Mine", "mine", COL.red, "uncommon",
		"Drops proximity mines that detonate on contact.",
		[30,42,54,66,80,95,108,120], [1.7,1.65,1.6,1.5,1.4,1.3,1.2,1.1],
		[1,1,2,2,3,3,4,5], [0,0,0,0,0,0,0,0], 0.0, 0.0,
		{"radius": [60,66,72,80,90,100,110,120]})
	_w("laser_beam", "Laser Beam", "beam", COL.pink, "epic",
		"A sweeping continuous beam that pierces everything.",
		[6,8,10,12,15,18,21,26], [0,0,0,0,0,0,0,0],
		[1,1,1,1,1,1,1,1], [0,0,0,0,0,0,0,0], 0.0, 0.0,
		{"length": [220,240,260,285,310,340,370,410], "width": [12,14,16,18,21,24,27,30], "tick": [0.16,0.15,0.14,0.13,0.12,0.11,0.1,0.09], "sweep": [0.5,0.55,0.6,0.65,0.7,0.78,0.86,1.0]})
	_w("nano_swarm", "Nano Swarm", "homing", COL.green, "rare",
		"Releases homing nanite shards that chase targets.",
		[7,10,13,17,21,25,28,32], [1.1,1.05,1.0,0.95,0.9,0.85,0.8,0.72],
		[2,2,3,3,4,5,6,7], [0,0,0,1,1,1,2,2], 300.0, 5.0,
		{"turn": [3.0,3.2,3.4,3.6,3.9,4.2,4.5,5.0]})

# ---------------------------------------------------------------- passives
func _p(id, nm, color, maxl, rarity, desc, stat, per, mode := "add", flag := "") -> PassiveData:
	var p := PassiveData.new()
	p.id = id; p.display_name = nm; p.color = color; p.max_level = maxl; p.rarity = rarity
	p.desc = desc; p.stat = stat; p.per_level = per; p.mode = mode; p.flag = flag
	passives[id] = p
	return p

func _build_passives() -> void:
	_p("overclock", "Overclock", COL.yellow, 5, "uncommon", "-6% weapon cooldowns", "cd_mul", 0.06, "mul_reduce")
	_p("power_cell", "Power Cell", COL.orange, 5, "uncommon", "+8% damage", "power_mul", 0.08)
	_p("servo_legs", "Servo Legs", COL.green, 5, "common", "+8% move speed", "move_mul", 0.08)
	_p("targeting_ai", "Targeting AI", COL.cyan, 5, "rare", "+4% crit chance", "crit_chance_add", 0.04)
	_p("hollow_points", "Hollow Points", COL.red, 5, "rare", "+15% crit damage", "crit_dmg_add", 0.15)
	_p("nanoweave", "Nanoweave", COL.hp, 5, "common", "+12% max HP", "max_hp_mul", 0.12)
	_p("repair_nanites", "Repair Nanites", COL.green, 5, "rare", "+0.4 HP/sec", "regen_add", 0.4)
	_p("capacitor", "Capacitor", COL.cyan, 3, "epic", "+1 projectile", "count_add", 1.0)
	_p("magnetic_coil", "Magnetic Coil", COL.steel, 5, "common", "+30% pickup radius", "pickup_mul", 0.30)
	_p("amplifier", "Amplifier", COL.purple, 5, "uncommon", "+10% area", "area_mul", 0.10)
	_p("railgun_coils", "Railgun Coils", COL.cyan, 5, "common", "+12% projectile speed", "proj_speed_mul", 0.12)
	_p("salvager", "Salvager", COL.xp, 5, "uncommon", "+15% fragment gain", "frag_mul", 0.15)
	_p("scrap_magnet", "Scrap Magnet", COL.scrap, 5, "uncommon", "+15% Scrap gain", "scrap_mul", 0.15)
	_p("reinforced_plating", "Reinforced Plating", COL.steel, 5, "uncommon", "+1 armor", "armor_add", 1.0)
	_p("kinetic_dampener", "Kinetic Dampener", COL.purple, 5, "rare", "+6% damage reduction", "dr_add", 0.06)
	_p("reactive_shield", "Reactive Shield", COL.cyan, 3, "epic", "+1 shield charge", "shield_add", 1.0, "add", "shield")
	_p("volatile_rounds", "Volatile Rounds", COL.orange, 1, "legendary", "Kills trigger a plasma burst", "none", 0.0, "add", "volatile")

# ---------------------------------------------------------------- enemies
func _e(id, nm, hp, spd, dmg, r, xp, behavior, color, shape, elite, extra := {}) -> EnemyData:
	var e := EnemyData.new()
	e.id = id; e.display_name = nm; e.hp = hp; e.speed = spd; e.damage = dmg; e.radius = r
	e.xp = xp; e.behavior = behavior; e.color = color; e.shape = shape; e.elite = elite; e.extra = extra
	e.texture_path = "res://assets/sprites/enemies/" + id + ".png"
	enemies[id] = e
	return e

func _build_enemies() -> void:
	_e("corrupted_walker", "Corrupted Walker", 12, 46, 6, 11, 1, "chase", COL.steel, "blob", false)
	_e("shadow_crawler", "Shadow Crawler", 8, 96, 5, 8, 1, "weave", COL.purple, "crawler", false)
	_e("mutated_brute", "Mutated Brute", 70, 34, 14, 19, 5, "chase", Color("#c06a3a"), "brute", true)
	_e("sparker", "Sparker", 18, 42, 8, 11, 5, "ranged", COL.cyan, "sparker", false,
		{"range": 300, "fire_cd": 2.0, "proj_speed": 170, "proj_dmg": 8, "burst": 1})
	_e("ruptor", "Ruptor", 20, 72, 20, 11, 5, "bomber", COL.orange, "ruptor", false,
		{"explode_r": 64, "explode_dmg": 22})

# ---------------------------------------------------------------- stages
func _stage(idx, nm, music, palette, base_rate, grow, elite_every, elite_id, spawns, boss) -> StageData:
	var s := StageData.new()
	s.index = idx; s.display_name = nm; s.music = music; s.palette = palette
	s.base_rate = base_rate; s.rate_grow = grow; s.elite_every = elite_every; s.elite_id = elite_id
	s.spawns = spawns; s.boss = boss
	stages.append(s)
	return s

func _build_stages() -> void:
	_stage(0, "Abandoned City", "stage1",
		{"bg": Color("#0a0f16"), "grid": Color(0.35,0.5,0.7,0.06), "accent": COL.orange, "fog": Color(0.5,0.4,0.3,0.04)},
		1.1, 0.028, 32.0, "mutated_brute",
		[{"enemy":"corrupted_walker","s":0,"e":300,"w":60},{"enemy":"shadow_crawler","s":18,"e":300,"w":45},
		 {"enemy":"sparker","s":60,"e":300,"w":22},{"enemy":"mutated_brute","s":110,"e":300,"w":10}],
		{"id":"corrupted_colossus","name":"Corrupted Colossus","hp":2600,"radius":46,"speed":44,"contact":18,"color":Color("#c06a3a"),
		 "phases":[
			{"at":1.0,"spd":44,"attacks":[{"type":"summon","cd":5.5,"enemy":"corrupted_walker","count":4},{"type":"aimed","cd":2.4,"count":1,"proj_dmg":12,"proj_speed":190},{"type":"dash","cd":6.0,"speed":380,"windup":0.7}]},
			{"at":0.5,"spd":52,"attacks":[{"type":"summon","cd":4.0,"enemy":"shadow_crawler","count":5},{"type":"radial","cd":3.4,"count":12,"proj_dmg":12,"proj_speed":170},{"type":"dash","cd":4.5,"speed":430,"windup":0.55}]}]})
	_stage(1, "Destroyed Research Facility", "stage2",
		{"bg": Color("#0a140f"), "grid": Color(0.4,0.7,0.5,0.06), "accent": COL.green, "fog": Color(0.3,0.6,0.3,0.05)},
		1.5, 0.034, 30.0, "mutated_brute",
		[{"enemy":"shadow_crawler","s":0,"e":300,"w":50},{"enemy":"corrupted_walker","s":0,"e":120,"w":25},
		 {"enemy":"sparker","s":40,"e":300,"w":28},{"enemy":"ruptor","s":70,"e":300,"w":24},{"enemy":"mutated_brute","s":120,"e":300,"w":10}],
		{"id":"facility_warden","name":"Facility Warden","hp":4600,"radius":48,"speed":52,"contact":22,"color":Color("#4de08a"),
		 "phases":[
			{"at":1.0,"spd":52,"attacks":[{"type":"radial","cd":3.0,"count":14,"proj_dmg":14,"proj_speed":180},{"type":"dash","cd":4.5,"speed":460,"windup":0.7},{"type":"aimed","cd":2.2,"count":3,"spread":0.3,"proj_dmg":12,"proj_speed":210}]},
			{"at":0.3,"spd":66,"attacks":[{"type":"radial","cd":2.0,"count":20,"proj_dmg":16,"proj_speed":210},{"type":"summon","cd":5.0,"enemy":"sparker","count":2},{"type":"pulse","cd":5.0,"radius":200,"dmg":26,"telegraph":1.0}]}]})
	_stage(2, "Corrupted Communication Tower", "stage3",
		{"bg": Color("#0d0916"), "grid": Color(0.6,0.4,0.9,0.06), "accent": COL.purple, "fog": Color(0.5,0.3,0.8,0.05)},
		1.9, 0.04, 26.0, "mutated_brute",
		[{"enemy":"shadow_crawler","s":0,"e":300,"w":40},{"enemy":"sparker","s":30,"e":300,"w":28},
		 {"enemy":"ruptor","s":0,"e":300,"w":30},{"enemy":"mutated_brute","s":140,"e":300,"w":9},{"enemy":"corrupted_walker","s":0,"e":300,"w":20}],
		{"id":"signal_devourer","name":"The Signal Devourer","hp":9000,"radius":52,"speed":40,"contact":26,"color":COL.purple,
		 "phases":[
			{"at":1.0,"spd":40,"attacks":[{"type":"radial","cd":3.2,"count":16,"proj_dmg":14,"proj_speed":175},{"type":"aimed","cd":2.4,"count":3,"spread":0.35,"proj_dmg":14,"proj_speed":220}]},
			{"at":0.66,"spd":46,"attacks":[{"type":"summon","cd":6.0,"enemy":"ruptor","count":2},{"type":"radial","cd":2.8,"count":20,"proj_dmg":15,"proj_speed":190,"spin":0.4},{"type":"dash","cd":4.5,"speed":500,"windup":0.6}]},
			{"at":0.33,"spd":52,"attacks":[{"type":"radial","cd":2.2,"count":24,"proj_dmg":16,"proj_speed":210,"spin":0.6},{"type":"summon","cd":5.0,"enemy":"sparker","count":3},{"type":"pulse","cd":4.5,"radius":240,"dmg":30,"telegraph":1.1}]}]})

# ---------------------------------------------------------------- meta (Station shop)
func _build_meta() -> void:
	meta_upgrades = [
		{"id":"power","name":"Power Core","desc":"+5% damage","max":5,"base":100,"growth":1.6,"color":COL.orange},
		{"id":"vitality","name":"Vitality","desc":"+10 Max HP","max":5,"base":90,"growth":1.6,"color":COL.hp},
		{"id":"servos","name":"Servos","desc":"+4% move speed","max":5,"base":90,"growth":1.6,"color":COL.green},
		{"id":"plating","name":"Plating","desc":"+1 armor","max":5,"base":140,"growth":1.7,"color":COL.steel},
		{"id":"fortune","name":"Fortune","desc":"+5% luck","max":5,"base":120,"growth":1.6,"color":COL.purple},
		{"id":"avarice","name":"Avarice","desc":"+8% Scrap gain","max":5,"base":110,"growth":1.55,"color":COL.scrap},
		{"id":"insight","name":"Insight","desc":"+5% fragment gain","max":5,"base":120,"growth":1.6,"color":COL.cyan},
		{"id":"recovery","name":"Recovery","desc":"+0.3 HP/sec","max":3,"base":200,"growth":1.9,"color":COL.green},
		{"id":"reboot","name":"Reboot","desc":"+1 auto-revive","max":2,"base":600,"growth":2.4,"color":COL.yellow},
		{"id":"magnetics","name":"Magnetics","desc":"+20% pickup radius","max":3,"base":120,"growth":1.7,"color":COL.steel},
	]
