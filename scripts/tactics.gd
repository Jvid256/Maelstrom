class_name Tactics
extends Control
## Tactical combat for major fights: a hex battlefield built from the land, turns with
## planned enemy moves shown on the board, and each hero's own toolkit.
##
## Shared rules: move up to the hero's step count, then one action; no moving after acting.
## Enemies plan at the start of your turn and red hexes show where their blows will land:
## step off a red hex and the blow misses. Foresight (the Oracleborn) refills 1 per turn.
##
## Scenarios (SCENARIOS below):
##   throne_hall   the Oracleborn vs the afterimages; the hall collapses at half the Guard's health.
##   ambush        the Engineer and the Augmented Player survive six turns against two antagonists.
##   crash_site    Alysia holds Pallas's airlock against waves of drifters.

signal finished(won: bool, hero_hp: int, result: Dictionary)

const COLS := 9
const ROWS := 7
const HW := 12
const HH := 9
const STEP_X := 18
const STEP_Y := 18
const SIDE := 3
const ORIGIN := Vector2(320 - 4 * STEP_X, 100)

const C_TOP := Color("#45414a")
const C_TOP_L := Color("#56515a")
const C_SIDE := Color("#2a2630")
const C_EDGE := Color("#121016")
const C_RED := Color("#c8485a")
const C_CYAN := Color("#9fe0e6")
const C_AMBER := Color("#f0b050")

const SCENARIOS := {
	"throne_hall": {
		"title": "THE THRONE HALL", "sub": "Afterimages of the last hour", "sub2": "The hall is collapsing",
		"hero": "oracle", "hero_pos": Vector2i(4, 6), "goal": "boss",
		"blocks": {Vector2i(2, 1): "pillar", Vector2i(6, 1): "pillar", Vector2i(2, 4): "pillar", Vector2i(6, 4): "pillar", Vector2i(4, 0): "throne",
			Vector2i(0, 0): "void", Vector2i(8, 0): "void", Vector2i(0, 6): "void", Vector2i(8, 6): "void"},
		"enemies": [["afterimage_guard", Vector2i(4, 2), true], ["afterimage_echo", Vector2i(2, 3), false], ["afterimage_echo", Vector2i(6, 3), false]],
		"intro": "Turn %d. Move, then act. Red hexes are blows aimed at you.",
	},
	"ambush": {
		"title": "THE PLAZA", "sub": "Survive until they have what they came for", "sub2": "",
		"hero": "engineer", "hero_pos": Vector2i(3, 5), "goal": "survive", "turns": 6,
		"blocks": {Vector2i(1, 2): "server", Vector2i(7, 2): "server", Vector2i(4, 3): "cache",
			Vector2i(0, 0): "void", Vector2i(8, 0): "void", Vector2i(0, 6): "void", Vector2i(8, 6): "void", Vector2i(4, 0): "server"},
		"enemies": [["armored_man", Vector2i(3, 0), true], ["cyber_mastiff", Vector2i(7, 2), false]],
		"ally": {"name": "The Augmented Player", "sprite": "npc_player", "pos": Vector2i(5, 5), "hp": 34, "atk": 8, "armor": 2, "move": 2},
		"intro": "Turn %d of 6. Keep the Engineer alive. Deploy turrets between you and them.",
	},
	"crash_site": {
		"title": "THE CRASH SITE", "sub": "Hold the airlock", "sub2": "",
		"hero": "gunslinger", "hero_pos": Vector2i(4, 2), "goal": "defend", "objective": Vector2i(4, 1), "hold": Vector2i(4, 2),
		"blocks": {Vector2i(2, 0): "hull", Vector2i(3, 0): "hull", Vector2i(4, 0): "hull", Vector2i(5, 0): "hull", Vector2i(6, 0): "hull",
			Vector2i(1, 0): "void", Vector2i(7, 0): "void", Vector2i(0, 0): "void", Vector2i(8, 0): "void", Vector2i(4, 1): "airlock",
			Vector2i(3, 1): "crates", Vector2i(5, 1): "crates", Vector2i(1, 3): "crates", Vector2i(7, 3): "crates"},
		"enemies": [["drifter", Vector2i(1, 6), false], ["drifter", Vector2i(7, 6), false]],
		"waves": {3: [["drifter", Vector2i(2, 6)], ["raider", Vector2i(6, 6)]], 5: [["reaver", Vector2i(4, 6)]]},
		"intro": "Turn %d. Nothing reaches the airlock. The crates make a doorway: hold it, and they can only come at you from the front.",
	},
}

