extends Node
## Balance simulator: unlocks every hero, runs many expeditions per hero with random
## tile shaping, and prints fight statistics. Run with:  godot --path . -- --sim

const TRIPS_PER_HERO := 14

var main: Node
var map: MaelstromMap
var fights := []   # {hero, enemies, won, hp_before, hp_after, steps}
var trips := []    # {hero, outcome, tiles, loot, fights}
var drops := {"oracle": 0, "engineer": 0, "gunslinger": 0}
var events := 0


func _ready() -> void:
	await get_tree().process_frame
	main = get_parent()
	map = main.map
	main.set_process(false)
	Engine.time_scale = 8.0
	_skip()
	# sandbox: every hero, every region, a bit of gear
	for h in ["engineer", "gunslinger"]:
		main.heroes[h] = HeroState.new(h)
		Story.unlock_hero(h)
		map.open_region(h)
	main.stock["power"] = 200
	main.stock["parts"] = 200
	main.hud.battle.finished.connect(_on_fight)
	for h in ["oracle", "engineer", "gunslinger"]:
		for t in range(TRIPS_PER_HERO):
			await _trip(h, t)
			if t % 3 == 2:
				main._on_wait()
				await get_tree().process_frame
				_skip()
	_report()
	get_tree().quit()


func _skip() -> void:
	main.hud.screens.close()
	for i in range(40):
		if not main.hud.screens._dialog.visible:
			break
		if main.hud.screens._choice_open:
			events += 1
			main.hud.screens.resolve_choice(randi() % 2)
		else:
			main.hud.screens.advance()


var _hp_before := 0


func _trip(h: String, t: int) -> void:
	main.switch_hero(h)
	main.heroes[h].injured = false
	if map.glimpses[h].is_empty():
		main.advance_day()
		await get_tree().process_frame
		_skip()
		return
	var g: Vector2i = map.glimpses[h][t % map.glimpses[h].size()]
	main._start_expedition(g)
	if main.mode != "expedition":
		main.advance_day()
		_skip()
		return
	var shaped := 0
	var want := t % 4  # 0..3 tiles beside the route, more on later trips
	main.hand = []
	for i in range(6):
		main.hand.append(main._draw_card())
	for r in main.route:
		for n in Hex.neighbors(r):
			if shaped < want and map.can_shape(n, main.route) and not main.hand.is_empty():
				main.selected = 0
				main._on_click(n, MOUSE_BUTTON_LEFT)
				shaped += 1
	var fights_before := fights.size()
	var start_hp: int = main.hero_hp
	for i in range(500):
		if main.mode == "expedition":
			_hp_before = main.hero_hp
			main._step()
			_skip()
		var waited := 0
		while main.mode == "battle" and waited < 4000:
			await get_tree().process_frame
			waited += 1
			if main.hud.screens._dialog.visible:
				_skip()
		if main.hud.tactics.visible:
			main.hud.tactics.visible = false
			main._return_home("retreat")
		await get_tree().process_frame
		_skip()
		if main.mode == "territory":
			break
	var outcome := "success" if main.heroes[h].injured == false and main.mode == "territory" else "defeat"
	trips.append({"hero": h, "tiles": shaped, "fights": fights.size() - fights_before, "start_hp": start_hp, "injured": main.heroes[h].injured})
	_skip()


func _on_fight(won: bool, hp: int, _fs: int, _sup: int, result: Dictionary) -> void:
	fights.append({"hero": main.active, "enemies": main.hud.battle._enemies.map(func(e): return e["id"]), "won": won,
		"hp_before": _hp_before, "hp_after": hp, "kills": result["kills"].size(), "notes": result["notes"]})


func _report() -> void:
	print("=== SIM REPORT (%d trips, %d fights) ===" % [trips.size(), fights.size()])
	for h in ["oracle", "engineer", "gunslinger"]:
		var hf := fights.filter(func(f): return f["hero"] == h)
		var wins := hf.filter(func(f): return f["won"]).size()
		var lost := 0
		for f in hf:
			lost += f["hp_before"] - f["hp_after"]
		var ht := trips.filter(func(t): return t["hero"] == h)
		var inj := ht.filter(func(t): return t["injured"]).size()
		print("%-10s fights %2d  won %2d  avg hp lost %5.1f  trips %2d  injured %d  items %d" % [h, hf.size(), wins,
			float(lost) / maxi(1, hf.size()), ht.size(), inj, main.heroes[h].inventory.size()])
	var by_enemy := {}
	for f in fights:
		var key := ",".join(f["enemies"])
		if not by_enemy.has(key):
			by_enemy[key] = {"n": 0, "won": 0, "lost": 0}
		by_enemy[key]["n"] += 1
		by_enemy[key]["won"] += 1 if f["won"] else 0
		by_enemy[key]["lost"] += f["hp_before"] - f["hp_after"]
	var keys := by_enemy.keys()
	keys.sort_custom(func(a, b): return by_enemy[a]["n"] > by_enemy[b]["n"])
	for k in keys:
		var e: Dictionary = by_enemy[k]
		print("  %-32s n=%2d won=%2d avg hp lost=%5.1f" % [k, e["n"], e["won"], float(e["lost"]) / e["n"]])
	var fugue := 0
	for f in fights:
		if f["hero"] == "engineer" and not f["notes"].is_empty():
			fugue += 1
	print("engineer fugue triggers: %d of %d fights" % [fugue, fights.filter(func(f): return f["hero"] == "engineer").size()])
	print("stock: %s" % str(main.stock))
	print("combos: %s" % str(main.discovered))
	print("day: %d, choices answered: %d, omens: %d" % [main.day, events, Story.state["omens"].size()])
