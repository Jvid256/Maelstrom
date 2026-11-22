class_name HeroState
extends RefCounted
## One hero's state: equipment, carried items and growth. Each hero grows differently:
## the Oracleborn through visions (knowledge), the Engineer through levels and skills,
## Alysia through gun mastery and her standing with Pallas.

const HEROES := {
	"oracle": {
		"name": "The Oracleborn", "short": "Oracleborn", "method": "pillar",
		"base": {"hp": 32, "atk": 0, "armor": 0, "spd": 1.2, "fs": 2, "dodge": 0},
		"weights": ["light", "medium"],
		"start": {"weapon": "short_sword", "offhand": "round_shield", "body": "worn_leathers", "keepsake": "oracle_bead", "pack": "canvas_pack"},
		"sprite": "hero_oracleborn_sprite", "portrait": "hero_oracleborn_portrait",
		"growth": "visions",
		"about": "A fighter whose bloodline shows him the next few seconds and the deep past. He grows by reading the past of stabilized land.",
	},
	"engineer": {
		"name": "The Uncoded Engineer", "short": "Engineer", "method": "anchor",
		"base": {"hp": 28, "atk": 0, "armor": 0, "spd": 1.0, "fs": 0, "dodge": 0},
		"weights": ["light", "medium", "heavy"],
		"start": {"weapon": "field_wrench", "body": "lab_coat", "keepsake": "tower_badge", "implant": "swarm_seed", "construct": "turret_mk1", "pack": "tool_satchel", "belt": "field_kit"},
		"sprite": "hero_engineer_sprite", "portrait": "hero_engineer_portrait",
		"growth": "levels",
		"about": "A prodigy from a world whose laws don't match this one, carrying a bionic swarm. He grows through levels and skills, and pins land in place with anchors that need power.",
	},
	"gunslinger": {
		"name": "Alysia Ward", "short": "Alysia", "method": "tether",
		"base": {"hp": 26, "atk": 0, "armor": 0, "spd": 1.4, "fs": 0, "dodge": 0},
		"weights": ["light", "medium"],
		"start": {"python": "python", "glock": "glock", "energy": "energy_pistol", "body": "duster", "keepsake": "keris_tag", "pack": "saddlebag"},
		"sprite": "hero_alysia_sprite", "portrait": "hero_alysia_portrait",
		"growth": "mastery",
		"about": "A gunslinger from a desert that used to be New York, pulled into the Maelstrom with the Pallas mining station. Her guns improve with use, and Pallas's tethers hold land in place for parts.",
	},
}
const ORDER := ["oracle", "engineer", "gunslinger"]

## The Engineer's skill tree: branch -> ranks. Each rank costs one skill point.
const SKILLS := {
	"constructs": [
		{"name": "Field repair", "text": "Constructs deal +1 damage."},
		{"name": "Second mount", "text": "Opens the second construct slot."},
		{"name": "Overclock", "text": "Constructs act 30% faster."},
	],
	"swarm": [
		{"name": "Knitting", "text": "+6 Health, and the swarm closes wounds: +3 health after each fight won."},
		{"name": "Hardening", "text": "+1 Armor."},
		{"name": "Reflex loop", "text": "+0.2 Speed."},
	],
	"fugue": [
		{"name": "Lucid fugue", "text": "Fugue builds trigger in 40% of fights, and never backfire."},
		{"name": "Blueprints", "text": "Studied fugue builds become blueprints at the workbench."},
		{"name": "Overdrive", "text": "Fugue effects are doubled."},
	],
}
const XP_PER_LEVEL := 20
const MASTERY_STEP := 12  # shots fired per mastery rank
const MASTERY_MAX := 5