var scenario := ""
var sc := {}
var terrain := {}   # Vector2i -> "floor" | "crack" | block name | "void"
var units: Array = []
var hero: Dictionary
var hero_state: HeroState
var turn := 1
var phase2 := false
var steps_left := 2
var acted := false
var guarding := false
var quickdraw := false
var foresight := 0
var fs_max := 3
var armor := 0
var supplies := 0
var charge := 0
var turrets_placed := 0
var action := ""
var log_text := ""
var _busy := false
var _hover := Vector2i(-99, -99)
var _rng := RandomNumberGenerator.new()
var _font: Font
var _buttons := {}
var _button_row: HBoxContainer
var _fs_label: Label
var _info: Label
var _result := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_font = load("res://fonts/PixelifySans.ttf")
	var bar := PanelContainer.new()
	add_child(bar)
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = -220
	bar.offset_right = 220
	bar.offset_top = -46
	bar.offset_bottom = -4
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	bar.add_child(col)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(580, 0)
	col.add_child(_info)
	_button_row = HBoxContainer.new()
	_button_row.add_theme_constant_override("separation", 3)
	col.add_child(_button_row)
	_fs_label = Label.new()
	_fs_label.add_theme_color_override("font_color", C_CYAN)


## Actions per hero: [id, label].
func _kit(hero_id: String) -> Array:
	match hero_id:
		"engineer":
			return [["strike", "Wrench"], ["deploy", "Deploy turret"], ["patch", "Patch (+8)"], ["draught", "Draught"], ["end", "End turn"]]
		"gunslinger":
			return [["python", "Python"], ["glock", "Glock"], ["energy", "Energy shot"], ["quickdraw", "Quick-draw"], ["draught", "Draught"], ["end", "End turn"]]
		_:
			return [["strike", "Strike"], ["bash", "Bash"], ["guard", "Guard"], ["draught", "Draught"], ["cancel", "Cancel (1)"], ["counter", "Counter (2)"], ["end", "End turn"]]


# ------------------------------------------------------------------ setup
func start(scenario_id: String, hs: HeroState, hero_hp: int, draughts: int) -> void:
	scenario = scenario_id
	sc = SCENARIOS[scenario_id]
	hero_state = hs
	var stats := hs.stats()
	for b in _buttons.values():
		b.queue_free()
	_buttons.clear()
	for a in _kit(hs.id):
		var b := Button.new()
		b.text = a[1]
		b.focus_mode = Control.FOCUS_NONE
		var id: String = a[0]
		b.pressed.connect(func() -> void: _on_button(id))
		_button_row.add_child(b)
		_buttons[id] = b
	if _fs_label.get_parent():
		_fs_label.get_parent().remove_child(_fs_label)
	_button_row.add_child(_fs_label)
	terrain.clear()
	for c in range(COLS):
		for r in range(ROWS):
			terrain[Vector2i(c, r)] = "floor"
	for p in sc["blocks"]:
		terrain[p] = sc["blocks"][p]
	units = []
	hero = {"kind": "hero", "name": hs.short_name(), "sprite": hs.def()["sprite"], "pos": sc["hero_pos"], "hp": hero_hp, "max": stats["hp"],
		"atk": stats["atk"], "armor": stats["armor"], "move": 3 if hs.id == "gunslinger" else 2, "read": 0, "intent": {}}
	units.append(hero)
	if sc.has("ally"):
		var a: Dictionary = sc["ally"].duplicate()
		a["kind"] = "ally"
		a["max"] = a["hp"]
		a["read"] = 0
		a["intent"] = {}
		units.append(a)
	for e in sc["enemies"]:
		units.append(_enemy(e[0], e[1], e[2]))
	fs_max = stats["fs"]
	foresight = fs_max
	armor = stats["armor"]
	supplies = draughts
	charge = hs.charge if hs.id == "gunslinger" else 0
	turrets_placed = 0
	turn = 1
	phase2 = false
	_busy = false
	_finished = false
	_result = {"kills": [], "xp": 0, "turns": 0}
	visible = true
	_begin_turn()


func _enemy(id: String, p: Vector2i, boss: bool) -> Dictionary:
	var d := Bestiary.enemy(id)
	return {"kind": "enemy", "id": id, "name": d["name"], "sprite": d["sprite"], "pos": p, "hp": d["hp"], "max": d["hp"],
		"atk": d["atk"], "armor": d["armor"], "move": 3 if d["special"] == "swift" else (2 if boss or d["special"] == "relentless" else 1),
		"boss": boss, "read": 0, "intent": {},
		"special": d["special"], "tags": d["tags"]}


