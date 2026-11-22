class_name Battle
extends Control
## The auto-combat board: the hero on the left, one or two enemies on the right, all
## acting on their own timers. No direct control (Loop Hero style); behaviors set
## beforehand decide what the hero does.
##   The Oracleborn spends Foresight to dodge heavy hits.
##   The Engineer's constructs open the fight with him, and the fugue may improvise.
##   Alysia switches guns to suit the enemy and her ammo, and fires the energy pistol when charged.

signal finished(won: bool, hero_hp: int, foresight: int, supplies: int, result: Dictionary)

const SPEED := 1.6  # whole fight runs a bit faster than real time
const FUGUE_EFFECTS := {
	"overclock": {"text": "Fugue: overclock", "blueprint": "turret_mk2"},
	"mend": {"text": "Fugue: the swarm mends", "blueprint": "plating_implant"},
	"surge": {"text": "Fugue: a surge", "blueprint": "spark_coil"},
	"ward": {"text": "Fugue: a ward", "blueprint": "shield_drone"},
	"backfire": {"text": "Fugue: backfire", "blueprint": ""},
}

var _hero: HeroState
var _stats := {}
var _hero_hp := 0
var _hero_max := 1
var _foresight := 0
var _supplies := 0
var _shield := 0
var _free_dodge := false
var _hero_t := 0.0
var _enemies: Array = []
var _constructs: Array = []
var _gun := "glock"
var _running := false
var _result := {}
var _rng := RandomNumberGenerator.new()

var _title: Label
var _mood: Label
var _regen_t := 0.0
var _hero_rect: TextureRect
var _hero_bar: ColorRect
var _hero_hp_label: Label
var _hero_note: Label
var _construct_rect: TextureRect
var _enemy_boxes: Array = []
var _board: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_board = PanelContainer.new()
	_board.custom_minimum_size = Vector2(320, 0)
	add_child(_board)
	_board.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_board.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_board.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	_board.add_child(box)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", Color("#f0b050"))
	box.add_child(_title)
	_mood = Label.new()
	_mood.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mood.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mood.custom_minimum_size = Vector2(320, 0)
	_mood.add_theme_font_size_override("font_size", 11)
	_mood.add_theme_color_override("font_color", Color("#9a90b2"))
	box.add_child(_mood)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var left := _fighter(row, true)
	_hero_rect = left[0]
	_hero_bar = left[1]
	_hero_hp_label = left[2]
	_hero_note = left[3]
	_construct_rect = TextureRect.new()
	_construct_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_construct_rect.custom_minimum_size = Vector2(12, 52)
	row.add_child(_construct_rect)
	var vs := Label.new()
	vs.text = "vs"
	vs.add_theme_color_override("font_color", Color("#9a90b2"))
	row.add_child(vs)
	for i in range(2):
		_enemy_boxes.append(_fighter(row, false))


func _fighter(parent: Control, is_hero: bool) -> Array:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	parent.add_child(col)
	var name := Label.new()
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 11)
	name.add_theme_color_override("font_color", Color("#9a90b2"))
	col.add_child(name)
	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(48, 52)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	col.add_child(rect)
	var back := ColorRect.new()
	back.color = Color("#0c0912")
	back.custom_minimum_size = Vector2(44, 3)
	col.add_child(back)
	var fill := ColorRect.new()
	fill.color = Color("#9a2e3e")
	fill.size = Vector2(44, 3)
	back.add_child(fill)
	var hp := Label.new()
	hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp.add_theme_font_size_override("font_size", 11)
	col.add_child(hp)
	return [rect, fill, hp, name, col]


# ------------------------------------------------------------------ setup
## Set before start(): what happened before the fight. wound: enemies begin with this share
## of their health gone. note: a line under the hero saying why.
var opening := {}


