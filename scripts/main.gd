extends Node2D
## Game flow for Act I.
##
## Territory: look over the active hero's land, pick a glimpse or a lead in the fog (or wait a day).
## Expedition: the hero walks the route on their own. Place tiles from your hand beside the
##   route: they pay out as the hero passes and draw encounters.
##   Land shaped next to the glimpse comes home with it (up to the pack limit).
## Return: the fragment fuses onto the edge of that hero's territory and settles for 2 days.
##   The Oracleborn's pillar holds land for free; the Engineer's anchors draw Power each day;
##   Alysia's tethers cost Parts to set.
## Chapters: talk to the people of each region, follow their leads, and the story moves on.
##   The regions connect when their land meets; Act I ends when all three have.

const STEP_TIME := 1.1
const MAX_HAND := 6
const START_HAND := 3
const DRAW_CHANCE := 0.45
const ENCOUNTER_BASE := 0.22
const ENCOUNTER_PER_SHAPED := 0.08
const ENCOUNTER_PER_LURE := 0.12
const PAIR_CHANCE := 0.3
const EVENT_CHANCE := 0.22
const NIGHT_EVENT_CHANCE := 0.45
const MAELSTROM_CHANCE := 0.06
const SHIFT_EVERY := 3
const FRAGMENT_LIMIT := 3
const DROP_CHANCE := 0.25
const SURVIVOR_CHANCE := 0.3
const REST_COST := 6
const MAST_POWER := 2
const SAVE_PATH := "user://maelstrom_save.json"
const SAVE_VERSION := 3

var map: MaelstromMap
var hud: Hud
var camera: Camera2D
var rng := RandomNumberGenerator.new()

var mode := "territory"  # territory, expedition, battle
var day := 1
var stock := {}
var discovered: Array = []
var heroes := {}
var active := "oracle"

var route: Array[Vector2i] = []
var target := MaelstromMap.NONE
var step_index := 0
var step_timer := 0.0
var paused := false
var hand: Array = []
var selected := -1
var loot := {}
var hero_hp := 0
var foresight := 0
var supplies := 0
var _hover := MaelstromMap.NONE
var _scripted := false
var _story_busy := false
var _cam_target := Vector2.ZERO
var _void: Sprite2D