# ------------------------------------------------------------------ geometry
func center(p: Vector2i) -> Vector2:
	return ORIGIN + Vector2(p.x * STEP_X, p.y * STEP_Y + (p.x & 1) * (STEP_Y / 2))


func _hex_points(c: Vector2, dy: float = 0.0) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(-HW, dy), c + Vector2(-HW / 2, -HH + dy), c + Vector2(HW / 2, -HH + dy),
		c + Vector2(HW, dy), c + Vector2(HW / 2, HH + dy), c + Vector2(-HW / 2, HH + dy)])


func pick(m: Vector2) -> Vector2i:
	var best := Vector2i(-99, -99)
	var bd := INF
	for p in terrain:
		var d := center(p).distance_to(m)
		if d < bd and Geometry2D.is_point_in_polygon(m, _hex_points(center(p))):
			bd = d
			best = p
	return best


func walkable(p: Vector2i) -> bool:
	return terrain.get(p, "void") in ["floor", "crack", "airlock"] and unit_at(p).is_empty()


func unit_at(p: Vector2i) -> Dictionary:
	for u in units:
		if u["hp"] > 0 and u["pos"] == p:
			return u
	return {}


func enemies() -> Array:
	return units.filter(func(u): return u["kind"] == "enemy" and u["hp"] > 0)


func friends() -> Array:
	return units.filter(func(u): return u["kind"] in ["hero", "ally", "turret"] and u["hp"] > 0)


## Hexes reachable within n steps.
func reachable(from: Vector2i, n: int) -> Dictionary:
	var dist := {from: 0}
	var frontier := [from]
	for i in range(n):
		var next := []
		for p in frontier:
			for q in Hex.neighbors(p):
				if not dist.has(q) and walkable(q):
					dist[q] = i + 1
					next.append(q)
		frontier = next
	dist.erase(from)
	return dist


# ------------------------------------------------------------------ turns
func _begin_turn() -> void:
	steps_left = hero["move"]
	acted = false
	guarding = false
	quickdraw = false
	action = ""
	if turn > 1:
		foresight = mini(fs_max, foresight + 1)
		if hero_state.id == "gunslinger":
			charge = mini(9, charge + 1)
	if phase2:
		_crack_floor()
	if sc.has("waves") and sc["waves"].has(turn):
		for w in sc["waves"][turn]:
			var spot := _nearest_floor(w[1])
			units.append(_enemy(w[0], spot, false))
		_say("More of them come out of the dust.")
	for e in enemies():
		_plan(e)
	_say(sc["intro"] % turn)
	_refresh()


## Enemies choose whom to hit: whoever they can reach, the airlock if defending, else they advance.
func _plan(e: Dictionary) -> void:
	var targets := friends()
	var best: Dictionary = {}
	var bd := 99
	for t in targets:
		var d := Hex.distance(e["pos"], t["pos"])
		if t["kind"] == "hero" and scenario == "ambush" and d <= 3:
			d -= 2  # they want the boy with the toys
		if d < bd:
			bd = d
			best = t
	bd = Hex.distance(e["pos"], best["pos"]) if not best.is_empty() else 99
	var objective: Vector2i = sc.get("objective", Vector2i(-99, -99))
	if sc["goal"] == "defend" and bd > 1 and objective != Vector2i(-99, -99):
		e["intent"] = {"type": "advance", "to": objective}
	elif bd <= 1 and e.get("boss", false) and e["id"] == "afterimage_guard":
		var hexes := [best["pos"]]
		for q in Hex.neighbors(best["pos"]):
			if Hex.distance(q, e["pos"]) == 1 and hexes.size() < 3 and terrain.get(q, "void") != "void":
				hexes.append(q)
		e["intent"] = {"type": "sweep", "hexes": hexes, "dmg": e["atk"]}
	elif bd <= 1 or (bd <= 2 and e.get("boss", false) == false and e["special"] != "relentless"):
		e["intent"] = {"type": "strike", "hexes": [best["pos"]], "dmg": e["atk"]}
	else:
		e["intent"] = {"type": "advance", "to": best["pos"] if not best.is_empty() else e["pos"]}
	# the Oracleborn only sees blows aimed at him unless an enemy is Read; others see everything
	if hero_state.id == "oracle":
		e["visible"] = e["read"] > 0 or e["intent"].get("hexes", []).has(hero["pos"])
	else:
		e["visible"] = true


