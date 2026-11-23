extends Node
## Development helper: plays through Act I by calling the game's functions directly, and
## prints what happened. Run with:  godot --path . -- --test

var main: Node
var map: MaelstromMap
var fails := 0


func check(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


func _skip_dialog() -> void:
	for i in range(60):
		if not main.hud.screens._dialog.visible:
			break
		if main.hud.screens._choice_open:
			main.hud.screens.resolve_choice(randi() % 2)
		else:
			main.hud.screens.advance()
		await get_tree().process_frame


func _wait_territory(frames: int = 400) -> void:
	for i in range(frames):
		await get_tree().process_frame
		await _skip_dialog()
		if main.hud.tactics.visible:
			await FightAI.play(main.hud.tactics, self)
		if main.mode == "territory" and not main._story_busy and not main.hud.tactics.visible and not main.hud.screens._dialog.visible:
			break


## Brings a lead home, retrying a lost fight up to three times.
func _lead(lead: String) -> bool:
	for attempt in range(3):
		var pos := _lead_pos(lead)
		if pos == Vector2i(-99, -99):
			return false
		main.heroes[main.active].injured = false
		await _expedition(pos)
		if Story.state["leads_done"].has(lead):
			return true
		print("      lead %s: attempt %d failed (route %d, camps %d, hp %d, day %d, banner: %s)" % [lead, attempt + 1, main.route.size(), main._camps.size(), main.hero_hp, main.day, main.hud._banner_label.text])
	return false


## Walks the active hero to a target and brings it home, playing out fights with a simple script.
func _expedition(pos: Vector2i) -> bool:
	main._start_expedition(pos)
	if main.mode != "expedition":
		return false
	for i in range(500):
		if main.mode == "expedition":
			main._step()
		while main.mode == "battle" and main.hud.battle.visible:
			await get_tree().process_frame
		if main.hud.tactics.visible:
			await FightAI.play(main.hud.tactics, self)
		await get_tree().process_frame
		await _skip_dialog()
		if main.mode == "territory":
			break
		if main.mode == "battle" and not main.hud.battle.visible and not main.hud.tactics.visible:
			for k in range(120):
				await get_tree().process_frame
				await _skip_dialog()
				if main.mode == "territory":
					break
	await _wait_territory(200)
	return main.mode == "territory"


func _lead_pos(lead: String) -> Vector2i:
	for p in map.lead_cells():
		if map.lead_cells()[p] == lead:
			return p
	return Vector2i(-99, -99)


## Builds a structure on the first valid tile of the active hero's land. Returns the tile or NONE.
func _build(id: String) -> Vector2i:
	main.begin_build(id)
	if main.mode != "build":
		print("      build %s: could not begin (count %d, afford %s)" % [id, main.struct_count(id), str(main.can_afford(main.struct_cost(id)))])
		return MaelstromMap.NONE
	var best := MaelstromMap.NONE
	for pos in map.land_of(main.active):
		if main.place_reason(id, pos) == "":
			best = pos
			break
	if best == MaelstromMap.NONE:
		main.cancel_build()
		return MaelstromMap.NONE
	main.place_structure(best)
	await get_tree().process_frame
	return best if map.cells[best].has("structure") else MaelstromMap.NONE


func _talk_all(region: String) -> void:
	for id in Story.people_in(region):
		while Story.has_news(id):
			main.on_heard(id, Story.hear(id))


## Grows a hero's land toward a point by repeated expeditions with a full hand of tiles.
func _grow_toward(hero_id: String, goal: Vector2i, max_trips: int) -> int:
	var trips := 0
	while trips < max_trips and not map.land_of(hero_id).has(goal):
		main.switch_hero(hero_id)
		var best := Vector2i(-99, -99)
		var bd := 999
		for g in map.glimpses[hero_id]:
			var d := Hex.distance(g, goal)
			if d < bd:
				bd = d
				best = g
		if best == Vector2i(-99, -99):
			main.advance_day()
			await _wait_territory(60)
			trips += 1
			continue
		if hero_id == "gunslinger" and main.stock["parts"] < 4:
			main.stock["parts"] += 4
		if hero_id == "engineer" and main.stock["power"] < 6:
			main.stock["power"] += 6
		main._start_expedition(best)
		if main.mode != "expedition":
			trips += 1
			continue
		# shape every hex beside the glimpse so the fragment is as big as the pack allows
		main.hand = []
		for i in range(6):
			main.hand.append(main._draw_card())
		for n in Hex.neighbors(best):
			if map.can_shape(n, main.route) and not main.hand.is_empty():
				main.selected = 0
				main._on_click(n, MOUSE_BUTTON_LEFT)
		for i in range(500):
			if main.mode == "expedition":
				main._step()
			while main.mode == "battle" and main.hud.battle.visible:
				await get_tree().process_frame
			await get_tree().process_frame
			await _skip_dialog()
			if main.mode == "territory":
				break
			if main.mode == "battle" and not main.hud.battle.visible:
				for k in range(120):
					await get_tree().process_frame
					if main.mode == "territory":
						break
		await _wait_territory(200)
		trips += 1
		var bd2 := 99
		for pos in map.land_of(hero_id):
			bd2 = mini(bd2, Hex.distance(pos, goal))
		print("      trip %d: %s land %d, %d hexes from goal, glimpse %s, mode %s" % [trips, hero_id, map.land_of(hero_id).size(), bd2, str(best), main.mode])
	return trips


func _ready() -> void:
	await get_tree().process_frame
	main = get_parent()
	map = main.map
	main.set_process(false)
	main.hud.screens.close()
	await _skip_dialog()

	# ================================================================ chapter 1
	print("--- Chapter 1")
	_talk_all("oracle")
	check(Story.state["leads_active"].size() == 3, "three leads after talking to the town")
	check(map.lead_cells().size() == 3, "three lead fragments placed: %s" % str(map.lead_cells()))
	var far := 99
	for pos in map.land_of("oracle"):
		far = mini(far, Hex.distance(pos, _lead_pos("bell")))
	check(far >= 5, "the first lead is a journey: %d tiles past the town's edge" % far)
	main._ambience()
	await get_tree().create_timer(0.3).timeout
	check(Ambience._bed[Ambience._bed_i].stream != null and Ambience._bed[Ambience._bed_i].playing, "the town's ambience is playing")
	check(Ambience._hbed[Ambience._hbed_i].stream != null, "the Oracleborn's layer is loaded")
	for lead in ["bell", "crypt", "lamp"]:
		check(_lead_pos(lead) != Vector2i(-99, -99), "lead %s is on the map" % lead)
		var ok := await _lead(lead)
		check(ok, "lead %s brought home" % lead)
		_talk_all("oracle")
	check(main.heroes["oracle"].inventory.has("lamplighter_cloak"), "Maren's coat received")
	main.advance_day()
	main.advance_day()
	var read_any := false
	for w in ["frozen", "hollow", "eroded"]:
		if main._can_read(w):
			var r: Dictionary = Story.read(w)
			main._gain_vision(r["vision"])
			read_any = true
	check(read_any, "read the past at least once")
	_talk_all("oracle")
	check(_lead_pos("throne") != Vector2i(-99, -99), "throne hall placed")
	var ok := await _lead("throne")
	check(ok, "throne hall won")
	_talk_all("oracle")
	check(Story.flag("ch1_done"), "chapter 1 complete")

	# ================================================================ the Way
	var with_notes := 0
	var done_notes := 0
	var kinds := {}
	for pos in map.cells:
		for n in map.cells[pos].get("notables", []):
			with_notes += 1
			kinds[n["type"]] = int(kinds.get(n["type"], 0)) + 1
			if n["done"]:
				done_notes += 1
	check(with_notes >= 4, "the road placed notables on world tiles (%d: %s)" % [with_notes, str(kinds)])
	check(done_notes >= 3, "some were examined and the tiles remember it (%d done)" % done_notes)
	check(main.way.stretches.size() >= 3, "the last trip walked %d stretches of road" % main.way.stretches.size())
	var known := 0
	for pos in map.cells:
		if map.cells[pos].get("known", false):
			known += 1
	check(known >= 2, "walked tiles' notables are known on the world map (%d tiles)" % known)


	# ================================================================ structures (the town)
	print("--- Structures")
	for r in Worlds.RESOURCES:
		main.stock[r] += 40
	var fs_before: int = main.heroes["oracle"].stats()["fs"]
	var glimpses_before: int = map.glimpse_count["oracle"]
	check(main.structures_for("oracle") == ["lamps", "infirmary", "shrine"], "the town builds its own three structures: %s" % str(main.structures_for("oracle")))
	var placed := await _build("lamps")
	check(placed != MaelstromMap.NONE, "lamps placed at %s (%s ground)" % [str(placed), map.cells[placed]["world"] if placed != MaelstromMap.NONE else "-"])
	check(map.glimpse_count["oracle"] == glimpses_before + 1, "lamps add a glimpse (%d -> %d)" % [glimpses_before, map.glimpse_count["oracle"]])
	var shrine := await _build("shrine")
	check(shrine != MaelstromMap.NONE, "shrine placed on %s ground" % (map.cells[shrine]["world"] if shrine != MaelstromMap.NONE else "-"))
	var fx: Dictionary = main.struct_fx("oracle")
	check(not fx.is_empty(), "structure effects published: %s" % str(fx))
	if shrine != MaelstromMap.NONE and map.cells[shrine]["world"] == "kingdom":
		check(main.heroes["oracle"].stats()["fs"] == fs_before + 1, "a shrine on Kingdom ground gives Foresight (%d -> %d)" % [fs_before, main.heroes["oracle"].stats()["fs"]])
	var inf := await _build("infirmary")
	check(inf != MaelstromMap.NONE, "infirmary placed beside a house")
	check(Rules.produces(map.cells[placed]) == false, "a structure's tile stops yielding")
	main.heroes["oracle"].injured = true
	main.advance_day()
	check(not main.heroes["oracle"].injured, "the infirmary heals after a day")
	check(main.structures().size() == 3, "three structures standing")
	# damage and repair
	map.cells[placed]["structure"]["damaged"] = true
	map.refresh(placed)
	check(main.struct_effects(main.structures().filter(func(st): return st["pos"] == placed)[0]).is_empty(), "a damaged structure does nothing")
	main.active = "oracle"
	main.repair_structure(placed)
	check(not map.cells[placed]["structure"]["damaged"], "repair with the ground's material")
	check(main.struct_count("lamps") == 1 and main.struct_cost("lamps")["sunstone"] == 12, "second lamps cost double")
	# the Documenter spoke in the past tense before the Engineer
	var doc_then := Documenter.record().filter(func(r): return r.get("tense", "") == "then")
	check(not doc_then.is_empty(), "the Documenter remarked in the past tense (%d lines)" % doc_then.size())

	# ================================================================ chapter 2
	print("--- Chapter 2")
	main.check_story()
	await _wait_territory(600)
	check(main.heroes.has("engineer") and Story.hero_unlocked("engineer"), "the Engineer is playable")
	check(map.open_regions.has("engineer") and map.cells[MaelstromMap.HOMES["engineer"]]["layout"] == "mast", "the Engineer's region opened")
	check(main.heroes["engineer"].level >= 1 and main.heroes["engineer"].xp + main.heroes["engineer"].level > 1, "the ambush gave XP (level %d, xp %d)" % [main.heroes["engineer"].level, main.heroes["engineer"].xp])
	main.switch_hero("engineer")
	check(main.active == "engineer", "switched to the Engineer")
	_talk_all("engineer")
	check(main.heroes["engineer"].inventory.has("players_jacket"), "the Player's jacket from the grave")
	check(_lead_pos("cache") != Vector2i(-99, -99) and _lead_pos("cauldron") != Vector2i(-99, -99), "the Documenter's leads placed")
	for lead in ["cache", "cauldron"]:
		main.stock["power"] += 6
		ok = await _lead(lead)
		check(ok, "lead %s brought home" % lead)
	check(main.heroes["engineer"].inventory.has("shield_drone"), "shield drone from the cache")
	# anchors, power and a law
	var before_power: int = main.stock["power"]
	main.advance_day()
	check(main.stock["power"] != before_power, "power changes day to day (%d -> %d)" % [before_power, main.stock["power"]])
	var trips := await _grow_toward("engineer", MaelstromMap.HOMES["engineer"] + Vector2i(0, 3), 4)
	main.advance_day()
	main.advance_day()
	check(not Story.state["laws"].is_empty(), "a law was written after %d trips: %s (stable leader %d, coven %d)" % [trips, str(Story.state["laws"]),
		map.stable_count("engineer", "leader"), map.stable_count("engineer", "coven")])
	if Story.state["laws"].is_empty():
		Story.learn_law("leader")
	# skills
	main.heroes["engineer"].gain_xp(60)
	check(main.heroes["engineer"].skill_points > 0, "skill points from XP (level %d)" % main.heroes["engineer"].level)
	main.heroes["engineer"].learn("constructs")
	main.heroes["engineer"].learn("constructs")
	check(main.heroes["engineer"].unlocked.has("construct2"), "second construct slot from the skill")
	check(main.heroes["engineer"].equip("shield_drone") == "", "shield drone equipped into the second slot")
	check(main.heroes["engineer"].equip("tower_plate") == "" if main.heroes["engineer"].inventory.has("tower_plate") else true, "heavy armor allowed for the Engineer")
	# power failure releases an anchor
	main.stock["power"] = 0
	var land_before: int = map.land_of("engineer").size()
	main.advance_day()
	check(map.land_of("engineer").size() <= land_before, "an anchor fails without power (%d -> %d tiles)" % [land_before, map.land_of("engineer").size()])
	_talk_all("engineer")
	check(Story.flag("ch2_done"), "chapter 2 complete")

	# ================================================================ chapter 3
	print("--- Chapter 3")
	main.check_story()
	await _wait_territory(800)
	check(main.heroes.has("gunslinger") and Story.hero_unlocked("gunslinger"), "Alysia is playable")
	check(map.open_regions.has("gunslinger") and map.cells[MaelstromMap.HOMES["gunslinger"]]["layout"] == "pallas_core", "Pallas is on the map")
	main.switch_hero("gunslinger")
	_talk_all("gunslinger")
	for lead in ["rig", "pod"]:
		check(_lead_pos(lead) != Vector2i(-99, -99), "lead %s placed" % lead)
		main.stock["parts"] += 3
		ok = await _lead(lead)
		check(ok, "lead %s brought home" % lead)
		_talk_all("gunslinger")
	check(_lead_pos("saloon") != Vector2i(-99, -99), "the saloon town lead placed")
	ok = await _lead("saloon")
	check(ok and int(Story.state["people"]) >= 9, "the saloon town joined (%d people)" % int(Story.state["people"]))
	_talk_all("gunslinger")
	check(Story.flag("outpost"), "Pallas is an outpost")
	check(main.heroes["gunslinger"].inventory.has("franklin_sidearm"), "Franklin's sidearm received")
	check(main.heroes["gunslinger"].equip("ammo_ap") == "", "AP rounds equipped")
	check(main.heroes["gunslinger"].mastery("python") >= 0 and main.heroes["gunslinger"].shots.values().reduce(func(a, b): return a + b, 0) > 0, "shots were fired (%s)" % str(main.heroes["gunslinger"].shots))
	# parts limit the tethers
	main.stock["parts"] = 0
	var land_g: int = map.land_of("gunslinger").size()
	main.switch_hero("gunslinger")
	if not map.glimpses["gunslinger"].is_empty():
		main._start_expedition(map.glimpses["gunslinger"][0])
		if main.mode == "expedition":
			main.step_index = main.route.size() - 1
			main._return_home("success")
			await _wait_territory(100)
	check(map.land_of("gunslinger").size() == land_g, "no parts, no tethered land (%d -> %d)" % [land_g, map.land_of("gunslinger").size()])

	# ================================================================ act I: connect the regions
	print("--- Act I: connecting")
	main.stock["parts"] += 30
	main.stock["power"] += 30
	var t1 := await _grow_toward("oracle", MaelstromMap.HOMES["gunslinger"], 22)
	check(map.connected("oracle", "gunslinger") or map.connected("gunslinger", "any"), "the Oracleborn's land reached Pallas in %d trips (connected: %s)" % [t1, str(map.connected("oracle", "gunslinger"))])
	main.check_story()
	await _wait_territory(300)
	check(Story.seen("meet_gunslinger") == map.connected("gunslinger", "any"), "meeting the gunslinger played: %s" % str(Story.seen("meet_gunslinger")))
	var goal := MaelstromMap.HOMES["gunslinger"]
	var gd := 999
	for pos in map.land_of("oracle"):
		var d := Hex.distance(pos, MaelstromMap.HOMES["engineer"])
		if d < gd:
			gd = d
			goal = pos
	var t2 := await _grow_toward("engineer", goal, 26)
	main.check_story()
	await _wait_territory(300)
	check(map.connected("oracle", "engineer"), "all three regions connected after %d more trips" % t2)
	await _wait_territory(300)
	main.check_story()
	await _wait_territory(300)
	check(Story.flag("act1_done"), "Act I complete (scenes seen: %s)" % str(Story.state["scenes_seen"]))
	check(main.camps_made >= 3, "heroes made camp on the road %d times" % main.camps_made)
	var talks: Array = Story.state["scenes_seen"].filter(func(x): return String(x).begins_with("talk_"))
	check(talks.size() >= 2, "heroes talked to each other at home: %s" % str(talks))
	check(Story.state.get("tile_lines", []).size() >= 3, "the map spoke when land was shaped (%d lines)" % Story.state.get("tile_lines", []).size())
	main.switch_hero("oracle")
	main.hero_hp = main.hero().stats()["hp"]
	check(main.threat(["drifter"]) == 0 and main.threat(["armored_man"]) == 3, "danger reads right: a drifter is easy, the armored man is deadly")
	var lines_before: int = Documenter.record().size()
	check(lines_before >= 15, "the Documenter has plenty to say (%d lines so far)" % lines_before)
	# talk of the town
	while TownTalk.has_word("pell"):
		TownTalk.take_word("pell")
	TownTalk._given().erase("tithe_box")
	TownTalk.note_examined("tithe_box")
	check(TownTalk.has_word("pell"), "Pell has a word about the tithe box")
	check(main.town_chatter("pell").begins_with("A tithe box"), "and says it when greeted")
	var rumour := ""
	var known_before := 0
	for pos in map.cells:
		if map.cells[pos].get("known", false):
			known_before += 1
	while TownTalk.has_word("maren"):
		TownTalk.take_word("maren")
	for tries in range(30):
		Story.state["rumour_day"] = {}
		rumour = main.town_chatter("maren")
		if rumour != "":
			break
	var known_after := 0
	for pos in map.cells:
		if map.cells[pos].get("known", false):
			known_after += 1
	check(rumour != "" and known_after > known_before, "Maren tells a rumour and the place is marked: \"%s\"" % rumour)
	# a ruin story keeps its own time
	var ruin := {"world": "eroded", "notables": [{"type": "story", "id": "the_car", "stage": 1, "done": true, "ready_day": main.day + 2}]}
	Notables.wake_stories(ruin, main.day)
	check(ruin["notables"][0]["done"], "a ruin story stays quiet for a while after a visit")
	Notables.wake_stories(ruin, main.day + 2)
	check(not ruin["notables"][0]["done"], "then something has changed there")
	var stories := 0
	for pos in map.cells:
		for n in map.cells[pos].get("notables", []):
			if n["type"] == "story":
				stories += 1
	check(stories >= 1, "ruin stories took root on the road (%d)" % stories)
	# planning: route through a tile off the direct way
	var g2: Vector2i = map.glimpses[main.active][0]
	main._start_expedition(g2)
	var direct: int = main.route.size()
	var wp := MaelstromMap.NONE
	for pos in map.cells:
		if not main.route.has(pos) and not map.land_of(main.active).has(pos) and Hex.distance(pos, main.route[direct / 2]) == 1:
			wp = pos
			break
	main._toggle_waypoint(wp)
	check(main.route.has(wp) and main.route.size() <= direct + main.ROUTE_SLACK, "a waypoint bends the route through it (%d -> %d tiles)" % [direct, main.route.size()])
	check(map.protect.is_empty(), "nothing is protected from the Drift before setting out")
	main._step()
	check(map.protect.has(g2), "once out, the road and destination are protected from the Drift")
	main._return_home("retreat")
	await _wait_territory()
	main.switch_hero("oracle")
	var avail: Array = main.structures_for("oracle")
	check(avail.has("capacitor") and avail.has("winch"), "joined heroes' structures open in the capital: %s" % str(avail))
	for r in Worlds.RESOURCES:
		main.stock[r] += 40
	var cap := await _build("capacitor")
	check(cap != MaelstromMap.NONE, "a capacitor placed in the joined land, touching Leaderboard land or the mast")
	var mess := await _build("mess_hall")
	check(mess != MaelstromMap.NONE and int(main.struct_fx("oracle").get("mess", 0)) > 0, "a mess hall in the capital feeds the Oracleborn too: three actions at camp")
	var power_fx: int = int(main.struct_fx("engineer").get("power", 0))
	check(power_fx >= 1, "capacitor power reaches the Engineer through the joined land (+%d)" % power_fx)
	var doc_now := Documenter.record().filter(func(r): return r.get("tense", "") == "now")
	check(not doc_now.is_empty(), "the Documenter logged in the present tense with the Engineer (%d lines)" % doc_now.size())

	# ================================================================ save and load
	main._scripted = false
	main.save_game()
	var day_before: int = main.day
	var heroes_before: int = main.heroes.size()
	var cells_before: int = map.cells.size()
	check(main.load_game(), "save loads")
	check(main.day == day_before and main.heroes.size() == heroes_before and map.cells.size() == cells_before, "save round trip keeps day, heroes and land")
	main.start_over()
	check(main.day == 1 and main.heroes.size() == 1, "start over resets")
	main._scripted = true
	print("FAILURES: %d  (day %d)" % [fails, day_before])
	get_tree().quit()