func _ready() -> void:
	rng.seed = 7
	for r in Worlds.RESOURCES:
		stock[r] = 0

	map = MaelstromMap.new()
	_void = Sprite2D.new()
	_void.centered = false
	_void.z_index = -10
	var size := map.pixel_size()
	_void.texture = TileFactory.make_void(int(size.x / 2), int(size.y / 2))
	_void.scale = Vector2(2, 2)
	add_child(_void)
	add_child(map)
	map.cell_hovered.connect(_on_hover)
	map.cell_clicked.connect(_on_click)
	way = Way.new()
	way.visible = false
	way.position = Vector2(0, size.y + 400)
	add_child(way)
	way.notable_hovered.connect(func(t: String) -> void: hud.show_tip(t) if way_phase == "walk" and not hud.screens.is_open() else null)
	way.notable_clicked.connect(_on_notable_clicked)

	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(size.x)
	camera.limit_bottom = int(size.y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 4.0
	add_child(camera)
	_add_ash()

	fx = PostFx.new()
	add_child(fx)

	hud = Hud.new()
	add_child(hud)
	hud.card_pressed.connect(_select)
	hud.wait_pressed.connect(_on_wait)
	hud.retreat_pressed.connect(_on_retreat)
	hud.pause_pressed.connect(_toggle_pause)
	hud.map_pressed.connect(_toggle_map)
	hud.bandage_pressed.connect(bandage)
	hud.battle.finished.connect(_on_battle_finished)
	hud.tactics.finished.connect(_on_tactics_finished)
	hud.screen_pressed.connect(open_screen)
	hud.hero_pressed.connect(switch_hero)
	hud.screens.game = self
	hud.screens.closed.connect(_on_screen_closed)
	Story.connected_check = map.connected
	Documenter.bind(hud.documenter_line)
	Story.level_check = func(h: String) -> int: return heroes[h].level if heroes.has(h) else 0

	var shot_path := ""
	var test := false
	var sim := false
	var fights := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			shot_path = arg.substr(7)
		test = test or arg == "--test"
		sim = sim or arg == "--sim"
		fights = fights or arg == "--fights"
	_scripted = shot_path != "" or test or sim or fights
	if _scripted or not load_game():
		new_game()
	if shot_path != "":
		var shot: Node = load("res://tools/screenshot.gd").new()
		shot.path = shot_path
		add_child(shot)
	elif test:
		add_child(load("res://tools/chapter_test.gd").new())
	elif sim:
		add_child(load("res://tools/sim.gd").new())
	elif fights:
		add_child(load("res://tools/fight_sim.gd").new())


func new_game() -> void:
	Story.reset()
	Events.reset()
	heroes = {"oracle": HeroState.new("oracle")}
	active = "oracle"
	day = 1
	for r in Worlds.RESOURCES:
		stock[r] = 0
	discovered = []
	map.revealed.clear()
	map.generate(1)
	hero_hp = hero().stats()["hp"]
	_enter_territory()
	focus_camera(true)
	if _scripted:
		return
	hud.screens.say("The Oracleborn", [
		"For as long as anyone in town remembers, the pillar in the square has stood dead.",
		"This morning it hummed. When he laid his hand on it, the fog at the edge of town drew back, and the ground beneath held still.",
		"It can hold land now. Out in the fog are pieces of other worlds, drifting. Some of them the townspeople lost.",
	], func() -> void: hud.banner("Talk to the town first (Town button or T).", 4.0))


func hero() -> HeroState:
	return heroes[active]


## Ash, always falling: single pale violet-gray pixels drifting down, following the camera.
func _add_ash() -> void:
	var ash := CPUParticles2D.new()
	ash.amount = 70
	ash.lifetime = 14.0
	ash.preprocess = 14.0
	ash.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ash.emission_rect_extents = Vector2(260, 160)
	ash.direction = Vector2(0.3, 1)
	ash.spread = 25.0
	ash.gravity = Vector2(0, 1.5)
	ash.initial_velocity_min = 3.0
	ash.initial_velocity_max = 7.0
	ash.color = Color(Worlds.ASH, 0.45)
	ash.z_index = 30
	ash.local_coords = false
	camera.add_child(ash)


# ------------------------------------------------------------------ camera and heroes
## Centers the view on the active hero's land (the side panel covers the right of the screen).
func focus_camera(instant: bool = false) -> void:
	_cam_target = map.region_center(active) + Vector2(52, 6)
	if instant:
		camera.position = _cam_target
		camera.reset_smoothing()
	else:
		camera.position = _cam_target


func switch_hero(id: String) -> void:
	if mode != "territory" or not heroes.has(id) or hud.screens.is_open():
		return
	active = id
	map.active_hero = id
	map.hero.texture = TileFactory.hero_texture(id)
	selected = -1
	focus_camera()
	_refresh_hud()
	hud.banner("%s. %s" % [hero().def()["name"], _method_text()], 3.0)


func _method_text() -> String:
	match active:
		"engineer":
			return "Anchored land draws %d Power a day; the mast and capacitors give %d." % [_anchor_count(), MAST_POWER + int(struct_fx("engineer").get("power", 0))]
		"gunslinger":
			return "Tethers cost 1 Part per tile brought home."
	return "The pillar holds land for free."


func _process(delta: float) -> void:
	_ambience()
	if mode == "expedition" and way_phase == "walk" and not hud.screens.is_open():
		if not _pending.is_empty():
			_stop_wait -= delta
			if _stop_wait <= 0.0:
				_pass_notable()
		elif not paused:
			step_timer += delta
			if step_timer >= _walk_time():
				step_timer = 0.0
				_step()
		camera.position = way.hero.global_position + Vector2(70, 0)
	elif mode in ["territory", "build"] and not hud.screens.is_open():
		var pan := Vector2.ZERO
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			pan.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			pan.x += 1
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			pan.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			pan.y += 1
		if pan != Vector2.ZERO:
			camera.position += pan * 120.0 * delta


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if hud.screens.is_open():
		if event.keycode == KEY_ESCAPE and hud.screens.current != "":
			hud.screens.close()
		return
	if mode == "territory" and event.keycode in [KEY_T, KEY_C, KEY_H]:
		open_screen({KEY_T: "town", KEY_C: "chronicle", KEY_H: "hero"}[event.keycode])
		return
	if mode == "territory" and event.keycode == KEY_TAB:
		var ids: Array = heroes.keys()
		switch_hero(ids[(ids.find(active) + 1) % ids.size()])
		return
	if mode == "territory" and event.keycode == KEY_F:
		focus_camera()
		return
	if event.keycode == KEY_N:
		hud.banner("Ambience off." if Ambience.toggle_mute() else "Ambience on.", 2.0)
		return
	if mode == "expedition" and event.keycode == KEY_B:
		bandage()
		return
	if mode == "expedition" and event.keycode == KEY_M:
		_toggle_map()
		return
	if mode == "expedition" and event.keycode == KEY_E and not _pending.is_empty():
		_examine(_pending[0], _pending[1])
		return
	if event.keycode == KEY_SPACE and mode == "expedition":
		_toggle_pause()
	elif event.keycode == KEY_SPACE and mode == "territory":
		_on_wait()
	elif event.keycode >= KEY_1 and event.keycode <= KEY_6:
		_select(event.keycode - KEY_1)
	elif event.keycode == KEY_ESCAPE:
		selected = -1
		if mode == "build":
			cancel_build()
		_refresh_hud()


# ------------------------------------------------------------------ territory
func _enter_territory() -> void:
	mode = "territory"
	selected = -1
	hud.show_tip("")
	map.hero.visible = false
	map.show_markers(true)
	map.show_route([] as Array[Vector2i])
	hud.set_mode(mode)
	_refresh_hud()


## Engineer-anchored tiles beyond his starting ground, each drawing 1 Power a day.
func _anchor_count() -> int:
	var n := 0
	for pos in map.cells:
		var c: Dictionary = map.cells[pos]
		if c.get("owner", "") == "engineer" and c.has("fused_day") and c["state"] in ["stable", "settling"]:
			if Story.law_known("eroded") and c["world"] == "eroded":
				continue
			n += 1
	return n


func advance_day(on_road: bool = false) -> void:
	day += 1
	var settled := 0
	for pos in map.cells:
		var c: Dictionary = map.cells[pos]
		if c["state"] == "settling":
			c["settle"] -= 1
			if c["settle"] <= 0:
				c["state"] = "stable"
				c.erase("previous")
				settled += 1
	var breakdown := Rules.evaluate(map.cells)
	_discover(Rules.combos_in(breakdown))
	var gained := Rules.totals(breakdown)
	for r in Worlds.RESOURCES:
		stock[r] += gained[r]
	var msg := "Day %d" % day
	if settled > 0:
		msg += ". %d tile%s settled for good" % [settled, "" if settled == 1 else "s"]
	# the Engineer's anchors
	if heroes.has("engineer"):
		stock["power"] += MAST_POWER
		var upkeep := _anchor_count()
		stock["power"] -= upkeep
		if stock["power"] < 0:
			stock["power"] = 0
			var lost := _release_newest_anchor()
			if lost != "":
				msg += ". An anchor failed for lack of Power: %s drifted loose" % lost
		_check_laws()
	# Pallas's tether dock turns out spare couplings
	if heroes.has("gunslinger"):
		stock["parts"] += 1 + heroes["gunslinger"].stats()["parts"]
	var shifted := day % SHIFT_EVERY == 0
	if shifted:
		map.drift_shift(day)
		msg += ". The Drift shifts"
	else:
		map.rebuild_all()
	msg += _structures_daily(shifted)
	for h in heroes:
		map.glimpse_count[h] = _glimpse_count(h)
		if heroes[h].injured and struct_fx(h).get("heal", 0) > 0:
			heroes[h].injured = false
			msg += ". %s is healed" % heroes[h].short_name()
	hud.banner(msg + ".")
	if Documenter.remark("shift" if shifted else "day", active, rng, day) == "":
		if Documenter.stage() < 3 or Documenter.remark("musing", active, rng, day) == "":
			_maybe_drone_day()
	_refresh_hud()
	if on_road:
		return  # no saving or story beats while a hero is out on the road
	save_game()
	check_story()


## A rare day entry: a drone sighting written straight into the Omens tab.
const DRONE_DAY_CHANCE := 0.06
func _maybe_drone_day() -> void:
	if rng.randf() > DRONE_DAY_CHANCE:
		return
	for text in Events.DRONE_DAYS:
		if not Story.state["omens"].has(text):
			Story.add_omen(text)
			hud.banner(text, 5.0)
			return


func _glimpse_count(h: String) -> int:
	var n := 3
	if heroes[h].has_vision("drifters_eye"):
		n += 1
	n += int(struct_fx(h).get("glimpse", 0))
	return n


func _release_newest_anchor() -> String:
	var newest := MaelstromMap.NONE
	var newest_day := -1
	for pos in map.cells:
		var c: Dictionary = map.cells[pos]
		if c.get("owner", "") == "engineer" and c.has("fused_day") and c["state"] in ["stable", "settling"] and int(c["fused_day"]) > newest_day:
			newest_day = int(c["fused_day"])
			newest = pos
	if newest == MaelstromMap.NONE:
		return ""
	var name: String = Worlds.LAYOUT_NAMES[map.cells[newest]["layout"]]
	map.release(newest)
	return name


func _check_laws() -> void:
	for w in Story.LAWS:
		if not Story.law_known(w) and map.stable_count("engineer", w) >= int(Story.LAWS[w]["tiles"]):
			Story.learn_law(w)
			Documenter.remark("law", active, rng, day)
			heroes["engineer"].unlock_slot("charm")
			hud.screens.say("The Documenter", [
				"New entry in the Book of Laws: %s. I've been looking forward to writing this one." % Story.LAWS[w]["name"],
				Story.LAWS[w]["text"],
			], Callable())


func _release(pos: Vector2i) -> void:
	var owner: String = map.cells[pos].get("owner", "")
	map.cells[pos] = map.cells[pos]["previous"]
	map.rebuild_all()
	if owner == "gunslinger":
		stock["parts"] += 1
		hud.banner("Released. The tether's coupling is recovered; the land drifts back into the fog.")
	else:
		hud.banner("Released. The land drifts back into the fog.")
	_refresh_hud()


# ------------------------------------------------------------------ expedition
func _start_expedition(to: Vector2i) -> void:
	if hero().injured and not _scripted and not Story.flag("warned_injury_%s" % active):
		Story.set_flag("warned_injury_%s" % active)
		hud.banner("%s is injured: 60%% health this trip. Rest in town first if you can." % hero().short_name(), 4.0)
	route = map.route_to(to, active)
	if route.size() < 2:
		hud.banner("No way through the fog to there.")
		return
	target = to
	waypoints.clear()
	_direct_len = route.size()
	map.show_waypoints([])
	mode = "expedition"
	step_index = 0
	step_timer = 0.0
	paused = false
	loot = {}
	var st := hero().stats()
	hero_hp = int(st["hp"] * (0.6 if hero().injured else 1.0))
	foresight = st["fs"]
	supplies = st["supplies"]
	hero().injured = false
	hand.clear()
	for i in range(START_HAND + st["hand"]):
		hand.append(_draw_card())
	map.show_markers(false)
	map.show_route(route)
	map.hero.texture = TileFactory.hero_texture(active)
	map.hero.visible = true
	map.hero.position = map.center_of(route[0])
	map.reveal_around(route[0])
	map.revealed[target] = true
	map.rebuild_all()
	way_phase = "plan"
	hud.set_way_phase("plan")
	hud.set_mode(mode)
	var mid := Vector2.ZERO
	for pos in route:
		mid += map.center_of(pos)
	camera.position = mid / route.size() + Vector2(60, 0)
	hud.banner("Plan the road: place tiles beside it, or click tiles to route through them. Set out with Space.", 4.5)
	_refresh_hud()


func _draftable() -> Array:
	var out: Array = Worlds.BASE_DRAFTABLE.duplicate()
	if heroes.has("engineer"):
		out.append_array(["leader", "coven"])
	return out


func _draw_card() -> Dictionary:
	var worlds := _draftable()
	var w: String = worlds[rng.randi_range(0, worlds.size() - 1)]
	var layouts: Array = Worlds.world(w)["layouts"]
	return {"world": w, "layout": layouts[rng.randi_range(0, layouts.size() - 1)]}


# ------------------------------------------------------------------ the Way
## An expedition is planned on the world map and walked on the Way: a road built from the
## world tiles the route crosses (see way.gd). main decides what happens at each stop.
var way: Way
var fx: PostFx
var _in_camp := false
var way_phase := ""          # plan | walk | map
var way_index := 0
var _way_done := {}          # "index:n" stops already resolved
var _encounters := {}        # stretch -> enemy ids still waiting on the road
var _enc_shaped := {}        # stretch -> shaped count the roll was made with
var _fighting := -1          # the stretch whose encounter is being fought
var _pending := []           # [stretch, index] of the notable the hero is standing beside
var _stop_wait := 0.0
var _trip_extra := {}        # shaped world cell -> roadside find for this trip
const WALK_TIME := 0.34
const NOTABLE_WAIT := 2.4
const CAMP_EVERY := 3        # stretches walked per day on the road
const ROUTE_SLACK := 4       # extra tiles a planned route may add to the direct way
var _camps := []             # stretch indices whose exits are camps
var waypoints: Array[Vector2i] = []
var _direct_len := 0


## The soundscape and colour follow where the hero is and who it is.
func _ambience() -> void:
	var place := "camp" if _in_camp else ("road" if mode == "expedition" and way_phase in ["walk", "map"] else "town")
	var fighting: bool = hud != null and (hud.battle.visible or hud.tactics.visible)
	Ambience.set_state(place, active, fighting)
	if fx != null:
		fx.set_hero(active)


## True the first time a hint is asked for, then never again.
func _first(flag: String) -> bool:
	if Story.flag(flag):
		return false
	Story.set_flag(flag)
	return true


func _walk_time() -> float:
	return maxf(0.16, WALK_TIME + hero().stats()["step"] * 0.3)


## Public for the tools: one step of the trip. In the plan phase it sets out; on the map it returns to the road.
func _step() -> void:
	if way_phase == "plan":
		_set_out()
		return
	if way_phase == "map":
		_back_to_road()
		return
	if not _pending.is_empty():
		_pass_notable()
		if not _pending.is_empty() or mode != "expedition":
			return
	if way_index >= way.path.size() - 1:
		_resolve_stops(way_index)
		return
	way_index += 1
	if not _scripted:
		for k in _encounters.keys():
			var idx := _encounter_index(k)
			if idx > way_index and idx - way_index <= 3 and not _approached.has(k):
				_approached[k] = true
				var tw0 := way.hero.create_tween()
				tw0.tween_property(way.hero, "position", way.hero_at(way_index), _walk_time() * 0.9)
				_approach(k)
				_refresh_hud()
				return
	var tw := way.hero.create_tween()
	tw.tween_property(way.hero, "position", way.hero_at(way_index), _walk_time() * 0.9)
	_resolve_stops(way_index)
	_refresh_hud()


## The notables each world tile holds, rolled the first time any road crosses it.
func _notes_for(route_cells: Array) -> Array:
	var taken := {}
	for pos in map.cells:
		for n in map.cells[pos].get("notables", []):
			taken[n["id"]] = true
	var out := []
	for k in range(route_cells.size()):
		var pos: Vector2i = route_cells[k]
		var list := []
		if k > 0 and map.cells.has(pos):
			var c: Dictionary = map.cells[pos]
			if not c.has("notables"):
				c["notables"] = Notables.roll(c, active, rng, taken)
			Notables.wake_stories(c, day)
			list.append_array(c["notables"])
			# land shaped beside this stretch of road shows at the roadside
			for n in Hex.neighbors(pos):
				if map.cells.has(n) and map.cells[n]["state"] == "shaped" and not route_cells.has(n):
					if not _trip_extra.has(n):
						var extra := Notables.roll({"world": map.cells[n]["world"], "layout": map.cells[n]["layout"]}, active, rng, taken)
						_trip_extra[n] = extra.slice(0, 1) if rng.randf() < 0.4 else []
					if not _claimed(n, k, route_cells):
						list.append_array(_trip_extra[n])
		out.append(list)
	return out


## A shaped tile beside two stretches shows at the first of them only.
func _claimed(n: Vector2i, k: int, route_cells: Array) -> bool:
	for j in range(1, k):
		if Hex.neighbors(route_cells[j]).has(n):
			return true
	return false


func _set_out() -> void:
	_approached.clear()
	_buffs.clear()
	_opening = {}
	_trip_extra.clear()
	_encounters.clear()
	_enc_shaped.clear()
	_way_done.clear()
	_pending = []
	way_index = 0
	map.protect = {}
	for pos in route:
		map.protect[pos] = true
	map.show_waypoints([])
	_build_way()
	way.hero.texture = TileFactory.hero_texture(active)
	way.hero.position = way.hero_at(0)
	way.dest_marker.texture = TileFactory.lead_marker_texture() if map.cells[target].has("lead") else TileFactory.marker_texture()
	_show_way()
	var days := 1 + _camps.size()
	hud.banner("On the road: %d day%s there. Glints mark places worth a look: E or click as you pass." % [days, "" if days == 1 else "s"], 4.0)


func _build_way() -> void:
	way.build(route, map, _notes_for(route))
	_camps.clear()
	for k in range(route.size() - 1):
		if (k + 1) % CAMP_EVERY == 0 and k < route.size() - 2:
			_camps.append(k)
			way.add_camp(k)
	for k in range(1, route.size() - 1):
		var shaped := 0
		var lures := []
		for n in Hex.neighbors(route[k]):
			if map.cells.has(n) and map.cells[n]["state"] == "shaped":
				shaped += 1
				if Events.LURES.has(map.cells[n]["layout"]):
					lures.append(Events.LURES[map.cells[n]["layout"]])
		var start: int = way.stretches[k]["first"]
		if start <= way_index:
			if _encounters.has(k) and start + 2 > way_index:
				way.place_encounter(k, _encounters[k], threat(_encounters[k]))
			continue  # this stretch's luck was settled when it was first walked
		if _enc_shaped.has(k) and _enc_shaped[k] == shaped:
			if _encounters.has(k):
				way.place_encounter(k, _encounters[k], threat(_encounters[k]))
			continue
		_enc_shaped[k] = shaped
		_encounters.erase(k)
		var chance: float = ENCOUNTER_BASE + ENCOUNTER_PER_SHAPED * shaped + ENCOUNTER_PER_LURE * lures.size() + hero().stats()["fog"]
		if rng.randf() >= maxf(0.02, chance):
			continue
		var w: String = map.cells[route[k]]["world"] if map.cells.has(route[k]) else "eroded"
		if not Bestiary.has_world(w):
			w = "eroded"
		# danger deepens along the road, gently; the worst of the fog waits until the first chapter is behind you
		var depth := mini(2 if Story.flag("ch1_done") else 1, k / 3)
		var pool := Bestiary.pool(w, depth)
		var ids := []
		if not lures.is_empty():
			ids.append(lures[rng.randi_range(0, lures.size() - 1)])
		else:
			ids.append(pool[rng.randi_range(0, pool.size() - 1)])
		if depth >= 1 and rng.randf() < MAELSTROM_CHANCE * depth:
			ids = ["driftwatcher"] if rng.randf() < 0.7 else ["unmoored"]
		elif rng.randf() < PAIR_CHANCE + 0.1 * depth:
			var near := Bestiary.pool(w, 0)
			ids.append(near[rng.randi_range(0, near.size() - 1)])
		_encounters[k] = ids
		way.place_encounter(k, ids, threat(ids))


func _show_way() -> void:
	way_phase = "walk"
	hud.set_way_phase("walk")
	map.visible = false
	_void.visible = false
	map.set_process_unhandled_input(false)
	map.set_hover_style(-1)
	hud.show_tip("")
	way.visible = true
	var size := way.pixel_size()
	var mid := way.position.y + size.y / 2.0 - 10
	camera.limit_left = int(way.position.x - 30)
	camera.limit_right = int(way.position.x + size.x + 140)
	camera.limit_top = int(mid - 180)
	camera.limit_bottom = int(mid + 180)
	camera.position = way.hero.global_position + Vector2(70, 0)
	camera.reset_smoothing()
	paused = false
	hud.set_paused(false)
	_refresh_hud()


func _leave_way() -> void:
	_in_camp = false
	map.protect = {}
	map.show_waypoints([])
	if way_phase == "":
		return
	way_phase = ""
	way.visible = false
	map.visible = true
	_void.visible = true
	map.set_process_unhandled_input(true)
	var size := map.pixel_size()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(size.x)
	camera.limit_bottom = int(size.y)
	_pending = []
	hud.set_way_phase("walk")


## M, the Map button, or picking a card mid-walk: look at the world map to shape land ahead.
func _toggle_map() -> void:
	if mode != "expedition":
		return
	if way_phase == "walk":
		_show_map()
	elif way_phase == "map":
		_back_to_road()


func _show_map() -> void:
	way_phase = "map"
	hud.set_way_phase("map")
	way.visible = false
	map.visible = true
	_void.visible = true
	map.set_process_unhandled_input(true)
	var size := map.pixel_size()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(size.x)
	camera.limit_bottom = int(size.y)
	var k: int = way.path_stretch[way_index]
	map.hero.position = map.center_of(route[k])
	map.hero.visible = true
	camera.position = map.hero.position + Vector2(52, 6)
	camera.reset_smoothing()
	hud.banner("The world map. Place tiles beside the road ahead, then back to the road (Space or M).", 3.5)
	_refresh_hud()


func _back_to_road() -> void:
	var at := way_index
	_build_way()
	way_index = at
	way.hero.texture = TileFactory.hero_texture(active)
	way.hero.position = way.hero_at(way_index)
	way.dest_marker.texture = TileFactory.lead_marker_texture() if map.cells[target].has("lead") else TileFactory.marker_texture()
	_show_way()


## Works through what waits at a point on the road. Returns true if something stopped the hero.
func _resolve_stops(index: int) -> bool:
	var list: Array = way.stops.get(index, [])
	for n in range(list.size()):
		var key := "%d:%d" % [index, n]
		if _way_done.has(key):
			continue
		var stop: Dictionary = list[n]
		match stop["type"]:
			"notable":
				_way_done[key] = true
				var entry: Dictionary = way.notable(stop["s"], stop["i"])
				if entry["n"]["done"]:
					continue
				if _scripted:
					if entry["n"]["type"] == "event" or rng.randf() < 0.5:
						_examine(stop["s"], stop["i"])
						return true
					continue
				_pending = [stop["s"], stop["i"]]
				_stop_wait = NOTABLE_WAIT
				hud.show_tip("%s\nE: examine. Space: walk on." % Notables.look(entry["n"])["name"])
				if _first("hint_notable"):
					_stop_wait = 8.0
					hud.banner("A place worth a look. Press E or click it to examine; Space to walk on. What you find stays found.", 6.0)
				return true
			"encounter":
				_way_done[key] = true
				if _encounters.has(stop["s"]):
					_fighting = stop["s"]
					var ids: Array = _encounters[stop["s"]]
					_encounters.erase(stop["s"])
					_start_fight(ids)
					return true
			"exit":
				_way_done[key] = true
				if _exit_stretch(stop["s"]):
					return true
	return false


## The end of a stretch: what the land beside it paid, a card perhaps, and the map updated.
## The last stretch is the destination. Returns true if the trip stops here.
func _exit_stretch(k: int) -> bool:
	var pos: Vector2i = route[k]
	map.reveal_around(pos)
	map.hero.position = map.center_of(pos)
	var gains := {}
	for n in Hex.neighbors(pos):
		if map.cells.has(n) and map.cells[n]["state"] == "shaped":
			var entries := Rules.tile_yields(n, map.cells)
			var combos := []
			for e in entries:
				gains[e["res"]] = gains.get(e["res"], 0) + e["amt"]
				if e["combo"] != "":
					combos.append(e["combo"])
			_discover(combos)
	for r in gains:
		loot[r] = loot.get(r, 0) + gains[r]
	if not gains.is_empty():
		_float_text(way.hero.global_position + Vector2(0, -24), _gain_text(gains))
	if map.cells.has(pos) and map.cells[pos].has("notables"):
		map.cells[pos]["known"] = true
	if pos == target:
		_arrive()
		return true
	if hand.size() < MAX_HAND and rng.randf() < DRAW_CHANCE:
		hand.append(_draw_card())
	if _camps.has(k):
		_make_camp(k)
		return true
	return false


## Night on the road. A day passes at home too (production, upkeep, perhaps a shift), and
## the dark comes up to the edge of the fire.
var camps_made := 0
var _opening := {}          # how the next fight begins (set by approaching it)
var _buffs := {}            # carried from camp: loaded, scouted
var _approached := {}       # encounters already met with a choice
const SLIP_CHANCE := 0.5
const BANDAGE_HP := 6
func _make_camp(k: int) -> void:
	camps_made += 1
	_in_camp = true
	if _first("hint_camp"):
		hud.banner("Every three stretches of road the hero makes camp, and a day passes: at home too. Two things to do before you sleep.", 5.0)
	var was := mode
	mode = "battle"  # holds the hero still
	advance_day(true)
	if not map.glimpses[active].has(target) and not map.cells[target].has("lead"):
		map.glimpses[active].append(target)  # the destination was protected; it's still there
	var world_id: String = map.cells[route[k]]["world"] if map.cells.has(route[k]) else "eroded"
	# a hot meal waiting at home steadies the hand: a mess hall in reach gives a third action
	var actions := 3 if int(struct_fx(active).get("mess", 0)) > 0 else 2
	Documenter.remark("camp", active, rng, day)
	var night := {"actions": actions, "chance": NIGHT_EVENT_CHANCE, "used": {}, "world": world_id, "k": k, "was": was}
	_camp_menu(night)


## The camp: two things to do before sleep, then keep watch or sleep, then the night.
func _camp_menu(night: Dictionary) -> void:
	var world_name: String = Worlds.world(night["world"])["name"].replace("The ", "the ")
	var options := []
	var left: int = night["actions"]
	if left > 0:
		var used: Dictionary = night["used"]
		if supplies > 0 and not used.has("rest"):
			options.append({"id": "rest", "label": "Rest properly (1 supply): +12 health"})
		if not used.has("dress"):
			options.append({"id": "dress", "label": "Dress your wounds: +5 health"})
		if not used.has("forage"):
			options.append({"id": "forage", "label": "Forage %s for what it has (the noise carries)" % world_name})
		if not used.has("make") and _have("salvage", 3):
			options.append({"id": "make", "label": "Make a supply from scrap (3 salvage)"})
		if not used.has("scout") and night["k"] < route.size() - 2:
			options.append({"id": "scout", "label": "Scout the road ahead"})
		if not used.has("hero"):
			match active:
				"oracle":
					options.append({"id": "hero", "label": "Read the embers: +2 Foresight, and you'll know when to wake"})
				"engineer":
					if _have("reagents", 1):
						options.append({"id": "hero", "label": "Let the swarm mend you (1 reagent): +10 health"})
				"gunslinger":
					options.append({"id": "hero", "label": "Clean and load: your next fight opens with a shot already in"})
	var watch_fx: Array = {"oracle": ["+1 Foresight", {"fs": 1}], "gunslinger": ["+1 charge", {"fs": 1}], "engineer": ["+3 experience", {"xp": 3}]}[active]
	options.append({"id": "watch", "label": "Keep watch till dawn (%s; the night is less likely to find you)" % watch_fx[0], "fx": watch_fx[1]})
	options.append({"id": "sleep", "label": "Sleep: +3 health"})
	var head := "Camp on the road through %s. Day %d. The fire is small and the dark is not." % [world_name, day]
	if left == 3:
		head += " The mess hall's rations go further than road food: three things before you sleep."
	elif left == 2 and night["actions"] == 3 and night["used"].size() == 1:
		head = "The fire's settled. Time for two more things before you sleep."
	elif left == 1:
		head = "The fire's settled. Time for one more thing before you sleep."
	elif left == 0:
		head = "That's all the night has room for. Watch, or sleep."
	hud.screens.choice("Camp", head, options, func(i: int) -> void:
		_camp_act(night, options[i]))


func _camp_act(night: Dictionary, opt: Dictionary) -> void:
	var id: String = opt["id"]
	var text := ""
	match id:
		"rest":
			supplies -= 1
			_heal(12)
			text = "You eat properly and sleep an hour by the fire. It helps more than you expected."
		"dress":
			_heal(5)
			text = "You clean what needs cleaning and bind what needs binding."
		"forage":
			var res: Array = [Worlds.world(night["world"]).get("yield", "salvage"), Worlds.world(night["world"]).get("yield", "salvage"), "salvage", "food"]
			var got := {}
			for n in range(2):
				var r: String = res[rng.randi_range(0, res.size() - 1)]
				got[r] = int(got.get(r, 0)) + rng.randi_range(1, 2)
			for r in got:
				loot[r] = loot.get(r, 0) + got[r]
			night["chance"] = float(night["chance"]) + 0.2
			text = "You go out past the firelight and come back with %s. Something out there heard you." % _gain_text(got).strip_edges()
		"make":
			_spend("salvage", 3)
			supplies += 1
			text = "Scrap, cord and patience: one more supply for the road."
		"scout":
			text = _scout_ahead(night["k"])
		"hero":
			match active:
				"oracle":
					foresight = mini(hero().stats()["fs"] + 2, foresight + 2)
					night["chance"] = float(night["chance"]) * 0.5
					text = "In the embers, the shapes of tonight. You'll wake before anything reaches the fire."
				"engineer":
					_spend("reagents", 1)
					_heal(10)
					hero().gain_xp(2)
					text = "The swarm works through the night. By morning the worst of it has closed."
				"gunslinger":
					_buffs["loaded"] = 0.25
					hero().charge = mini(9, hero().charge + 1)
					text = "You strip the guns down by firelight and put them back together. Whatever comes next, you'll speak first."
		"watch":
			_apply_effects(opt["fx"])
			night["chance"] = float(night["chance"]) * 0.5
			text = "You sit up with your back to the fire and watch the dark watch you."
		"sleep":
			_heal(3)
			text = "Thin sleep, full of the road."
	if id not in ["watch", "sleep"]:
		night["actions"] = int(night["actions"]) - 1
		night["used"][id] = true
		hud.screens.say("", [text], func() -> void: _camp_menu(night))
		_refresh_hud()
		return
	hud.screens.say("", [text], func() -> void: _camp_night(night))
	_refresh_hud()


func _camp_night(night: Dictionary) -> void:
	var was: String = night["was"]
	var resume := func() -> void:
		_in_camp = false
		mode = was if mode == "battle" else mode
		if mode == "expedition":
			_resolve_stops(way_index)
		_refresh_hud()
	if rng.randf() < float(night["chance"]):
		var e := Events.pick_road_night(rng)
		if not e.is_empty():
			mode = was
			_run_event(e, resume)
			return
	Documenter.remark("wait", active, rng, day)
	resume.call()


func _heal(n: int) -> void:
	hero_hp = mini(hero().stats()["hp"], hero_hp + n)


## On a trip, resources come from what's been found first, then from home.
func _have(r: String, n: int) -> bool:
	return int(loot.get(r, 0)) + int(stock.get(r, 0)) >= n


func _spend(r: String, n: int) -> void:
	var from_loot := mini(n, int(loot.get(r, 0)))
	loot[r] = int(loot.get(r, 0)) - from_loot
	stock[r] = int(stock.get(r, 0)) - (n - from_loot)


## What the next two stretches hold. Slipping past what you've scouted is easier.
func _scout_ahead(k: int) -> String:
	var seen := []
	for j in range(k + 1, mini(k + 3, route.size())):
		if _encounters.has(j):
			var what: String = " and ".join(_encounters[j].map(func(id): return Bestiary.enemy(id)["name"].to_lower()))
			var d := threat(_encounters[j])
			seen.append(what + ([""," (wary)", " (dangerous)", " (deadly)"][d]))
		if map.cells.has(route[j]) and map.cells[route[j]].has("notables"):
			map.cells[route[j]]["known"] = true
	_buffs["scouted"] = true
	map.refresh_notes()
	if seen.is_empty():
		return "You climb what high ground there is and look along the road. Nothing waiting on it, as far as the light reaches. The way looks clear."
	return "You climb what high ground there is and look along the road. Waiting on it: %s. You mark the ground around them; you'll know where to step." % ", then ".join(seen)


# ------------------------------------------------------------------ meeting what waits on the road
func _encounter_index(k: int) -> int:
	for idx in way.stops:
		for st in way.stops[idx]:
			if st["type"] == "encounter" and st["s"] == k:
				return idx
	return -1


## Something on the road ahead, and it has seen the light. How to meet it.
func _approach(k: int) -> void:
	var ids: Array = _encounters[k]
	var names: String = " and ".join(ids.map(func(id): return Bestiary.enemy(id)["name"].to_lower()))
	var was := mode
	mode = "battle"  # holds the hero still
	var slip := SLIP_CHANCE + (0.25 if _buffs.has("scouted") else 0.0) + (0.05 * foresight if active == "oracle" else 0.0)
	slip = minf(0.9, slip)
	var options := [{"id": "fight", "label": "Meet it head on"}]
	options.append({"id": "slip", "label": "Slip past in the dark (%d%%; if it sees you, it strikes first)" % int(slip * 100)})
	match active:
		"oracle":
			if foresight > 0:
				options.append({"id": "edge", "label": "Foresee its first move (1 Foresight): it opens badly hurt"})
		"engineer":
			if _have("parts", 1):
				options.append({"id": "edge", "label": "Set a turret in its path (1 Part): it walks into fire"})
		"gunslinger":
			if hero().charge > 0:
				options.append({"id": "edge", "label": "Take the first shot (1 charge): the weak ones won't get up"})
	options.append({"id": "back", "label": "Turn back for home"})
	var danger := threat(ids)
	var text := "On the road ahead: %s. %s seen your light. %s" % [names, "They've" if ids.size() > 1 else "It has", THREAT_WORDS[danger]]
	if _first("hint_enemy"):
		text += " There's no going round it on this road, but there's more than one way to meet it."
	Documenter.remark("approach", active, rng, day)
	hud.screens.choice("", text, options, func(i: int) -> void:
		mode = was
		var id: String = options[i]["id"]
		match id:
			"fight":
				pass
			"slip":
				_buffs.erase("scouted")
				if rng.randf() < slip:
					_encounters.erase(k)
					way.clear_encounter(k)
					hud.banner("You keep to the dark, and it never turns its head.", 3.0)
					Documenter.remark("slipped", active, rng, day)
				else:
					var hit := maxi(2, int(hero().stats()["hp"] * 0.12))
					hero_hp = maxi(1, hero_hp - hit)
					hud.banner("It sees you. It strikes first (-%d health)." % hit, 3.0)
					Documenter.remark("caught", active, rng, day)
			"edge":
				Documenter.remark("edge", active, rng, day)
				match active:
					"oracle":
						foresight -= 1
						_opening = {"wound": 0.3, "note": "Foreseen: you struck where it was going to be."}
					"engineer":
						_spend("parts", 1)
						_opening = {"wound": 0.35, "note": "It walked into the turret's fire."}
					"gunslinger":
						hero().charge -= 1
						var left := []
						for eid in ids:
							if int(Bestiary.enemy(eid)["hp"]) > 12:
								left.append(eid)
						if left.is_empty():
							_encounters.erase(k)
							way.clear_encounter(k)
							hud.banner("One shot each. Nothing gets up.", 3.0)
						else:
							_encounters[k] = left
							_opening = {"wound": 0.3, "note": "She spoke first."}
							if left.size() < ids.size():
								hud.banner("The weak one drops. The other keeps coming.", 3.0)
			"back":
				_return_home("retreat")
				return
		_refresh_hud())


## Coming home: the home light swells to meet the hero, then settles. Warmer for a
## good trip, dimmer for a hard one.
func _homecoming(hero_id: String, outcome: String) -> void:
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.8, 0.5, 1))
	g.set_color(1, Color(1, 0.6, 0.3, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var flare := Sprite2D.new()
	flare.texture = tex
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flare.material = mat
	flare.z_index = 12
	flare.position = map.center_of(MaelstromMap.HOMES[hero_id]) + Vector2(0, -8)
	var strength: float = {"success": 0.55, "retreat": 0.35, "defeat": 0.2}.get(outcome, 0.4)
	flare.modulate = Color(1, 1, 1, 0)
	flare.scale = Vector2(0.4, 0.3)
	map.add_child(flare)
	var tw := flare.create_tween()
	tw.tween_property(flare, "modulate:a", strength, 0.6).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(flare, "scale", Vector2(2.2, 1.5), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(flare, "modulate:a", 0.0, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(flare.queue_free)
	if outcome == "success":
		Documenter.remark("home", hero_id, rng, day)


## How dangerous what waits on the road is to the hero in play right now: 0 easy,
## 1 wary, 2 dangerous, 3 deadly. Compares how long each side would take to wear the other down.
func threat(ids: Array) -> int:
	var st: Dictionary = hero().stats()
	var atk := maxf(1.0, float(st.get("atk", 3)))
	# what the stat line leaves out: the Engineer's constructs, Alysia's guns
	var extra := {"engineer": 1.6, "gunslinger": 3.0}.get(active, 1.0) as float
	var spd := float(st.get("spd", 1.0)) * extra
	var time_to_win := 0.0
	var their_dps := 0.0
	for id in ids:
		var e: Dictionary = Bestiary.enemy(id)
		var per_hit := maxf(ceilf(atk * 0.5), atk - float(e.get("armor", 0)))
		time_to_win += float(e["hp"]) / (per_hit * spd)
		var dmg := maxf(ceilf(e["atk"] * 0.4), e["atk"] - float(st.get("armor", 0)))
		their_dps += dmg * float(e.get("spd", 1.0))
	var share := time_to_win * their_dps / maxf(1.0, float(hero_hp))
	if share >= 0.85:
		return 3
	if share >= 0.5:
		return 2
	if share >= 0.25:
		return 1
	return 0


const THREAT_WORDS := ["It looks manageable.", "Be wary.", "This one is dangerous.", "This could kill you."]


## B on the road: a supply for a little health.
func bandage() -> void:
	if mode != "expedition" or way_phase != "walk" or supplies <= 0:
		if supplies <= 0:
			hud.banner("No supplies left to bandage with.", 2.0)
		return
	if hero_hp >= hero().stats()["hp"]:
		hud.banner("Nothing that needs binding.", 2.0)
		return
	supplies -= 1
	_heal(BANDAGE_HP)
	_float_text(way.hero.global_position + Vector2(0, -24), "+%d health" % BANDAGE_HP)
	Documenter.remark("bandage", active, rng, day)
	_refresh_hud()


# ------------------------------------------------------------------ planning the route
## Click tiles in the plan phase to route through them, in the order clicked, then on to
## the glimpse. The route may run up to ROUTE_SLACK tiles longer than the direct way.
func _toggle_waypoint(pos: Vector2i) -> void:
	if pos == target or route.size() < 1 or pos == route[0] or map.land_of(active).has(pos):
		return
	if not map.cells.has(pos):
		return
	if waypoints.has(pos):
		waypoints.erase(pos)
		_apply_plan()
		return
	waypoints.append(pos)
	var r := _plan_route()
	if r.is_empty():
		waypoints.erase(pos)
		hud.banner("No way through the fog to there.", 2.5)
		return
	if r.size() > _direct_len + ROUTE_SLACK:
		waypoints.erase(pos)
		hud.banner("Too far out of the way: a route may run %d tiles longer than the direct way." % ROUTE_SLACK, 3.0)
		return
	_apply_plan()


func _plan_route() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if waypoints.is_empty():
		return map.route_to(target, active)
	out = map.route_to(waypoints[0], active)
	if out.is_empty():
		return out
	var stops: Array = waypoints.slice(1) + [target]
	for p in stops:
		var seg := map.path_between(out[out.size() - 1], p)
		if seg.is_empty():
			return [] as Array[Vector2i]
		for i in range(1, seg.size()):
			out.append(seg[i])
	return out


func _apply_plan() -> void:
	var r := _plan_route()
	if r.is_empty():
		return
	route = r
	# tiles shaped beside the old route that the new one no longer passes come back to hand
	for pos in map.cells.keys():
		var c: Dictionary = map.cells[pos]
		if c["state"] != "shaped":
			continue
		var beside := false
		for n in Hex.neighbors(pos):
			if route.has(n):
				beside = true
		if route.has(pos) or not beside:
			hand.append({"world": c["world"], "layout": c["layout"]})
			map.cells[pos] = c["previous"]
			map.refresh(pos)
	map.show_route(route)
	map.show_waypoints(waypoints)
	var extra := route.size() - _direct_len
	var days := 1 + int((route.size() - 2) / CAMP_EVERY)
	hud.banner("Route: %d tiles (%s), about %d day%s. Right-click clears the waypoints." % [route.size(),
		"direct" if extra <= 0 else "+%d of %d spare" % [extra, ROUTE_SLACK], days, "" if days == 1 else "s"], 3.0)
	_refresh_hud()


## A lookout: the notables on tiles within reach become known on the map.
func _reveal_from(center: Vector2i, radius: int) -> void:
	var taken := {}
	for pos in map.cells:
		for n in map.cells[pos].get("notables", []):
			taken[n["id"]] = true
	var found := 0
	for pos in map.cells.keys():
		var c: Dictionary = map.cells[pos]
		if c["state"] != "unstable" or Hex.distance(pos, center) > radius or c.get("known", false):
			continue
		if not c.has("notables"):
			c["notables"] = Notables.roll(c, active, rng, taken)
		if not c["notables"].is_empty():
			c["known"] = true
			map.revealed[pos] = true
			found += 1
	map.refresh_notes()
	hud.banner("From up here you can make out %d place%s worth a look. They're marked on the map." % [found, "" if found == 1 else "s"], 3.5)


# ------------------------------------------------------------------ talk of the town
## When someone has no story news: a word about something a hero found, or a rumour of a
## place out in the fog, which then shows on the map. "" means only their idle line.
func town_chatter(person: String) -> String:
	var word := TownTalk.take_word(person)
	if word != "":
		return word
	if not Story.state.has("rumour_day"):
		Story.state["rumour_day"] = {}
	if int(Story.state["rumour_day"].get(person, -1)) == day or rng.randf() > TownTalk.RUMOUR_CHANCE:
		return ""
	var region: String = Story.PEOPLE[person]["region"]
	if not heroes.has(region):
		return ""
	var land := map.land_of(region)
	var taken := {}
	for pos in map.cells:
		for n in map.cells[pos].get("notables", []):
			taken[n["id"]] = true
	var best := MaelstromMap.NONE
	var best_score := -INF
	for pos in map.cells.keys():
		var c: Dictionary = map.cells[pos]
		if c["state"] != "unstable" or c.get("known", false) or c.has("lead"):
			continue
		var d := 99
		for h in [MaelstromMap.HOMES[region]]:
			d = Hex.distance(pos, h)
		if d < 4 or d > 9:
			continue
		var score := rng.randf() - absf(d - 6) * 0.2
		if score > best_score:
			best_score = score
			best = pos
	if best == MaelstromMap.NONE:
		return ""
	var cell: Dictionary = map.cells[best]
	if not cell.has("notables"):
		cell["notables"] = Notables.roll(cell, region, rng, taken)
	if cell["notables"].is_empty():
		cell["notables"] = [{"type": "find", "id": "cairn", "done": false}]
	cell["known"] = true
	map.revealed[best] = true
	map.refresh_notes()
	Story.state["rumour_day"][person] = day
	var thing: String = Notables.look(cell["notables"][0])["name"]
	var dir := TownTalk.compass(map.center_of(MaelstromMap.HOMES[region]), map.center_of(best))
	var tiles := Hex.distance(best, MaelstromMap.HOMES[region])
	hud.banner("Marked on the map: %s, to the %s." % [thing.substr(0, 1).to_lower() + thing.substr(1), dir], 3.5)
	return TownTalk.rumour_text(person, thing, dir, tiles, rng)


func _on_notable_clicked(k: int, i: int) -> void:
	if way_phase != "walk" or hud.screens.is_open() or mode != "expedition":
		return
	if not _pending.is_empty() and _pending[0] == k and _pending[1] == i:
		_examine(k, i)
	elif way.notable(k, i)["n"]["done"]:
		hud.banner(Notables.look(way.notable(k, i)["n"]).get("seen", "Examined."), 2.5)
	else:
		hud.banner("Too far. Walk up to it first.", 2.0)


func _pass_notable() -> void:
	_pending = []
	_stop_wait = 0.0
	hud.show_tip("")
	_resolve_stops(way_index)


func _examine(k: int, i: int) -> void:
	_pending = []
	_stop_wait = 0.0
	hud.show_tip("")
	var n: Dictionary = way.notable(k, i)["n"]
	way.mark_done(k, i)
	TownTalk.note_examined(n["id"])
	var resume := func() -> void:
		if mode == "expedition":
			_resolve_stops(way_index)
		_refresh_hud()
	if n["type"] == "story":
		var sd: Dictionary = Notables.STORIES[n["id"]]
		var stage: int = int(n.get("stage", 0))
		var page: Dictionary = sd["stages"][stage]
		_run_event({"id": "%s:%d" % [n["id"], stage], "text": page["text"], "options": page["options"], "once": false}, func() -> void:
			n["stage"] = stage + 1
			n["done"] = true
			n["ready_day"] = day + Notables.STORY_REST_DAYS
			if n["stage"] >= sd["stages"].size():
				hud.banner("%s: the story here has run its course." % sd["title"], 3.5)
			else:
				hud.banner("%s (%d of %d). It won't stay like this. Come back in a few days." % [sd["title"], n["stage"], sd["stages"].size()], 3.5)
			resume.call())
		return
	if n["type"] == "event":
		var e := _event(n["id"])
		if not e.is_empty():
			_run_event(e, resume)
			return
	var f := Notables.find(n["id"])
	var was := mode
	mode = "battle"  # holds the hero still
	hud.screens.say("", [f.get("text", "Nothing of use.")], func() -> void:
		mode = was
		var fx: Dictionary = f.get("effects", {})
		_apply_effects(fx)
		var gains: Dictionary = fx.get("res", {})
		if not gains.is_empty():
			_float_text(way.hero.global_position + Vector2(0, -24), _gain_text(gains))
		Documenter.remark("find", active, rng, day)
		resume.call())


func _event(id: String) -> Dictionary:
	for e in Events.EXPEDITION:
		if e["id"] == id:
			return e
	return {}


func _start_fight(ids: Array) -> void:
	mode = "battle"
	hud.show_tip("")
	var wound: float = float(_opening.get("wound", 0.0)) + float(_buffs.get("loaded", 0.0))
	var note: String = _opening.get("note", "")
	if _buffs.has("loaded"):
		note = (note + " " if note != "" else "") + "Loaded at camp."
		_buffs.erase("loaded")
	hud.battle.opening = {"wound": minf(0.6, wound), "note": note}
	_opening = {}
	hud.battle.start(ids, hero(), hero_hp, foresight, supplies)


## An expedition event: a short scene with a choice, then its consequences.
func _run_event(e: Dictionary, done: Callable = Callable()) -> void:
	Events.mark(e)
	hud.show_tip("")
	var was := mode
	mode = "battle"  # holds the hero still
	hud.screens.choice("", e["text"], e["options"], func(i: int) -> void:
		var opt: Dictionary = e["options"][i]
		_apply_effects(opt["effects"])
		var fight: Array = opt["effects"].get("fight", [])
		hud.screens.say("", [opt["text"]], func() -> void:
			if not fight.is_empty():
				_start_fight(fight)
			else:
				mode = was
				Documenter.remark("event", active, rng, day)
				if done.is_valid():
					done.call()
			_refresh_hud()))


func _apply_effects(fx: Dictionary) -> void:
	for r in fx.get("res", {}):
		if mode == "territory":
			stock[r] = maxi(0, stock[r] + fx["res"][r])
		else:
			loot[r] = loot.get(r, 0) + fx["res"][r]
	if fx.has("hp"):
		hero_hp = clampi(hero_hp + fx["hp"], 1, hero().stats()["hp"])
	if fx.has("fs"):
		foresight = mini(hero().stats()["fs"], foresight + fx["fs"]) if active == "oracle" else foresight
		if active == "gunslinger":
			hero().charge = mini(9, hero().charge + fx["fs"])
	if fx.has("item"):
		hero().give(fx["item"])
	if fx.has("supplies"):
		supplies += int(fx["supplies"])
	if fx.has("reveal") and way_phase == "walk":
		_reveal_from(route[way.path_stretch[way_index]], int(fx["reveal"]))
	if fx.has("chronicle"):
		Story.add_chronicle(fx["chronicle"])
	if fx.has("flag"):
		Story.set_flag(fx["flag"])
	if fx.has("omen"):
		Story.add_omen(fx["omen"])
		Documenter.remark("omen", active, rng, day)
	if fx.has("people") and heroes.has("gunslinger"):
		Story.state["people"] += int(fx["people"])
	if fx.has("xp") and heroes.has("engineer"):
		heroes["engineer"].gain_xp(int(fx["xp"]))


func _on_battle_finished(won: bool, hp: int, fs: int, left: int, result: Dictionary) -> void:
	hero_hp = hp
	foresight = fs
	supplies = left
	if not won:
		Documenter.remark("fight_lost", active, rng, day)
		_return_home("defeat")
		return
	Documenter.remark("fight_close" if hp <= hero().stats()["hp"] * 0.3 else "fight_won", active, rng, day)
	if active == "oracle" and hero().has_vision("counting_fallen"):
		foresight = mini(hero().stats()["fs"], foresight + 1)
	for id in result["kills"]:
		var e := Bestiary.enemy(id)
		loot[e["loot"]] = loot.get(e["loot"], 0) + 2 + int(e["tier"])
		_maybe_drop(e["world"] if e["world"] != "" else "eroded", DROP_CHANCE)
	if active == "engineer":
		var levels: int = hero().gain_xp(int(result["xp"]))
		if levels > 0:
			hud.banner("Level %d. A skill point is waiting on the Hero screen." % hero().level, 3.5)
	for note in result["notes"]:
		if note.begins_with("Blueprint"):
			hud.banner(note + ". Build it at the camp bench.", 3.5)
	if hand.size() < MAX_HAND:
		hand.append(_draw_card())
	mode = "expedition"
	if _fighting >= 0:
		way.clear_encounter(_fighting)
		_fighting = -1
	if way_phase == "walk":
		_resolve_stops(way_index)
	_refresh_hud()


func _arrive() -> void:
	mode = "battle"  # freezes stepping while the fragment is stabilized
	var lead: String = map.cells[target].get("lead", "")
	if lead != "" and Story.LEADS[lead].has("fight"):
		hud.show_tip("")
		hud.screens.say("The Oracleborn", [
			"Pale stone underfoot. A throne, and a window of colored glass he has seen before, in dreams.",
			"The light moves. Figures step out of it: afterimages of the last hour of his world, and they won't let him look.",
		], func() -> void:
			hero_hp = maxi(hero_hp, int(hero().stats()["hp"] * 0.75))  # he steadies himself before the hall
			hud.tactics.start(Story.LEADS[lead]["fight"], hero(), hero_hp, supplies))
		return
	var tiles := _fragment_cells()
	hud.banner("Fragment stabilized: %d tile%s." % [tiles.size(), "" if tiles.size() == 1 else "s"])
	await get_tree().create_timer(1.2).timeout
	_return_home("success")


func _on_tactics_finished(won: bool, hp: int, result: Dictionary) -> void:
	if _story_busy:
		_prologue_finished(won, hp, result)
		return
	hero_hp = hp
	if active == "engineer":
		hero().gain_xp(int(result["xp"]))
	if not won:
		_return_home("defeat")
		return
	hud.banner("The afterimages fade. The throne hall holds still.", 2.5)
	await get_tree().create_timer(1.0).timeout
	_return_home("success")


## The glimpse plus shaped land touching it, up to the pack limit.
func _fragment_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = [target]
	for n in Hex.neighbors(target):
		if out.size() >= FRAGMENT_LIMIT + hero().stats()["pack"]:
			break
		if map.cells.has(n) and map.cells[n]["state"] == "shaped":
			out.append(n)
	return out


func _return_home(outcome: String) -> void:
	if target == MaelstromMap.NONE:
		return
	_leave_way()
	_homecoming(active, outcome)
	var lead: String = map.cells[target].get("lead", "") if map.cells.has(target) else ""
	var tiles := []
	if outcome == "success":
		for pos in _fragment_cells():
			tiles.append({"world": map.cells[pos]["world"], "layout": map.cells[pos]["layout"]})
	var toward := map.center_of(target)
	var taken := _fragment_cells() if outcome == "success" else ([] as Array[Vector2i])
	map.clear_shaped()
	var kept := 1.0 if outcome != "defeat" else 0.5
	for r in loot:
		stock[r] += int(floor(loot[r] * kept))
	var fused_msg := ""
	if outcome == "success":
		for pos in taken:
			map.cells.erase(pos)  # the fragment leaves a hole in the fog
		map.glimpses[active].erase(target)
		if active == "gunslinger":
			var free := 1 if struct_fx("gunslinger").get("winch", 0) > 0 else 0
			var affordable := mini(tiles.size(), stock["parts"] + free)
			if affordable < tiles.size():
				fused_msg = " Only %d Part%s: %d tile%s drifted away unheld." % [stock["parts"], "" if stock["parts"] == 1 else "s",
						tiles.size() - affordable, "" if tiles.size() - affordable == 1 else "s"]
				tiles = tiles.slice(0, affordable)
			stock["parts"] -= maxi(0, tiles.size() - free)
		var placed := map.fuse(tiles, toward, active)
		for pos in placed:
			map.cells[pos]["fused_day"] = day
		if lead == "":
			if not tiles.is_empty():
				_maybe_drop(tiles[0]["world"], DROP_CHANCE)
			_maybe_survivors()
	elif outcome == "defeat":
		hero().injured = true
		Documenter.remark("injured", active, rng, day)
		if lead == "":
			map.glimpses[active].erase(target)
	map.rebuild_all()
	target = MaelstromMap.NONE
	route = []
	_enter_territory()
	focus_camera()
	advance_day()
	if outcome == "success" and lead != "":
		_complete_lead(lead)
		return
	match outcome:
		"success":
			hud.banner("Home. The fragment fuses to your land and settles for 2 days." + fused_msg, 3.5)
		"retreat":
			hud.banner("Retreated with everything you carried.", 3.0)
		"defeat":
			hud.banner("Defeated. Half the loot is lost, the glimpse drifted away, and %s is injured." % hero().short_name(), 4.0)


func _maybe_survivors() -> void:
	if not heroes.has("gunslinger") or rng.randf() > SURVIVOR_CHANCE * (2.0 if struct_fx("gunslinger").get("mess", 0) > 0 else 1.0):
		return
	var n := rng.randi_range(1, 2)
	Story.state["people"] += n
	Documenter.remark("survivor", active, rng, day)
	hud.banner("%d survivor%s found in the fog. They head for Pallas (%d people)." % [n, "" if n == 1 else "s", Story.state["people"]], 3.5)


func _on_wait() -> void:
	if mode != "territory" or hud.screens.is_open() or _story_busy:
		return
	advance_day()
	if rng.randf() < NIGHT_EVENT_CHANCE:
		var e := Events.pick_night(rng)
		if e.is_empty():
			Documenter.remark("wait", active, rng, day)
		else:
			Events.mark(e)
			hud.screens.choice("That night", e["text"], e["options"], func(i: int) -> void:
				var opt: Dictionary = e["options"][i]
				_apply_effects(opt["effects"])
				hud.screens.say("", [opt["text"]], func() -> void:
					_refresh_hud()
					save_game()))


func _on_retreat() -> void:
	if mode == "expedition":
		_return_home("retreat")


func _toggle_pause() -> void:
	if mode != "expedition":
		return
	match way_phase:
		"plan":
			_set_out()
			return
		"map":
			_back_to_road()
			return
	if not _pending.is_empty():
		_pass_notable()
		return
	paused = not paused
	hud.set_paused(paused)


# ------------------------------------------------------------------ input
func _select(index: int) -> void:
	if mode != "expedition" or index >= hand.size():
		return
	if way_phase == "walk":
		_show_map()
	selected = -1 if selected == index else index
	_refresh_hud()
	_on_hover(_hover, map.cells.has(_hover))


func _on_click(pos: Vector2i, button: int) -> void:
	if hud.screens.is_open() or _story_busy:
		return
	var cell: Dictionary = map.cells[pos]
	if mode == "build":
		if button == MOUSE_BUTTON_LEFT:
			place_structure(pos)
		else:
			cancel_build()
		return
	if mode == "territory":
		if map.is_target_for(pos, active) and button == MOUSE_BUTTON_LEFT:
			_start_expedition(pos)
		elif cell.has("structure") and cell["structure"].get("damaged", false) and button == MOUSE_BUTTON_LEFT and map.land_of(active).has(pos):
			repair_structure(pos)
		elif cell["state"] == "settling" and map.land_of(active).has(pos):
			_release(pos)
		elif cell["state"] == "stable" and button == MOUSE_BUTTON_LEFT and active == "oracle" and map.land_of("oracle").has(pos) and _can_read(cell["world"]):
			_read_past(cell["world"])
	elif mode == "expedition" and selected >= 0 and button == MOUSE_BUTTON_LEFT:
		if map.can_shape(pos, route):
			map.shape(pos, hand[selected])
			hand.remove_at(selected)
			selected = -1
			var said := TileLines.line_for(pos, map.cells)
			if said != "":
				hud.banner(said, 4.5)
			_refresh_hud()
			_on_hover(pos, true)
		else:
			hud.banner("Place tiles on fog land next to the route.")
	elif mode == "expedition" and way_phase == "plan" and button == MOUSE_BUTTON_LEFT:
		_toggle_waypoint(pos)
	elif mode == "expedition" and button == MOUSE_BUTTON_RIGHT:
		if selected < 0 and way_phase == "plan" and not waypoints.is_empty():
			waypoints.clear()
			_apply_plan()
		selected = -1
		_refresh_hud()


func _on_hover(pos: Vector2i, inside: bool) -> void:
	_hover = pos
	if not inside or mode == "battle" or hud.screens.is_open():
		hud.show_tip("")
		map.set_hover_style(-1)
		if mode == "territory":
			map.show_route([] as Array[Vector2i])
		return
	var cell: Dictionary = map.cells[pos]
	var w: Dictionary = Worlds.world(cell["world"])
	if mode == "build":
		var reason := place_reason(build_pending, pos)
		map.set_hover_style(1 if reason == "" else (2 if cell["state"] == "stable" else -1))
		hud.show_tip(struct_preview(build_pending, pos) if cell["state"] == "stable" else "")
		return
	if mode == "territory":
		if cell.has("structure"):
			var st := {"id": cell["structure"]["id"], "pos": pos, "world": cell["world"],
				"damaged": bool(cell["structure"].get("damaged", false)), "dark": bool(cell["structure"].get("dark", false))}
			var d: Dictionary = Items.STRUCTURES[st["id"]]
			var lines := [d["name"], "On %s ground" % w["name"]]
			if st["damaged"]:
				lines.append("DAMAGED. Click to repair: %d %s." % [REPAIR_COST, Worlds.RESOURCE_NAMES[Worlds.MATERIAL[cell["world"]]]])
			elif st["dark"]:
				lines.append("Dark: no Sunstone to burn.")
			else:
				lines.append(d["text"].split(".")[0] + ".")
				var gt: String = d["ground_text"].get(cell["world"], "")
				if gt != "":
					lines.append(gt)
			map.set_hover_style(0)
			hud.show_tip("\n".join(lines))
			return
		if map.is_target_for(pos, active):
			map.set_hover_style(1)
			map.show_route(map.route_to(pos, active))
			var head := "GLIMPSE"
			var leads := map.lead_cells()
			if leads.has(pos):
				var ld: Dictionary = Story.LEADS[leads[pos]]
				head = "LEAD: %s (%s)" % [ld["name"].to_upper(), Story.PEOPLE[ld["giver"]]["name"]]
			hud.show_tip("%s\nThrough the fog: %s.\nClick to set out." % [head, map.glimpse_text(pos)])
			return
		map.show_route([] as Array[Vector2i])
		var leads := map.lead_cells()
		if leads.has(pos) or _other_glimpse(pos):
			map.set_hover_style(0)
			var who: String = Story.LEADS[leads[pos]]["hero"] if leads.has(pos) else _other_glimpse_owner(pos)
			hud.show_tip("Through the fog: %s.\nIn %s's reach. Switch heroes (Tab) to set out." % [map.glimpse_text(pos), HeroState.HEROES[who]["short"]])
			return
		map.set_hover_style(0 if cell["state"] != "unstable" else -1)
		if cell["state"] == "unstable":
			var known := map.notes_text(pos)
			hud.show_tip("%s, %s\n%s" % [Worlds.LAYOUT_NAMES[cell["layout"]], w["name"], known] if known != "" else "")
			return
		var lines := [Worlds.LAYOUT_NAMES[cell["layout"]], w["name"]]
		var b := Rules.evaluate(map.cells)
		if b.has(pos):
			lines.append(_gain_text(_sum(b[pos])) + " / day")
		var owner: String = cell.get("owner", "")
		if owner != "" and cell.has("fused_day"):
			lines.append({"oracle": "Held by the pillar", "engineer": "Anchored: 1 Power/day", "gunslinger": "Tethered"}[owner])
		if cell["state"] == "settling":
			lines.append("Settling %d day%s. Click to release." % [cell["settle"], "" if cell["settle"] == 1 else "s"])
		elif cell["state"] == "stable" and active == "oracle" and map.land_of("oracle").has(pos):
			var rl := _reading_line(cell["world"])
			if rl != "":
				lines.append(rl)
		hud.show_tip("\n".join(lines))
		return
	# expedition
	if selected >= 0:
		var ok := map.can_shape(pos, route)
		map.set_hover_style(1 if ok else 2)
		if ok:
			var preview := map.cells.duplicate()
			var card: Dictionary = hand[selected]
			preview[pos] = {"world": card["world"], "layout": card["layout"], "state": "shaped", "seed": 0}
			var entries := Rules.tile_yields(pos, preview)
			var names := []
			for e in entries:
				if e["combo"] != "" and not names.has(e["combo"]):
					names.append(Rules.COMBOS[e["combo"]]["name"] if discovered.has(e["combo"]) else "???")
			var text := "Pays %s each time the hero passes." % _gain_text(_sum(entries))
			if names:
				text += "\n" + ", ".join(names)
			if Events.LURES.has(card["layout"]):
				text += "\nAttracts: %s." % Bestiary.enemy(Events.LURES[card["layout"]])["name"]
			if Hex.distance(pos, target) == 1:
				text += "\nNext to the glimpse: comes home with it."
			hud.show_tip(text)
		else:
			hud.show_tip("")
	else:
		map.set_hover_style(-1)
		if cell["state"] == "shaped":
			hud.show_tip("%s\n%s\nPays %s per pass." % [Worlds.LAYOUT_NAMES[cell["layout"]], w["name"],
					_gain_text(_sum(Rules.tile_yields(pos, map.cells)))])
		elif pos == target:
			hud.show_tip("GLIMPSE\n%s" % map.glimpse_text(pos))
		elif way_phase == "plan" and not map.land_of(active).has(pos):
			var known := map.notes_text(pos)
			var head := "Waypoint %d. Click to drop it." % (waypoints.find(pos) + 1) if waypoints.has(pos) else "Click to route through here."
			hud.show_tip(head + ("\n" + known if known != "" else ""))
		else:
			hud.show_tip("")


func _other_glimpse(pos: Vector2i) -> bool:
	return _other_glimpse_owner(pos) != ""


func _other_glimpse_owner(pos: Vector2i) -> String:
	for h in map.glimpses:
		if h != active and map.glimpses[h].has(pos):
			return h
	return ""


# ------------------------------------------------------------------ story, readings and gear
func open_screen(view: String) -> void:
	if _story_busy:
		return
	if mode != "territory" and view != "chronicle":
		hud.banner("Gear and the town wait until you're home.")
		return
	hud.show_tip("")
	map.set_hover_style(-1)
	hud.screens.open(view)


func _on_screen_closed() -> void:
	_refresh_hud()
	save_game()
	check_story()


## Called by the town screen after a talk; applies what it gave.
func on_heard(person: String, gives: Dictionary) -> void:
	for key in ["lead", "lead2"]:
		if gives.has(key):
			var pos := map.place_lead(gives[key])
			if pos != MaelstromMap.NONE:
				hud.banner("New lead: %s. Look for the cyan marker in the fog." % Story.LEADS[gives[key]]["name"], 4.0)
	if gives.has("item"):
		var region: String = Story.PEOPLE[person]["region"]
		heroes[region].give(gives["item"])
		hud.banner("Received: %s. Equip it on the Hero screen." % Items.item(gives["item"])["name"], 4.0)
	_refresh_hud()
	save_game()


func _complete_lead(lead: String) -> void:
	Story.complete_lead(lead)
	Documenter.remark("lead", active, rng, day)
	var giver: String = Story.LEADS[lead]["giver"]
	match lead:
		"throne":
			hero().give("oracle_glass")
			hero().give("guard_signet")
			Story.add_chronicle("throne_hall")
			_gain_vision("kings_decision")
			hud.screens.say("Reading the past: the throne hall", [
				Story.CHRONICLE["throne_hall"]["text"],
				"Vision: %s. %s" % [Story.VISIONS["kings_decision"]["name"], Story.VISIONS["kings_decision"]["text"]],
				"Left behind in the hall: a lens of oracle glass and a royal guard's signet. Pell will want to hear.",
			], Callable())
		"cache":
			hero().give("shield_drone")
			stock["parts"] += 6
			hud.banner("The cache: a shield drone and 6 Parts. The Documenter is pleased. (Camp)", 4.5)
		"cauldron":
			hero().give("ember_ring")
			stock["reagents"] += 6
			hud.banner("The war-cauldron: an ember ring in the ash, and 6 Reagents. (Camp)", 4.5)
		"rig":
			stock["parts"] += 10
			hud.banner("The drill rig: 10 Parts for the tethers. Arthur will want to hear. (Pallas)", 4.5)
		"pod":
			hero().give("quickdraw_rig")
			stock["salvage"] += 6
			hud.banner("Cargo pod three: the armory locker and a quick-draw rig. Louis will want to hear. (Pallas)", 4.5)
		"saloon":
			hud.banner("The saloon town joins Pallas: %d people now. Louis will want to hear." % Story.state["people"], 4.5)
		_:
			hud.banner("Brought in: %s. %s will want to hear." % [Story.LEADS[lead]["name"], Story.PEOPLE[giver]["name"]], 4.5)
	_refresh_hud()
	save_game()


func _gain_vision(id: String) -> void:
	var h: HeroState = heroes["oracle"]
	if not h.visions.has(id):
		h.visions.append(id)
	var unlock: String = Story.VISIONS[id].get("unlock", "")
	if unlock != "":
		h.unlock_slot(unlock)


func _can_read(world_id: String) -> bool:
	var r := Story.next_reading(world_id)
	return not r.is_empty() and map.stable_count("oracle", world_id) + int(struct_fx("oracle").get("reading", 0)) >= int(r["tiles"])


func _reading_line(world_id: String) -> String:
	var r := Story.next_reading(world_id)
	if not Story.READINGS.has(world_id):
		return ""
	if r.is_empty():
		return "Fully read."
	if _can_read(world_id):
		return "Click to read the past (takes a day)."
	return "To read further: %d stable tiles of this world." % maxi(1, int(r["tiles"]) - int(struct_fx("oracle").get("reading", 0)))


func _read_past(world_id: String) -> void:
	var r := Story.read(world_id)
	_gain_vision(r["vision"])
	Documenter.remark("reading", active, rng, day)
	var v: Dictionary = Story.VISIONS[r["vision"]]
	hud.show_tip("")
	hud.screens.say("Reading the past: %s" % Worlds.world(world_id)["name"], [
		"%s. %s" % [r["title"], r["text"]],
		"Vision: %s. %s" % [v["name"], v["text"]],
	], func() -> void: advance_day())


func _maybe_drop(world_id: String, chance: float) -> void:
	if not Items.DROPS.has(world_id) or rng.randf() > chance * (1.0 + hero().stats()["luck"]):
		return
	var options: Array = Items.DROPS[world_id].filter(func(id): return Items.usable_by(id, active) and not hero().has_item(id))
	if options.is_empty():
		return
	var id: String = options[rng.randi_range(0, options.size() - 1)]
	hero().give(id)
	hud.banner("Found: %s." % Items.item(id)["name"], 3.0)


func on_gear_changed() -> void:
	_refresh_hud()


## Build something at the active region's bench: Ysolde's recipes, the Engineer's blueprints, Pallas's stores.
func craft(id: String, costs: Dictionary) -> void:
	for r in costs:
		if stock.get(r, 0) < costs[r]:
			return
	for r in costs:
		stock[r] -= costs[r]
	hero().give(id)
	hud.banner("Made: %s." % Items.item(id)["name"], 3.0)
	_refresh_hud()


func rest_cost() -> int:
	return REST_COST / 2 if struct_fx(active).get("mess", 0) > 0 else REST_COST


func rest() -> void:
	if stock.get("food", 0) < rest_cost():
		hud.banner("Resting needs %d Food." % rest_cost())
		return
	stock["food"] -= rest_cost()
	hero().injured = false
	hud.banner("Rested. %s is fit again." % hero().short_name())
	_refresh_hud()


## Build a settlement upgrade.
# ------------------------------------------------------------------ structures
## Structures stand on stable tiles. The ground beneath decides what they do and how they
## look; the hero whose land reaches a tile decides what can go there.
var build_pending := ""
const LAMP_EVERY := 2
const SHIFT_DAMAGE_CHANCE := 0.25
const REPAIR_COST := 3


## Every structure on the map: {id, pos, world, damaged, dark}.
func structures() -> Array:
	var out := []
	for pos in map.cells:
		var c: Dictionary = map.cells[pos]
		if c.has("structure") and c["state"] in ["stable", "settling"]:
			out.append({"id": c["structure"]["id"], "pos": pos, "world": c["world"],
				"damaged": bool(c["structure"].get("damaged", false)), "dark": bool(c["structure"].get("dark", false))})
	return out


func struct_count(id: String) -> int:
	var n := 0
	for st in structures():
		if st["id"] == id:
			n += 1
	return n


## Effects of one standing structure, with its ground folded in. Empty if it's out of action.
func struct_effects(st: Dictionary) -> Dictionary:
	if st["damaged"] or st["dark"]:
		return {}
	var d: Dictionary = Items.STRUCTURES[st["id"]]
	var fx: Dictionary = d["fx"].duplicate()
	for k in d["ground"].get(st["world"], {}):
		fx[k] = int(fx.get(k, 0)) + int(d["ground"][st["world"]][k])
	return fx


## Summed effects of the structures a hero's land reaches. Also published as Story.fx[hero].
func struct_fx(hero_id: String) -> Dictionary:
	var out := {}
	var land := map.land_of(hero_id)
	for st in structures():
		if land.has(st["pos"]):
			var fx := struct_effects(st)
			for k in fx:
				out[k] = int(out.get(k, 0)) + int(fx[k])
	return out


func _publish_fx() -> void:
	for h in heroes:
		Story.fx[h] = struct_fx(h)


## Structures the active hero may build: their own, plus those of every hero whose land is joined to theirs.
func structures_for(hero_id: String) -> Array:
	var out := []
	for id in Items.STRUCTURES:
		var owner: String = Items.STRUCTURES[id]["hero"]
		if heroes.has(owner) and (owner == hero_id or map.connected(hero_id, owner)):
			out.append(id)
	return out


func struct_cost(id: String) -> Dictionary:
	var cost: Dictionary = Items.STRUCTURES[id]["cost"].duplicate()
	var n := struct_count(id)
	for r in cost:
		cost[r] = int(cost[r]) * (n + 1)
	return cost


func can_afford(cost: Dictionary) -> bool:
	for r in cost:
		if stock.get(r, 0) < int(cost[r]):
			return false
	return true


## Why a structure can't go on a tile, or "" if it can.
func place_reason(id: String, pos: Vector2i) -> String:
	if not map.cells.has(pos):
		return "Nothing to build on."
	var c: Dictionary = map.cells[pos]
	if c["state"] != "stable":
		return "Only settled land can carry a structure."
	if not map.land_of(active).has(pos):
		return "Not your ground."
	if c.has("structure"):
		return "Something already stands here."
	if c.has("lead") or Items.UNBUILDABLE.has(c["layout"]):
		return "This place is spoken for."
	match Items.STRUCTURES[id]["needs"]:
		"edge":
			var edge := false
			for n in Hex.neighbors(pos):
				if not map.cells.has(n) or map.cells[n]["state"] == "unstable":
					edge = true
			if not edge:
				return "Lamps belong at the edge of the land, against the fog."
		"house":
			var house := false
			for n in Hex.neighbors(pos):
				if map.cells.has(n) and map.cells[n]["layout"] in ["town", "ice_house", "saloon", "pallas_hab", "camp"]:
					house = true
			if not house:
				return "Wants a house beside it."
		"signal":
			var sig := false
			for n in Hex.neighbors(pos):
				if map.cells.has(n) and map.cells[n]["state"] in ["stable", "settling"] and (map.cells[n]["layout"] == "mast" or map.cells[n]["world"] == "leader"):
					sig = true
			if not sig:
				return "Must touch the mast or Leaderboard land."
	return ""


## What a structure would do here, for the tooltip.
func struct_preview(id: String, pos: Vector2i) -> String:
	var d: Dictionary = Items.STRUCTURES[id]
	var c: Dictionary = map.cells[pos]
	var lines := [d["name"], "On %s ground (%s)" % [Worlds.world(c["world"])["name"], Worlds.LAYOUT_NAMES[c["layout"]]]]
	var gt: String = d["ground_text"].get(c["world"], "")
	if gt != "":
		lines.append(gt)
	if c["layout"] == "graves" and id == "shrine":
		lines.append("Beside a grave. It will be asking for something.")
	var reason := place_reason(id, pos)
	lines.append(reason if reason != "" else "Click to build.")
	return "\n".join(lines)


## From the Build tab: close the screen and pick a tile.
func begin_build(id: String) -> void:
	if mode != "territory" or not structures_for(active).has(id):
		return
	if struct_count(id) >= int(Items.STRUCTURES[id]["limit"]) or not can_afford(struct_cost(id)):
		return
	build_pending = id
	mode = "build"
	hud.screens.close()
	hud.set_mode(mode)
	hud.banner("Choose a settled tile for the %s. Right-click to cancel." % Items.STRUCTURES[id]["name"].to_lower(), 4.0)


func cancel_build() -> void:
	build_pending = ""
	if mode == "build":
		mode = "territory"
		hud.set_mode(mode)
	map.set_hover_style(-1)
	hud.show_tip("")
	_refresh_hud()


func place_structure(pos: Vector2i) -> void:
	var id := build_pending
	var reason := place_reason(id, pos)
	if reason != "":
		hud.banner(reason, 3.0)
		return
	var cost := struct_cost(id)
	if not can_afford(cost):
		hud.banner("Not enough to build it.", 3.0)
		return
	for r in cost:
		stock[r] -= int(cost[r])
	var c: Dictionary = map.cells[pos]
	c["structure"] = {"id": id, "damaged": false, "dark": false, "built_day": day}
	c.erase("lead")
	if id == "shrine" and c["layout"] == "graves":
		Story.add_omen("A shrine of oracle glass stands on a grave. Something has noticed the asking.")
	map.refresh(pos)
	map.update_lights()
	map._seams.queue_redraw()
	cancel_build()
	_publish_fx()
	for h in heroes:
		map.glimpse_count[h] = _glimpse_count(h)
	hud.banner("Built: %s, on %s ground." % [Items.STRUCTURES[id]["name"], Worlds.world(c["world"])["name"]], 3.5)
	Documenter.remark("built", active, rng, day)
	_refresh_hud()
	save_game()


func repair_cost(pos: Vector2i) -> Dictionary:
	return {Worlds.MATERIAL[map.cells[pos]["world"]]: REPAIR_COST}


func repair_structure(pos: Vector2i) -> void:
	var c: Dictionary = map.cells[pos]
	if not c.has("structure") or not c["structure"].get("damaged", false):
		return
	var cost := repair_cost(pos)
	if not can_afford(cost):
		hud.banner("Repair needs %d %s, the material of the ground it stands on." % [REPAIR_COST, Worlds.RESOURCE_NAMES[cost.keys()[0]]], 3.5)
		return
	for r in cost:
		stock[r] -= int(cost[r])
	c["structure"]["damaged"] = false
	map.refresh(pos)
	map.update_lights()
	_publish_fx()
	hud.banner("Repaired: %s." % Items.STRUCTURES[c["structure"]["id"]]["name"], 3.0)
	_refresh_hud()


## Daily upkeep: what structures produce, what the lamps burn, what the Drift takes.
func _structures_daily(shifted: bool) -> String:
	var msg := ""
	var production := {}
	for st in structures():
		var fx := struct_effects(st)
		for r in ["food", "parts", "reagents"]:
			if fx.has(r):
				production[r] = int(production.get(r, 0)) + int(fx[r])
		if fx.has("power") and heroes.has("engineer"):
			production["power"] = int(production.get("power", 0)) + int(fx["power"])
	for r in production:
		stock[r] += production[r]
	# lamps burn sunstone
	for st in structures():
		if st["id"] != "lamps" or st["damaged"]:
			continue
		var every := LAMP_EVERY * (2 if Items.STRUCTURES["lamps"]["ground"].get(st["world"], {}).has("lamp_slow") else 1)
		var c: Dictionary = map.cells[st["pos"]]
		if (day - int(c["structure"].get("built_day", 0))) % every == 0:
			if stock["sunstone"] >= 1:
				stock["sunstone"] -= 1
				if c["structure"].get("dark", false):
					c["structure"]["dark"] = false
					msg += ". The lamps relight"
			elif not c["structure"].get("dark", false):
				c["structure"]["dark"] = true
				msg += ". The lamps go dark for want of Sunstone"
			map.refresh(st["pos"])
	# the Drift gnaws at structures on the edge
	if shifted:
		for st in structures():
			if st["damaged"]:
				continue
			var edge := false
			for n in Hex.neighbors(st["pos"]):
				if not map.cells.has(n) or map.cells[n]["state"] == "unstable":
					edge = true
			if edge and rng.randf() < SHIFT_DAMAGE_CHANCE:
				map.cells[st["pos"]]["structure"]["damaged"] = true
				map.refresh(st["pos"])
				msg += ". The shift cracked the %s" % Items.STRUCTURES[st["id"]]["name"].to_lower()
				Documenter.remark("damaged", active, rng, day)
	map.update_lights()
	_publish_fx()
	return msg


## Older saves kept upgrades as levels. They become structures on the nearest fitting tile.
func _migrate_upgrades() -> void:
	var old: Dictionary = Story.state.get("upgrades", {})
	if old.is_empty():
		return
	var rename := {"palisade": "infirmary", "swarm_forge": "forge"}
	for key in old:
		var id: String = rename.get(key, key)
		if not Items.STRUCTURES.has(id):
			continue
		var owner: String = Items.STRUCTURES[id]["hero"]
		if not heroes.has(owner):
			continue
		for i in range(int(old[key])):
			var best := MaelstromMap.NONE
			var bd := 999
			var saved := active
			active = owner
			for pos in map.land_of(owner):
				if place_reason(id, pos) == "" or (place_reason(id, pos).begins_with("Lamps") or place_reason(id, pos).begins_with("Wants") or place_reason(id, pos).begins_with("Must")):
					var d := Hex.distance(pos, MaelstromMap.HOMES[owner])
					if d < bd and not map.cells[pos].has("structure") and not Items.UNBUILDABLE.has(map.cells[pos]["layout"]) and map.cells[pos]["state"] == "stable":
						bd = d
						best = pos
			active = saved
			if best != MaelstromMap.NONE:
				map.cells[best]["structure"] = {"id": id, "damaged": false, "dark": false, "built_day": day}
	Story.state["upgrades"] = {}
	map.rebuild_all()
	_publish_fx()


## Burn sunstone for Power (the Law of the Frozen Sun).
func burn_sunstone() -> void:
	if stock["sunstone"] >= 2:
		stock["sunstone"] -= 2
		stock["power"] += 3
		_refresh_hud()


# ------------------------------------------------------------------ chapters
## Moves the story on when its conditions are met. Called after talks, days and returns.
func check_story() -> void:
	if _story_busy or mode != "territory" or hud.screens.is_open():
		return
	var t := Documenter.due()
	if not t.is_empty():
		_transmission(t)
		return
	if Story.flag("ch1_done") and not heroes.has("engineer"):
		_start_chapter2()
	elif Story.flag("ch2_done") and not heroes.has("gunslinger"):
		_start_chapter3()
	elif map.connected("oracle", "engineer") and not Story.seen("meet_oracle_engineer"):
		_play_scene("meet_oracle_engineer", func() -> void:
			Story.add_chronicle("meet_oracle_engineer")
			_on_connected("engineer")
			check_story())
	elif heroes.has("gunslinger") and map.connected("gunslinger", "any") and not Story.seen("meet_gunslinger"):
		_play_scene("meet_gunslinger", func() -> void:
			Story.add_chronicle("meet_gunslinger")
			heroes["gunslinger"].unlock_slot("ring2")
			_on_connected("gunslinger")
			check_story())
	elif heroes.has("gunslinger") and map.connected("oracle", "engineer") and map.connected("gunslinger", "any") and not Story.seen("act1_end"):
		_play_scene("act1_end", func() -> void:
			Story.add_chronicle("act1_end")
			Story.set_flag("act1_done")
			for h in heroes.values():
				h.unlock_slot("ring2")
			save_game())
	else:
		var talk := _next_conversation()
		if not talk.is_empty():
			_play_conversation(talk)


## One of the Documenter's story beats, spoken through the dialog box as a transmission.
## Its gifts (leads, flags, chronicle) land at once, so the story can move even if the
## player clicks through.
func _transmission(t: Dictionary) -> void:
	var gives := Story.hear("documenter")
	hud.show_tip("")
	hud.screens.say("The Documenter", t["pages"], func() -> void:
		on_heard("documenter", gives)
		check_story())


## A hero's land has joined the capital's: their structures can be built there now.
func _on_connected(hero_id: String) -> void:
	Story.set_flag("joined_%s" % hero_id)
	Documenter.remark("connected", active, rng, day, true)
	hud.banner("%s's people are welcome in the town. New structures can be built there." % heroes[hero_id].short_name(), 4.0)


## A conversation between two heroes, if one is due. Lowest priority of the story beats.
func _next_conversation() -> Dictionary:
	var last: Dictionary = Story.state.get("talk_day", {})
	for c in Story.CONVERSATIONS:
		if Story.seen(c["id"]):
			continue
		var a: String = c["pair"][0]
		var b: String = c["pair"][1]
		if not heroes.has(a) or not heroes.has(b) or not map.connected(a, b):
			continue
		if not Story.seen(c["after"]) or not Story.met(c["needs"]):
			continue
		var key := "%s_%s" % [a, b]
		var since: int = maxi(int(last.get(key, 0)), int(Story.state.get("met_day", {}).get(c["after"], 0)))
		if day - since < int(c["gap"]):
			continue
		return c
	return {}


func _play_conversation(c: Dictionary) -> void:
	_story_busy = true
	hud.screens.scene(c["lines"], func() -> void:
		Story.state["scenes_seen"].append(c["id"])
		if not Story.state.has("talk_day"):
			Story.state["talk_day"] = {}
		Story.state["talk_day"]["%s_%s" % c["pair"]] = day
		Story.state["met_day"] = Story.state.get("met_day", {})
		Story.state["met_day"][c["id"]] = day
		Story.add_chronicle(c["id"])
		_story_busy = false
		save_game()
		check_story())


func _play_scene(id: String, done: Callable) -> void:
	Story.mark_seen(id)
	if not Story.state.has("met_day"):
		Story.state["met_day"] = {}
	Story.state["met_day"][id] = day
	_story_busy = true
	hud.show_tip("")
	hud.screens.scene(Story.SCENES[id], func() -> void:
		_story_busy = false
		if done.is_valid():
			done.call())


var _prologue_hero := ""
var _prologue_done: Callable


## Chapter 2: the attack on the Player, the transfusion, the burial, and the Engineer's region.
func _start_chapter2() -> void:
	_story_busy = true
	heroes["engineer"] = HeroState.new("engineer")
	hud.screens.scene(Story.SCENES["ch2_intro"], func() -> void:
		hud.screens.scene(Story.SCENES["ch2_ambush_start"], func() -> void:
			_prologue_hero = "engineer"
			_prologue_done = _after_ambush
			hud.tactics.start("ambush", heroes["engineer"], heroes["engineer"].stats()["hp"], 1)))


func _prologue_finished(won: bool, hp: int, result: Dictionary) -> void:
	heroes[_prologue_hero].injured = not won
	if _prologue_hero == "engineer":
		heroes["engineer"].gain_xp(int(result["xp"]) + 10)
	if _prologue_done.is_valid():
		_prologue_done.call(won)


func _after_ambush(_won: bool) -> void:
	hud.screens.scene(Story.SCENES["ch2_ambush_end"], func() -> void:
		Story.add_chronicle("ch2_ambush")
		Story.add_chronicle("ch2_transfusion")
		Story.unlock_hero("engineer")
		map.open_region("engineer")
		stock["power"] += 6
		stock["parts"] += 4
		_story_busy = false
		switch_hero("engineer")
		hud.banner("Chapter 2. The Engineer holds his ground with anchors. The Documenter will speak when it has something to say.", 5.0)
		save_game()
		check_story())


## Chapter 3: Pallas falls, Alysia holds the airlock, and her region opens.
func _start_chapter3() -> void:
	_story_busy = true
	heroes["gunslinger"] = HeroState.new("gunslinger")
	hud.screens.scene(Story.SCENES["ch3_intro"], func() -> void:
		Story.add_chronicle("ch3_crash")
		map.open_region("gunslinger")
		hud.screens.scene(Story.SCENES["ch3_crash_start"], func() -> void:
			_prologue_hero = "gunslinger"
			_prologue_done = _after_crash
			hud.tactics.start("crash_site", heroes["gunslinger"], heroes["gunslinger"].stats()["hp"], 1)))


func _after_crash(won: bool) -> void:
	hud.screens.scene(Story.SCENES["ch3_crash_end"], func() -> void:
		Story.unlock_hero("gunslinger")
		stock["parts"] += 8 if won else 4
		stock["salvage"] += 6
		_story_busy = false
		switch_hero("gunslinger")
		hud.banner("Chapter 3. Alysia holds land with Pallas's tethers: 1 Part per tile. Talk to the crew (T).", 5.0)
		save_game())


# ------------------------------------------------------------------ saving
func save_game() -> void:
	if _scripted or mode != "territory" or _story_busy:
		return
	var cells := {}
	for pos in map.cells:
		cells["%d,%d" % [pos.x, pos.y]] = map.cells[pos]
	var glimpses := {}
	for h in map.glimpses:
		glimpses[h] = map.glimpses[h].map(func(g): return [g.x, g.y])
	var hs := {}
	for h in heroes:
		hs[h] = heroes[h].to_dict()
	var data := {"version": SAVE_VERSION, "day": day, "stock": stock, "discovered": discovered, "active": active,
		"cells": cells, "glimpses": glimpses, "open_regions": map.open_regions, "heroes": hs, "story": Story.state, "events": Events.seen}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text()) if f else null
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", 0)) < 2 or int(data.get("version", 0)) > SAVE_VERSION:
		return false
	day = int(data["day"])
	for r in Worlds.RESOURCES:
		stock[r] = int(data["stock"].get(r, 0))
	discovered = data["discovered"]
	map.cells.clear()
	for key in data["cells"]:
		var xy: PackedStringArray = key.split(",")
		map.cells[Vector2i(int(xy[0]), int(xy[1]))] = _fix_cell(data["cells"][key])
	map.open_regions = data["open_regions"]
	for h in data["glimpses"]:
		map.glimpses[h] = []
		for g in data["glimpses"][h]:
			map.glimpses[h].append(Vector2i(int(g[0]), int(g[1])))
	heroes = {}
	for h in data["heroes"]:
		heroes[h] = HeroState.from_dict(data["heroes"][h])
	active = data.get("active", "oracle")
	if not heroes.has(active):
		active = "oracle"
	Story.state = data["story"]
	for id in Story.state["talk"]:
		Story.state["talk"][id] = int(Story.state["talk"][id])
	for w in Story.state["readings"]:
		Story.state["readings"][w] = int(Story.state["readings"][w])
	Story.state["new_chronicle"] = int(Story.state["new_chronicle"])
	Story.state["people"] = int(Story.state["people"])
	if not Story.state.has("omens"):
		Story.state["omens"] = []
	if not Story.state.has("upgrades"):
		Story.state["upgrades"] = {}
	for k in Story.state["upgrades"]:
		Story.state["upgrades"][k] = int(Story.state["upgrades"][k])
	Events.seen = data.get("events", [])
	map.active_hero = active
	map.hero.texture = TileFactory.hero_texture(active)
	map.rebuild_all()
	_migrate_upgrades()
	for h in heroes:
		map.glimpse_count[h] = _glimpse_count(h)
	_enter_territory()
	focus_camera(true)
	hud.banner("Welcome back. Day %d." % day, 3.0)
	return true


## JSON turns numbers into floats; put the integers back.
func _fix_cell(c: Dictionary) -> Dictionary:
	for k in ["settle", "seed", "fragment", "fused_day"]:
		if c.has(k):
			c[k] = int(c[k])
	if c.has("previous"):
		c["previous"] = _fix_cell(c["previous"])
	if c.has("structure") and c["structure"].has("built_day"):
		c["structure"]["built_day"] = int(c["structure"]["built_day"])
	return c


func start_over() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	hud.screens.close()
	new_game()


# ------------------------------------------------------------------ helpers
func _discover(combos: Array) -> void:
	for id in combos:
		if not discovered.has(id):
			discovered.append(id)
			hud.banner("Discovered: %s. %s" % [Rules.COMBOS[id]["name"], Rules.COMBOS[id]["text"]], 4.0)


func _sum(entries: Array) -> Dictionary:
	var out := {}
	for e in entries:
		out[e["res"]] = out.get(e["res"], 0) + e["amt"]
	return out


func _gain_text(gains: Dictionary) -> String:
	var parts := []
	for r in Worlds.RESOURCES:
		if gains.get(r, 0) != 0:
			parts.append("%+d %s" % [gains[r], Worlds.RESOURCE_NAMES[r]])
	return ", ".join(parts) if parts else "nothing"


func _float_text(at: Vector2, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", load("res://fonts/PixelifySans.ttf"))
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color("#f0b050"))
	l.add_theme_color_override("font_outline_color", Color("#120d1a"))
	l.add_theme_constant_override("outline_size", 2)
	l.z_index = 30
	l.position = at - Vector2(text.length() * 2, 0)
	map.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", at.y - 10, 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.9)
	tw.tween_callback(l.queue_free)


func _refresh_hud() -> void:
	Story.active_hero = active
	Story.day = day
	_publish_fx()
	hud.set_resources(stock)
	var progress := 0.0
	if way_phase in ["walk", "map"] and way.path.size() > 1:
		progress = float(way_index) / float(way.path.size() - 1)
	hud.set_day(day, SHIFT_EVERY - (day % SHIFT_EVERY), progress)
	hud.set_combos(discovered)
	var territory := Rules.totals(Rules.evaluate(map.cells))
	if heroes.has("engineer"):
		territory["power"] += MAST_POWER + int(struct_fx("engineer").get("power", 0)) - _anchor_count()
	if heroes.has("gunslinger"):
		territory["parts"] += 1 + heroes["gunslinger"].stats()["parts"]
	hud.set_territory_yield(territory)
	var st := hero().stats()
	hud.set_hero(active, hero_hp, st["hp"], foresight, st["fs"])
	hud.set_heroes(heroes.keys(), active)
	hud.set_news(Story.any_news(active), int(Story.state["new_chronicle"]))
	var frag := 0
	if target != MaelstromMap.NONE and mode != "territory":
		frag = _fragment_cells().size()
	hud.set_loot(loot, frag, FRAGMENT_LIMIT + st["pack"])
	hud.set_hand(hand, selected)