func _end_turn() -> void:
	if _busy:
		return
	_busy = true
	action = ""
	_result["turns"] = turn
	if hero_state.id == "gunslinger" and steps_left == hero["move"]:
		quickdraw = true  # she held her ground: the first thing to swing at her eats a round
	# turrets fire first
	for u in units:
		if u["kind"] == "turret" and u["hp"] > 0:
			for q in Hex.neighbors(u["pos"]):
				var t := unit_at(q)
				if not t.is_empty() and t["kind"] == "enemy":
					_damage(t, u["atk"])
					break
	# the ally acts
	for u in units:
		if u["kind"] == "ally" and u["hp"] > 0:
			await _ally_act(u)
	for e in enemies():
		await _act(e)
		if hero["hp"] <= 0:
			break
	if phase2 and hero["hp"] > 0:
		await _collapse()
	for e in enemies():
		e["read"] = maxi(0, e["read"] - 1)
	_busy = false
	if hero["hp"] <= 0:
		_finish(false)
		return
	if sc["goal"] == "defend":
		var obj: Vector2i = sc["objective"]
		var at := unit_at(obj)
		if not at.is_empty() and at["kind"] == "enemy":
			_say("They're through the airlock.")
			_finish(false)
			return
	if sc["goal"] == "survive" and turn >= int(sc["turns"]):
		_finish(true)
		return
	turn += 1
	_begin_turn()


func _ally_act(a: Dictionary) -> void:
	var target: Dictionary = {}
	var bd := 99
	for e in enemies():
		var d := Hex.distance(a["pos"], e["pos"])
		if d < bd:
			bd = d
			target = e
	if target.is_empty():
		return
	if bd > 1:
		_step_toward_hex(a, target["pos"], a["move"])
	if Hex.distance(a["pos"], target["pos"]) <= 1:
		_damage(target, a["atk"] + _rng.randi_range(-1, 1))
		_say("%s strikes %s." % [a["name"], target["name"]])
	queue_redraw()
	await get_tree().create_timer(0.3).timeout


func _act(e: Dictionary) -> void:
	var it: Dictionary = e["intent"]
	match it.get("type", ""):
		"advance":
			_step_toward_hex(e, it["to"], e["move"])
			# a swift enemy that arrives next to someone bites at once
			if e["special"] == "swift":
				for q in Hex.neighbors(e["pos"]):
					var t := unit_at(q)
					if not t.is_empty() and t["kind"] != "enemy":
						_hit_unit(e, t, maxi(1, e["atk"] / 2))
						break
		"strike":
			var target: Vector2i = it["hexes"][0]
			if Hex.distance(e["pos"], target) > 1:
				_step_toward_hex(e, target, 1)
			if Hex.distance(e["pos"], target) <= 1:
				_hit_hexes(e, it["hexes"], it["dmg"])
		"sweep":
			_hit_hexes(e, it["hexes"], it["dmg"])
	e["intent"] = {}
	queue_redraw()
	await get_tree().create_timer(0.35).timeout


func _hit_hexes(e: Dictionary, hexes: Array, dmg: int) -> void:
	var hit_any := false
	for h in hexes:
		var t := unit_at(h)
		if not t.is_empty() and t["kind"] != "enemy":
			_hit_unit(e, t, dmg)
			hit_any = true
	if not hit_any:
		_say("%s strikes empty ground." % e["name"])


func _hit_unit(e: Dictionary, t: Dictionary, dmg: int) -> void:
	if t["kind"] == "hero" and quickdraw:
		quickdraw = false
		_damage(e, 6)
		_say("Quick-draw: she fires first (6).")
		if e["hp"] <= 0:
			return
	var taken := maxi(ceili(dmg * 0.4), dmg - int(t.get("armor", 0)))
	if t["kind"] == "hero" and guarding:
		taken = maxi(1, taken / 2)
	t["hp"] -= taken
	if t["kind"] == "hero":
		_say("%s hits for %d." % [e["name"], taken])
	elif t["kind"] == "ally":
		_say("%s hits %s for %d." % [e["name"], t["name"], taken])
		if t["hp"] <= 0 and sc["goal"] == "survive":
			t["hp"] = 1  # the Player holds on until the end of the fight; the story decides the rest
	else:
		_say("%s smashes a turret." % e["name"])


func _step_toward_hex(e: Dictionary, target: Vector2i, n: int) -> void:
	for i in range(n):
		if Hex.distance(e["pos"], target) <= (0 if terrain.get(target, "") == "airlock" and e["kind"] == "enemy" else 1):
			return
		var best: Vector2i = e["pos"]
		var bd := Hex.distance(e["pos"], target)
		for q in Hex.neighbors(e["pos"]):
			if walkable(q) and Hex.distance(q, target) < bd:
				bd = Hex.distance(q, target)
				best = q
		if best == e["pos"]:
			return
		e["pos"] = best