## Auto-combat behaviors (gambits) the player can toggle on the hero screen.
const BEHAVIORS := {
	"oracle": {
		"save_one": {"name": "Keep one Foresight in reserve", "text": "Never spends the last point in auto-combat.", "default": false},
		"dodge_small": {"name": "Dodge smaller hits", "text": "Spends Foresight on hits one point lighter than usual.", "default": false},
	},
	"engineer": {
		"patch_low": {"name": "Patch below 40%", "text": "Uses a draught when health falls under 40%.", "default": true},
		"fugue_on": {"name": "Allow fugue builds", "text": "Lets the fugue improvise constructs at the start of a fight. Unpredictable.", "default": true},
	},
	"gunslinger": {
		"match_ammo": {"name": "Match ammo to the enemy", "text": "Uses the Python when the equipped ammo suits the enemy.", "default": true},
		"python_armored": {"name": "Python against armor", "text": "Draws the Python against Armored enemies.", "default": true},
		"energy_charged": {"name": "Energy pistol when charged", "text": "Opens with the energy pistol when its charge is full.", "default": true},
	},
}

var id := "oracle"
var equipped := {}      # slot id -> item id
var inventory: Array = []
var visions: Array = []  # vision ids from Story.VISIONS (Oracleborn)
var unlocked: Array = []  # slots from Items.LOCKED that have opened
var injured := false
var behaviors := {}
# the Engineer
var xp := 0
var level := 1
var skill_points := 0
var skills := {"constructs": 0, "swarm": 0, "fugue": 0}
var blueprints: Array = []
# Alysia
var shots := {"python": 0, "glock": 0, "energy": 0}
var charge := 0


func _init(hero_id: String = "oracle") -> void:
	id = hero_id
	for slot in HEROES[id]["start"]:
		equipped[slot] = HEROES[id]["start"][slot]
	for b in BEHAVIORS[id]:
		behaviors[b] = BEHAVIORS[id][b]["default"]


func def() -> Dictionary:
	return HEROES[id]


func short_name() -> String:
	return HEROES[id]["short"]


func stats() -> Dictionary:
	var s := {"hp": 0, "atk": 0, "armor": 0, "spd": 1.0, "fs": 0, "dodge": 0, "step": 0.0, "fog": 0.0,
		"pack": 0, "supplies": 0, "hand": 0, "xp": 0, "charge": 0, "luck": 0.0, "power": 0, "parts": 0, "regen": 0}
	for k in HEROES[id]["base"]:
		s[k] = HEROES[id]["base"][k]
	for slot in equipped:
		var it: Dictionary = Items.item(equipped[slot])
		for k in it["stats"]:
			s[k] += it["stats"][k]
	for v in visions:
		var vs: Dictionary = Story.VISIONS[v].get("stats", {})
		for k in vs:
			s[k] += vs[k]
	if id == "engineer":
		s["hp"] += (level - 1) * 2
		if skills["swarm"] >= 1:
			s["hp"] += 6
		if skills["swarm"] >= 2:
			s["armor"] += 1
		if skills["swarm"] >= 3:
			s["spd"] += 0.2
	if id == "oracle":
		s["fs"] += int(Story.fx.get(id, {}).get("fs", 0))
	s["spd"] = maxf(0.5, s["spd"])
	s["hp"] = maxi(8, s["hp"])
	return s


func has_vision(vid: String) -> bool:
	return visions.has(vid)


# ------------------------------------------------------------------ gear
## Why an item can't go on, or "" if it can.
func cannot_equip(item_id: String) -> String:
	var it := Items.item(item_id)
	if not Items.usable_by(item_id, id):
		return "Not for %s." % short_name()
	if Items.LOCKED.has(it["slot"]) and not unlocked.has(it["slot"]):
		return "That slot isn't open yet: %s." % Items.LOCKED[it["slot"]].to_lower()
	if it["slot"] == "body" and not HEROES[id]["weights"].has(it.get("weight", "light")):
		return "Too heavy for %s." % short_name()
	return ""


## Equips an item from the inventory; whatever was in the slot goes back to the inventory.
func equip(item_id: String) -> String:
	var why := cannot_equip(item_id)
	if why != "":
		return why
	var slot: String = Items.item(item_id)["slot"]
	for pair in [["ring", "ring2"], ["implant", "implant2"], ["construct", "construct2"]]:
		if slot == pair[0] and equipped.has(pair[0]) and unlocked.has(pair[1]) and not equipped.has(pair[1]):
			slot = pair[1]
	inventory.erase(item_id)
	if equipped.has(slot):
		inventory.append(equipped[slot])
	equipped[slot] = item_id
	return ""