func start(enemy_ids: Array, hero: HeroState, hero_hp: int, foresight: int, supplies: int) -> void:
	_hero = hero
	_stats = hero.stats()
	_hero_hp = hero_hp
	_hero_max = _stats["hp"]
	_foresight = foresight
	_supplies = supplies
	_shield = 0
	_hero_t = 0.0
	_free_dodge = hero.id == "oracle" and hero.has_vision("ritual_echo")
	_result = {"kills": [], "xp": 0, "notes": [], "shots": {}}
	_enemies = []
	for i in range(enemy_ids.size()):
		var e: Dictionary = Bestiary.enemy(enemy_ids[i]).duplicate()
		e["id"] = enemy_ids[i]
		e["t"] = 0.3 + 0.4 * i
		e["stun"] = 0.0
		e["max"] = e["hp"]
		var wound: float = float(opening.get("wound", 0.0))
		if wound > 0.0:
			e["hp"] = maxi(1, int(round(e["hp"] * (1.0 - wound))))
		_enemies.append(e)
	_constructs = []
	if hero.id == "engineer":
		for c in hero.constructs():
			var cc: Dictionary = c.duplicate()
			cc["t"] = 0.0
			_constructs.append(cc)
	_hero_rect.texture = TileFactory.scaled(TileFactory.hero_texture(hero.id), 2)
	_construct_rect.texture = _construct_texture() if not _constructs.is_empty() else null
	_construct_rect.visible = not _constructs.is_empty()
	for i in range(2):
		var box: Array = _enemy_boxes[i]
		box[4].visible = i < _enemies.size()
		if i < _enemies.size():
			box[0].texture = TileFactory.scaled(TileFactory.enemy_texture(_enemies[i]["id"]), 2)
			box[3].text = _enemies[i]["name"]
	_title.text = (" & ".join(_enemies.map(func(e): return e["name"]))).to_upper()
	_mood.text = _enemies[0]["text"]
	_hero_note.text = String(opening.get("note", ""))
	opening = {}
	_regen_t = 0.0
	_open_fight()
	_update_bars()
	visible = true
	_running = true


func _construct_texture() -> ImageTexture:
	return TileFactory.scaled(TileFactory.character("enemy_drone"), 1)


## What happens as the fight opens: constructs deploy, the fugue improvises, Alysia draws.
func _open_fight() -> void:
	if _hero.id == "engineer":
		for c in _constructs:
			if c["kind"] == "shield":
				_shield += c["absorb"]
			elif c["kind"] == "coil":
				for e in _enemies:
					e["stun"] = c["stun"]
		if _hero.behaviors.get("fugue_on", true):
			_fugue()
	elif _hero.id == "gunslinger":
		_hero.charge = mini(9, _hero.charge + 1 + _stats["charge"])
		_choose_gun()


func _fugue() -> void:
	var chance := 0.25
	if _hero.skills["fugue"] >= 1:
		chance = 0.4
	if Story.law_known("coven"):
		chance += 0.15
	if _rng.randf() > chance:
		return
	var options := ["overclock", "mend", "surge", "ward"]
	if _hero.skills["fugue"] < 1:
		options.append("backfire")
	var fx: String = options[_rng.randi_range(0, options.size() - 1)]
	var mult := 2 if _hero.skills["fugue"] >= 3 else 1
	match fx:
		"overclock":
			for c in _constructs:
				if c.has("dmg"):
					c["dmg"] += 2 * mult
		"mend":
			_hero_hp = mini(_hero_max, _hero_hp + 8 * mult)
		"surge":
			for e in _enemies:
				e["stun"] = 1.5 * mult
		"ward":
			_shield += 6 * mult
		"backfire":
			_hero_hp -= 4
	_pop(_hero_rect, FUGUE_EFFECTS[fx]["text"], Color("#b98ae0"))
	_result["notes"].append(FUGUE_EFFECTS[fx]["text"])
	var bp: String = FUGUE_EFFECTS[fx]["blueprint"]
	if _hero.skills["fugue"] >= 2 and bp != "" and not _hero.blueprints.has(bp):
		_hero.blueprints.append(bp)
		_result["notes"].append("Blueprint studied: %s" % Items.item(bp)["name"])


## Alysia picks a gun for the enemies in front of her.
func _choose_gun() -> void:
	var guns := _hero.guns()
	var ammo := _hero.ammo()
	var tags := []
	for e in _enemies:
		if e["hp"] > 0:
			for t in e["tags"]:
				tags.append(t)
	var b := _hero.behaviors
	_gun = "glock" if guns.has("glock") else guns.keys()[0]
	if b.get("python_armored", true) and guns.has("python") and tags.has("Armored"):
		_gun = "python"
	if b.get("match_ammo", true) and guns.has("python") and not ammo.is_empty():
		for t in ammo["vs"]:
			if tags.has(t):
				_gun = "python"
	if b.get("energy_charged", true) and guns.has("energy") and _hero.charge >= guns["energy"]["charge"]:
		_gun = "energy"
	_hero_note.text = guns[_gun]["name"]