func _crack_floor() -> void:
	var floors := []
	for p in terrain:
		if terrain[p] == "floor":
			floors.append(p)
	floors.shuffle()
	for i in range(mini(3, floors.size())):
		terrain[floors[i]] = "crack"


func _collapse() -> void:
	var fell := false
	for p in terrain.keys():
		if terrain[p] == "crack":
			terrain[p] = "void"
			fell = true
			var u := unit_at(p)
			if not u.is_empty():
				u["hp"] -= 4
				u["pos"] = _nearest_floor(p)
				if u["kind"] == "hero":
					_say("The floor gives way under him: 4 damage.")
	if fell:
		queue_redraw()
		await get_tree().create_timer(0.35).timeout


func _nearest_floor(p: Vector2i) -> Vector2i:
	var best := p
	var bd := 99
	for q in terrain:
		if terrain[q] == "floor" and unit_at(q).is_empty() and Hex.distance(p, q) < bd:
			bd = Hex.distance(p, q)
			best = q
	return best


# ------------------------------------------------------------------ player actions
func _on_button(id: String) -> void:
	if _busy:
		return
	match id:
		"end":
			_end_turn()
		"guard":
			if not acted:
				guarding = true
				acted = true
				steps_left = 0
				_say("He raises the shield. Damage this enemy turn is halved.")
		"quickdraw":
			if not acted:
				quickdraw = true
				acted = true
				steps_left = 0
				_say("She waits with her hand on the Python. The first thing to swing at her eats a round. (Free whenever she doesn't move.)")
		"patch":
			if not acted:
				hero["hp"] = mini(hero["max"], hero["hp"] + 8)
				acted = true
				steps_left = 0
				_say("The swarm knits him back together: +8 health.")
		"draught":
			if not acted and supplies > 0:
				supplies -= 1
				hero["hp"] = mini(hero["max"], hero["hp"] + 10)
				acted = true
				steps_left = 0
				_say("A draught: +10 health.")
		_:
			action = "" if action == id else id
			_say({"strike": "Strike: click an adjacent enemy.", "bash": "Bash: click an adjacent enemy. Pushes it back and leaves it Read for 2 turns.",
				"cancel": "Cancel: click an enemy whose attack you can see.",
				"counter": "Counter: click an adjacent enemy whose attack you can see.",
				"deploy": "Deploy: click an empty hex next to you. Turrets hit an adjacent enemy for 3 each turn and draw fire.",
				"python": "Python: click an enemy within 3 hexes. Hits hardest.", "glock": "Glock: click an enemy within 2 hexes. Two shots.",
				"energy": "Energy shot: click an enemy within 4 hexes. Ignores armor. Needs 3 charge."}.get(id, ""))
	_refresh()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var p := pick(event.position)
		if p != _hover:
			_hover = p
			_hover_info(p)
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and not _busy:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			action = ""
			_refresh()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			_click(pick(event.position))


func _click(p: Vector2i) -> void:
	if not terrain.has(p):
		return
	var u := unit_at(p)
	if action == "deploy":
		if acted or not walkable(p) or Hex.distance(p, hero["pos"]) != 1 or terrain[p] == "airlock":
			_say("Deploy needs an empty hex next to you, before you've acted.")
			return
		if turrets_placed >= 2:
			_say("He only carries parts for two turrets.")
			return
		turrets_placed += 1
		units.append({"kind": "turret", "name": "Turret", "sprite": "enemy_drone", "pos": p, "hp": 8, "max": 8, "atk": 3, "armor": 0, "move": 0, "read": 0, "intent": {}})
		acted = true
		steps_left = 0
		action = ""
		for e in enemies():
			_plan(e)
		_say("Turret deployed. It fires at the end of your turn.")
		_refresh()
		return
	if action != "" and not u.is_empty() and u["kind"] == "enemy":
		_use_on(action, u)
		return
	if action == "" and u.is_empty() and not acted and reachable(hero["pos"], steps_left).has(p):
		steps_left -= reachable(hero["pos"], steps_left)[p]
		hero["pos"] = p
		_refresh()