func unequip(slot: String) -> void:
	if equipped.has(slot):
		inventory.append(equipped[slot])
		equipped.erase(slot)


func give(item_id: String) -> void:
	inventory.append(item_id)


func has_item(item_id: String) -> bool:
	return inventory.has(item_id) or equipped.values().has(item_id)


func unlock_slot(slot: String) -> void:
	if not unlocked.has(slot):
		unlocked.append(slot)


## Equipped constructs (Engineer) as a list of construct dictionaries.
func constructs() -> Array:
	var out := []
	for slot in ["construct", "construct2"]:
		if equipped.has(slot):
			var c: Dictionary = Items.item(equipped[slot])["construct"].duplicate()
			if skills["constructs"] >= 1 and c.has("dmg"):
				c["dmg"] += 1
			var fx: Dictionary = Story.fx.get(id, {})
			if c.has("dmg"):
				c["dmg"] += int(fx.get("construct_dmg", 0))
			if fx.get("construct_fire", 0) > 0:
				c["fire"] = true
			if skills["constructs"] >= 3 and c.has("every"):
				c["every"] *= 0.7
			if fx.get("turret_fast", 0) > 0 and c.has("every"):
				c["every"] *= 0.75
			out.append(c)
	return out


## Alysia's guns: slot -> gun data with mastery folded in.
func guns() -> Dictionary:
	var out := {}
	for slot in ["python", "glock", "energy"]:
		if equipped.has(slot):
			var g: Dictionary = Items.item(equipped[slot])["gun"].duplicate()
			g["dmg"] += mastery(slot)
			out[slot] = g
	return out


func mastery(slot: String) -> int:
	return mini(MASTERY_MAX, int(shots.get(slot, 0)) / MASTERY_STEP)


func ammo() -> Dictionary:
	if equipped.has("ammo"):
		return Items.item(equipped["ammo"])["ammo"]
	return {}


# ------------------------------------------------------------------ growth (Engineer)
func xp_to_next() -> int:
	return XP_PER_LEVEL * level


## Adds XP; returns the number of levels gained.
func gain_xp(amount: int) -> int:
	if id != "engineer":
		return 0
	xp += amount + stats()["xp"]
	var gained := 0
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		skill_points += 1
		gained += 1
		if level >= 4:
			unlock_slot("implant2")
	return gained


func can_learn(branch: String) -> bool:
	return skill_points > 0 and skills[branch] < SKILLS[branch].size()


func learn(branch: String) -> void:
	if not can_learn(branch):
		return
	skill_points -= 1
	skills[branch] += 1
	if branch == "constructs" and skills[branch] >= 2:
		unlock_slot("construct2")


# ------------------------------------------------------------------ saving
func to_dict() -> Dictionary:
	return {"id": id, "equipped": equipped, "inventory": inventory, "visions": visions, "unlocked": unlocked,
		"injured": injured, "behaviors": behaviors, "xp": xp, "level": level, "skill_points": skill_points,
		"skills": skills, "blueprints": blueprints, "shots": shots, "charge": charge}


static func from_dict(d: Dictionary) -> HeroState:
	var h := HeroState.new(d.get("id", "oracle"))
	h.equipped = d.get("equipped", h.equipped)
	h.inventory = d.get("inventory", [])
	h.visions = d.get("visions", [])
	h.unlocked = d.get("unlocked", [])
	h.injured = d.get("injured", false)
	for b in d.get("behaviors", {}):
		h.behaviors[b] = d["behaviors"][b]
	h.xp = int(d.get("xp", 0))
	h.level = int(d.get("level", 1))
	h.skill_points = int(d.get("skill_points", 0))
	for k in d.get("skills", {}):
		h.skills[k] = int(d["skills"][k])
	h.blueprints = d.get("blueprints", [])
	for k in d.get("shots", {}):
		h.shots[k] = int(d["shots"][k])
	h.charge = int(d.get("charge", 0))
	return h