# ------------------------------------------------------------------ the fight
func _process(delta: float) -> void:
	if not _running:
		return
	delta *= SPEED
	var target := _first_alive()
	if target.is_empty():
		_end(true)
		return
	# the hero
	_hero_t += delta
	var spd: float = _stats["spd"]
	var guns := {}
	if _hero.id == "gunslinger":
		guns = _hero.guns()
		spd = guns[_gun]["spd"] + (_stats["spd"] - 1.4)
	if _hero_t >= 1.0 / maxf(0.3, spd):
		_hero_t = 0.0
		_hero_attack(target, guns)
	# the swarm, knitting
	if _stats["regen"] > 0:
		_regen_t += delta
		if _regen_t >= 2.0 and _hero_hp < _hero_max:
			_regen_t = 0.0
			_hero_hp = mini(_hero_max, _hero_hp + int(_stats["regen"]))
	# constructs
	for c in _constructs:
		if c["kind"] != "turret":
			continue
		c["t"] += delta
		if c["t"] >= c["every"]:
			c["t"] = 0.0
			var t2 := _first_alive()
			if not t2.is_empty():
				var dmg: int = c["dmg"]
				if c.get("fire", false) and (t2["tags"].has("Undead") or t2["tags"].has("Spirit")):
					dmg += 1  # the forge's hot alloy
				_damage(t2, dmg, false, Color("#f0a060") if c.get("fire", false) else Color("#9fe0e6"))
	# enemies
	for e in _enemies:
		if e["hp"] <= 0:
			continue
		if e["stun"] > 0.0:
			e["stun"] -= delta
			continue
		e["t"] += delta
		if e["t"] >= 1.0 / float(e["spd"]):
			e["t"] = 0.0
			_enemy_attack(e)
	_update_bars()
	if _hero_hp <= 0:
		_end(false)


func _first_alive() -> Dictionary:
	for e in _enemies:
		if e["hp"] > 0:
			return e
	return {}


func _hero_attack(target: Dictionary, guns: Dictionary) -> void:
	var dmg: int = _stats["atk"] + _rng.randi_range(-1, 1)
	var pierce := false
	if _hero.id == "gunslinger":
		var g: Dictionary = guns[_gun]
		dmg = g["dmg"] + _rng.randi_range(-1, 1)
		_hero.shots[_gun] = int(_hero.shots.get(_gun, 0)) + 1
		_result["shots"][_gun] = int(_result["shots"].get(_gun, 0)) + 1
		if _gun == "energy":
			pierce = true
			_hero.charge = 0
		else:
			var ammo := _hero.ammo()
			if not ammo.is_empty():
				for t in ammo["vs"]:
					if target["tags"].has(t):
						if ammo.has("pierce"):
							pierce = true
						else:
							dmg = roundi(dmg * ammo.get("mult", 1.0))
						break
	if target["special"] == "swift" and _rng.randf() < 0.33:
		_pop(_enemy_rect(target), "miss", Color("#9a90b2"))
	else:
		_damage(target, dmg, pierce, Color("#dcd6e8"))
	_bump(_hero_rect, 3)
	if _hero.id == "gunslinger" and _gun == "energy":
		_choose_gun()


func _damage(e: Dictionary, dmg: int, pierce: bool, col: Color) -> void:
	var taken := dmg if pierce else maxi(ceili(dmg * 0.5), dmg - int(e["armor"]))
	e["hp"] -= taken
	_pop(_enemy_rect(e), "-%d" % taken, col)
	if e["special"] == "relentless":
		e["atk"] += 1
	if e["hp"] <= 0:
		_result["kills"].append(e["id"])
		_result["xp"] += int(e["max"]) / 2 + 3
		_enemy_rect(e).modulate = Color(1, 1, 1, 0.35)
		if _hero.id == "gunslinger":
			_choose_gun()