func _use_on(a: String, e: Dictionary) -> void:
	var dist := Hex.distance(e["pos"], hero["pos"])
	var adjacent := dist == 1
	var seen: bool = e.get("visible", false) and e["intent"].has("hexes")
	match a:
		"strike":
			if acted or not adjacent:
				_say("Strike needs an adjacent enemy, before you've acted.")
				return
			_damage(e, hero["atk"] + _rng.randi_range(-1, 1))
			acted = true
			steps_left = 0
		"bash":
			if acted or not adjacent:
				_say("Bash needs an adjacent enemy, before you've acted.")
				return
			_damage(e, maxi(1, hero["atk"] / 2) * (2 if e["special"] == "brittle" else 1))
			e["read"] = 2
			e["visible"] = true
			_push(e)
			acted = true
			steps_left = 0
		"cancel":
			if not seen or foresight < 1:
				_say("You can only cancel an attack you can see, with 1 Foresight.")
				return
			foresight -= 1
			e["intent"] = {"type": "foreseen"}
			_say("Foreseen. The blow never comes.")
		"counter":
			if not seen or not adjacent or foresight < 2:
				_say("Counter needs an adjacent enemy whose attack you can see, and 2 Foresight.")
				return
			foresight -= 2
			e["intent"] = {"type": "foreseen"}
			_damage(e, hero["atk"] + 2)
		"python", "glock", "energy":
			var guns := hero_state.guns()
			if acted or not guns.has(a):
				_say("One shot per turn.")
				return
			var ranges := {"python": 3, "glock": 2, "energy": 4}
			if dist > ranges[a]:
				_say("Out of range: the %s reaches %d hexes." % [guns[a]["name"], ranges[a]])
				return
			if a == "energy" and charge < 3:
				_say("The energy pistol needs 3 charge (it has %d). It charges 1 per turn." % charge)
				return
			var dmg: int = guns[a]["dmg"] + (3 if a == "python" else 0)  # a Python round, aimed, drops a man
			var ammo := hero_state.ammo()
			var pierce := a == "energy"
			if a != "energy" and not ammo.is_empty():
				for t in ammo["vs"]:
					if e["tags"].has(t):
						if ammo.has("pierce"):
							pierce = true
						else:
							dmg = roundi(dmg * ammo.get("mult", 1.0))
						break
			hero_state.shots[a] = int(hero_state.shots.get(a, 0)) + (2 if a == "glock" else 1)
			if a == "glock":
				_damage(e, dmg + _rng.randi_range(-1, 1), pierce)
				if e["hp"] > 0:
					_damage(e, dmg + _rng.randi_range(-1, 1), pierce)
			else:
				_damage(e, dmg + _rng.randi_range(-1, 1), pierce)
			if a == "energy":
				charge = 0
			acted = true
			steps_left = 0
	action = ""
	_refresh()
	_check_win()


func _damage(e: Dictionary, dmg: int, pierce: bool = false) -> void:
	var taken := dmg if pierce else maxi(ceili(dmg * 0.5), dmg - int(e.get("armor", 0)))
	e["hp"] -= taken
	_say("%s takes %d." % [e["name"], taken])
	if e["hp"] <= 0 and e["kind"] == "enemy":
		_result["kills"].append(e["id"])
		_result["xp"] += int(e["max"]) / 2 + 4
	if e.get("boss", false) and scenario == "throne_hall" and not phase2 and e["hp"] <= e["max"] / 2 and e["hp"] > 0:
		phase2 = true
		var echo := _enemy("afterimage_echo", _nearest_floor(Vector2i(4, 1)), false)
		units.append(echo)
		_plan(echo)
		_say("The Guard strikes the floor. The hall begins to collapse, and another echo steps out of the light.")


func _push(e: Dictionary) -> void:
	var away: Vector2i = e["pos"]
	var bd := Hex.distance(e["pos"], hero["pos"])
	for q in Hex.neighbors(e["pos"]):
		if walkable(q) and Hex.distance(q, hero["pos"]) > bd:
			away = q
			break
	if away != e["pos"]:
		e["pos"] = away
		if e["intent"].get("type", "") in ["strike", "sweep"]:
			_plan(e)
			e["visible"] = true


func _check_win() -> void:
	match sc["goal"]:
		"boss":
			for e in enemies():
				if e.get("boss", false):
					return
			_finish(true)
		"defend":
			if enemies().is_empty() and turn >= 5:
				_finish(true)


var _finished := false


func _finish(won: bool) -> void:
	if _finished:
		return
	_finished = true
	_busy = true
	_say({"boss": "The afterimages fade. The hall is quiet.", "survive": "The attackers turn back into the fog with what they came for.",
		"defend": "The last of them goes down in the dust."}[sc["goal"]] if won else "%s falls back." % hero["name"])
	queue_redraw()
	await get_tree().create_timer(1.2).timeout
	visible = false
	if hero_state.id == "gunslinger":
		hero_state.charge = charge
	finished.emit(won, maxi(1, hero["hp"]), _result)