func _enemy_attack(e: Dictionary) -> void:
	var hits := 1
	var hit: int = int(e["atk"]) + _rng.randi_range(-1, 1)
	if e["special"] == "volley":
		hits = 2
		hit = maxi(1, hit / 2 + 1)
	for i in range(hits):
		_take_hit(e, hit)
	_bump(_enemy_rect(e), -3)


func _take_hit(e: Dictionary, hit: int) -> void:
	var dodge_at := maxi(1, 5 - int(_stats["dodge"]) - (1 if _hero.behaviors.get("dodge_small", false) else 0))
	var reserve := 1 if _hero.behaviors.get("save_one", false) else 0
	if _hero.id == "oracle" and hit >= dodge_at and _free_dodge:
		_free_dodge = false
		_pop(_hero_rect, "Foreseen", Color("#9fe0e6"))
		return
	if _hero.id == "oracle" and hit >= dodge_at and _foresight > reserve:
		_foresight -= 1
		_pop(_hero_rect, "Foreseen", Color("#9fe0e6"))
		return
	var taken := maxi(ceili(hit * 0.4), hit - int(_stats["armor"]))
	if _shield > 0:
		var absorbed := mini(_shield, taken)
		_shield -= absorbed
		taken -= absorbed
		_pop(_hero_rect, "Shield -%d" % absorbed, Color("#9fe0e6"))
		if taken <= 0:
			return
	_hero_hp -= taken
	_pop(_hero_rect, "-%d" % taken, Color("#e3907a"))
	if e["special"] == "siphon":
		e["hp"] = mini(int(e["max"]), e["hp"] + taken / 2)
	if e["special"] == "shock":
		if _hero.id == "oracle" and _foresight > 0:
			_foresight -= 1
		elif _hero.id == "gunslinger":
			_hero.charge = maxi(0, _hero.charge - 1)
	var patch: bool = _hero.id != "engineer" or _hero.behaviors.get("patch_low", true)
	if patch and _hero_hp > 0 and _hero_hp < _hero_max * 0.4 and _supplies > 0:
		_supplies -= 1
		_hero_hp = mini(_hero_max, _hero_hp + 10)
		_pop(_hero_rect, "Draught +10", Color("#9fe0e6"))


func _end(won: bool) -> void:
	_running = false
	if won and _hero.id == "engineer" and _hero.skills["swarm"] >= 1:
		_hero_hp = mini(_hero_max, _hero_hp + 3)
	_title.text = "VICTORY" if won else "DEFEATED"
	_update_bars()
	await get_tree().create_timer(0.7).timeout
	visible = false
	finished.emit(won, maxi(_hero_hp, 0), _foresight, _supplies, _result)


# ------------------------------------------------------------------ display
func _enemy_rect(e: Dictionary) -> Control:
	return _enemy_boxes[_enemies.find(e)][0]


func _update_bars() -> void:
	_hero_bar.size.x = 44.0 * clampf(float(_hero_hp) / _hero_max, 0.0, 1.0)
	_hero_hp_label.text = "%d / %d" % [maxi(_hero_hp, 0), _hero_max]
	var extras := []
	if _hero.id == "oracle":
		extras.append("Foresight %d" % _foresight)
	if _shield > 0:
		extras.append("Shield %d" % _shield)
	if _hero.id == "gunslinger":
		extras.append("%s  charge %d" % [_hero.guns()[_gun]["name"], _hero.charge])
	_hero_note.text = "  ".join(extras)
	for i in range(_enemies.size()):
		var e: Dictionary = _enemies[i]
		var box: Array = _enemy_boxes[i]
		box[1].size.x = 44.0 * clampf(float(e["hp"]) / float(e["max"]), 0.0, 1.0)
		box[2].text = "%d / %d" % [maxi(e["hp"], 0), int(e["max"])] + ("  stunned" if e["stun"] > 0.0 else "")


func _bump(rect: Control, dx: float) -> void:
	var tw := rect.create_tween()
	tw.tween_property(rect, "position:x", rect.position.x + dx, 0.06)
	tw.tween_property(rect, "position:x", rect.position.x, 0.08)


func _pop(anchor: Control, text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 11)
	l.position = anchor.global_position + Vector2(anchor.size.x / 2 - 8, -4) - global_position
	add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 8, 0.5)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)