# ------------------------------------------------------------------ display
func _say(t: String) -> void:
	if t != "":
		log_text = t
	_refresh()


func _hover_info(p: Vector2i) -> void:
	var u := unit_at(p)
	if u.is_empty() or u["kind"] == "hero":
		return
	if u["kind"] != "enemy":
		log_text = "%s  %d/%d health." % [u["name"], maxi(0, u["hp"]), u["max"]]
		_refresh()
		return
	var plan := "?"
	if u.get("visible", false):
		plan = {"advance": "advance", "strike": "lunge and strike (%d)", "sweep": "sweep (%d)", "foreseen": "foreseen"}.get(
			u["intent"].get("type", ""), "-")
		if "%d" in plan:
			plan = plan % u["intent"]["dmg"]
	log_text = "%s  %d/%d health, armor %d. Plans: %s%s" % [u["name"], maxi(0, u["hp"]), u["max"], u["armor"], plan, "  (Read)" if u["read"] > 0 else ""]
	_refresh()


func _refresh() -> void:
	if not is_inside_tree() or sc.is_empty():
		return
	_info.text = log_text
	match hero_state.id:
		"oracle":
			_fs_label.text = "Foresight %d/%d" % [foresight, fs_max]
		"gunslinger":
			_fs_label.text = "Charge %d/3" % charge
		_:
			_fs_label.text = "Turrets %d/2" % turrets_placed
	for id in _buttons:
		var b: Button = _buttons[id]
		match id:
			"end":
				b.disabled = false
			"draught":
				b.disabled = acted or supplies <= 0
				b.text = "Draught (%d)" % supplies
			"cancel":
				b.disabled = foresight < 1
			"counter":
				b.disabled = foresight < 2
			"energy":
				b.disabled = acted or charge < 3
			"deploy":
				b.disabled = acted or turrets_placed >= 2
			_:
				b.disabled = acted
		b.add_theme_color_override("font_color", C_AMBER if action == id else Hud.TEXT)
	queue_redraw()


func _draw() -> void:
	if sc.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.01, 0.04, 0.72))
	_text(Vector2(320, 22), sc["title"], C_AMBER, true)
	_text(Vector2(320, 36), sc["sub2"] if phase2 and sc["sub2"] != "" else sc["sub"], Hud.DIM, true)
	var reach := {} if acted or action != "" else reachable(hero["pos"], steps_left)
	var order := terrain.keys()
	order.sort_custom(func(a, b): return center(a).y < center(b).y)
	for p in order:
		var t: String = terrain[p]
		if t == "void":
			continue
		var c := center(p)
		draw_colored_polygon(_hex_points(c, SIDE), C_SIDE)
		draw_colored_polygon(_hex_points(c), C_TOP if (p.x + p.y) % 3 else C_TOP_L)
		draw_polyline(_close(_hex_points(c)), C_EDGE)
		if t == "crack":
			draw_polyline(_close(_hex_points(c)), C_RED)
			draw_line(c + Vector2(-5, -3), c + Vector2(1, 1), C_EDGE)
			draw_line(c + Vector2(1, 1), c + Vector2(5, -1), C_EDGE)
		if t == "airlock":
			draw_polyline(_close(_hex_points(c)), C_AMBER)
			draw_rect(Rect2(c + Vector2(-3, -5), Vector2(6, 8)), Color("#0c0912"))
			draw_rect(Rect2(c + Vector2(-2, -4), Vector2(4, 6)), Color("#f0b050"))
		if reach.has(p):
			draw_polyline(_close(_hex_points(c)), Color(C_CYAN, 0.6))
	for e in enemies():
		if e.get("visible", false) and e["intent"].has("hexes"):
			for h in e["intent"]["hexes"]:
				var c := center(h)
				draw_polyline(_close(_hex_points(c)), C_RED, 1.0)
				draw_colored_polygon(_hex_points(c), Color(C_RED, 0.18))
	for p in order:
		var c := center(p)
		match terrain[p]:
			"pillar":
				draw_rect(Rect2(c + Vector2(-4, -26), Vector2(8, 26)), Color("#a8a4ae"))
				draw_rect(Rect2(c + Vector2(1, -26), Vector2(3, 26)), Color("#76727e"))
				draw_rect(Rect2(c + Vector2(-5, -28), Vector2(10, 2)), Color("#8a7a4a"))
			"throne":
				draw_rect(Rect2(c + Vector2(-5, -18), Vector2(10, 16)), Color("#a8a4ae"))
				draw_rect(Rect2(c + Vector2(-6, -4), Vector2(12, 4)), Color("#76727e"))
				draw_rect(Rect2(c + Vector2(-5, -20), Vector2(10, 2)), Color("#8a7a4a"))
			"server":
				draw_rect(Rect2(c + Vector2(-5, -20), Vector2(10, 20)), Color("#2f3640"))
				draw_rect(Rect2(c + Vector2(1, -20), Vector2(4, 20)), Color("#46505c"))
				for k in range(1, 19, 3):
					draw_rect(Rect2(c + Vector2(-3, -k - 1), Vector2(2, 1)), Color("#5fb8c4") if k % 2 else Color("#1e2228"))
			"cache":
				draw_rect(Rect2(c + Vector2(-6, -8), Vector2(12, 8)), Color("#46505c"))
				draw_rect(Rect2(c + Vector2(-6, -9), Vector2(12, 2)), Color("#66727e"))
				draw_rect(Rect2(c + Vector2(-1, -5), Vector2(2, 2)), Color("#5fb8c4"))
			"hull":
				draw_rect(Rect2(c + Vector2(-9, -24), Vector2(18, 26)), Color("#5a6470"))
				draw_rect(Rect2(c + Vector2(-9, -24), Vector2(18, 3)), Color("#7c8794"))
				draw_rect(Rect2(c + Vector2(-2, -14), Vector2(4, 4)), Color("#f0b050"))
			"crates":
				draw_rect(Rect2(c + Vector2(-5, -6), Vector2(10, 6)), Color("#6e6a5e"))
				draw_rect(Rect2(c + Vector2(-3, -10), Vector2(6, 4)), Color("#4a4740"))
		var u := unit_at(p)
		if u.is_empty():
			continue
		var tex: Texture2D = TileFactory.character(u["sprite"])
		draw_texture(tex, (c + Vector2(-tex.get_width() / 2, -tex.get_height() + 4)).floor())
		if u["kind"] != "hero":
			var top := c + Vector2(-8, -tex.get_height() - 1)
			draw_rect(Rect2(top, Vector2(16, 2)), Color("#0c0912"))
			var col := Color("#9a2e3e") if u["kind"] == "enemy" else C_CYAN
			draw_rect(Rect2(top, Vector2(16.0 * clampf(float(u["hp"]) / u["max"], 0, 1), 2)), col)
			if u["kind"] == "enemy":
				if not u.get("visible", false):
					_text(top + Vector2(8, -2), "?", Hud.DIM, true)
				elif u["intent"].get("type", "") in ["strike", "sweep"]:
					_text(top + Vector2(8, -2), str(u["intent"]["dmg"]), C_RED, true)
				if u["read"] > 0:
					draw_rect(Rect2(top + Vector2(17, -1), Vector2(3, 3)), C_CYAN)
	if terrain.has(_hover):
		draw_polyline(_close(_hex_points(center(_hover))), Color(1, 1, 1, 0.5))
	var hp_pos := Vector2(40, 60)
	_text(hp_pos, hero["name"].to_upper(), Hud.TEXT, false)
	draw_rect(Rect2(hp_pos + Vector2(0, 4), Vector2(60, 3)), Color("#0c0912"))
	draw_rect(Rect2(hp_pos + Vector2(0, 4), Vector2(60.0 * clampf(float(hero["hp"]) / hero["max"], 0, 1), 3)), Color("#9a2e3e"))
	_text(hp_pos + Vector2(0, 16), "%d / %d" % [maxi(0, hero["hp"]), hero["max"]], Hud.DIM, false)
	_text(hp_pos + Vector2(0, 28), "Steps %d" % steps_left, Hud.DIM, false)
	if sc["goal"] == "survive":
		_text(hp_pos + Vector2(0, 40), "Turn %d / %d" % [turn, int(sc["turns"])], C_AMBER, false)
	if guarding:
		_text(hp_pos + Vector2(0, 52), "Guarding", C_CYAN, false)
	if quickdraw:
		_text(hp_pos + Vector2(0, 52), "Quick-draw", C_CYAN, false)


func _close(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out


func _text(at: Vector2, t: String, col: Color, centered: bool) -> void:
	var w := _font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var p := at - Vector2(w / 2 if centered else 0.0, 0)
	draw_string(_font, p.floor() + Vector2(1, 1), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#0c0912"))
	draw_string(_font, p.floor(), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
