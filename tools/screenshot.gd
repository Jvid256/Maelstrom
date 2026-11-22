extends Node
## Development helper: plays a short scripted session and saves screenshots.
## Run with:  godot --path . -- --shot=/path/to/prefix

var path := ""


func _snap(name: String) -> void:
	for i in range(12):
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s_%s.png" % [path, name])
	print("saved ", name)


func _ready() -> void:
	await get_tree().process_frame
	var main := get_parent()
	var map: MaelstromMap = main.map
	main.set_process(false)
	var goal: Vector2i = map.glimpses["oracle"][0]
	map._hovered = goal
	map._hover_sprite.position = map.center_of(goal)
	main._on_hover(goal, true)
	main.hud._tip.position = Vector2(240, 150)
	Documenter.remark("day", "oracle", main.rng, main.day, true)
	main.hud._doc_label.visible_characters = -1
	await _snap("territory")

	# the town with structures on several grounds
	for r in Worlds.RESOURCES:
		main.stock[r] += 60
	var ring := Hex.neighbors(MaelstromMap.HOMES["oracle"])
	var worlds := ["kingdom", "eroded", "hollow", "frozen", "coven", "leader"]
	var ids := ["lamps", "infirmary", "shrine", "forge", "mess_hall", "capacitor"]
	for i in range(6):
		var pos: Vector2i = ring[i]
		main.map.cells[pos]["world"] = worlds[i]
		main.map.cells[pos]["structure"] = {"id": ids[i], "damaged": i == 3, "dark": false, "built_day": 1}
	main.map.rebuild_all()
	main._refresh_hud()
	main.hud.show_tip("")
	main.camera.position = main.map.center_of(MaelstromMap.HOMES["oracle"]) + Vector2(40, 10)
	main.camera.reset_smoothing()
	await _snap("structures")
	main.camera.zoom = Vector2(0.3, 0.3)
	main.camera.position = main.map.pixel_size() / 2.0
	main.camera.reset_smoothing()
	await _snap("overview")
	main.camera.zoom = Vector2(1, 1)
	for i in range(6):
		main.map.cells[ring[i]]["world"] = "kingdom"
		main.map.cells[ring[i]].erase("structure")
	main.map.rebuild_all()
	main._on_hover(goal, true)
	main.hud._tip.position = Vector2(240, 150)

	main._start_expedition(goal)
	main.hand = [
		{"world": "eroded", "layout": "dunes"}, {"world": "frozen", "layout": "ice"},
		{"world": "hollow", "layout": "deadwood"}, {"world": "eroded", "layout": "felled"},
		{"world": "frozen", "layout": "ice_house"},
	]
	var placed := 0
	for r in main.route:
		for n in Hex.neighbors(r):
			if placed < 4 and map.can_shape(n, main.route) and main.hand.size() > 1:
				main.selected = 0
				main._on_click(n, MOUSE_BUTTON_LEFT)
				placed += 1
	main._refresh_hud()
	await _snap("plan")
	# route through a tile off the direct way
	for pos in main.map.cells:
		if main.map.cells[pos]["state"] == "unstable" and Hex.distance(pos, main.route[main.route.size() / 2]) == 2 and not main.route.has(pos):
			main._toggle_waypoint(pos)
			if not main.waypoints.is_empty():
				break
	main.map.cells[main.route[2]]["notables"] = [{"type": "find", "id": "well", "done": false}]
	main.map.cells[main.route[2]]["known"] = true
	main.map.refresh_notes()
	main._on_hover(main.route[2], true)
	main.hud._tip.position = Vector2(200, 230)
	await _snap("plan_route")
	main._step()  # sets out onto the Way
	main.paused = true
	for i in range(12):
		main.way_index += 1
		main.way.hero.position = main.way.hero_at(main.way_index)
	main.camera.position = main.way.hero.global_position + Vector2(70, 0)
	main.camera.reset_smoothing()
	main._refresh_hud()
	await _snap("expedition")
	# a camp
	if not main._camps.is_empty():
		var ck: int = main._camps[0]
		main.way_index = main.way.stretches[ck]["last"]
		main.way.hero.position = main.way.hero_at(main.way_index)
		main.camera.position = main.way.hero.global_position + Vector2(70, 0)
		main.camera.reset_smoothing()
		await _snap("camp_road")
		main._make_camp(ck)
		await _snap("camp")
		main.hud.screens.resolve_choice(0)
		for i in range(10):
			if main.hud.screens._dialog.visible:
				main.hud.screens.advance()
			if main.hud.screens._choice_open:
				main.hud.screens.resolve_choice(0)
		main.mode = "expedition"
	# meeting something on the road
	for k in main._encounters.keys():
		var ei: int = main._encounter_index(k)
		main.way_index = maxi(0, ei - 3)
		main.way.hero.position = main.way.hero_at(main.way_index)
		main.camera.position = main.way.hero.global_position + Vector2(70, 0)
		main.camera.reset_smoothing()
		main._approach(k)
		await _snap("approach")
		main.hud.screens.resolve_choice(0)
		main.mode = "expedition"
		break
	# a notable up close
	for k in range(1, main.way.stretches.size()):
		if not main.way.stretches[k]["notables"].is_empty():
			var nb: Dictionary = main.way.stretches[k]["notables"][0]
			main.way_index = nb["stop"]
			main.way.hero.position = main.way.hero_at(main.way_index)
			main._pending = [k, 0]
			main._stop_wait = 99.0
			main.hud.show_tip("%s\nE: examine. Space: walk on." % Notables.look(nb["n"])["name"])
			main.hud._tip.position = Vector2(200, 60)
			main.camera.position = main.way.hero.global_position + Vector2(70, 0)
			main.camera.reset_smoothing()
			await _snap("notable")
			main._pending = []
			main.hud.show_tip("")
			break
	var ev: Dictionary = Events.EXPEDITION[8]
	main._run_event(ev)
	await _snap("event")
	main.hud.screens.resolve_choice(1)
	await _snap("event_result")
	while main.hud.screens._dialog.visible:
		main.hud.screens.advance()
	main.mode = "expedition"

	main.way_phase = ""
	main.mode = "battle"
	main.hud.battle.start(["restless", "wisp"], main.hero(), main.hero_hp, main.foresight, main.supplies)
	await get_tree().create_timer(0.9).timeout
	await _snap("battle")
	while main.mode == "battle":
		await get_tree().process_frame
	main._return_home("retreat")
	await get_tree().create_timer(0.5).timeout

	# the Engineer: ambush
	main.heroes["engineer"] = HeroState.new("engineer")
	main.hud.tactics.start("ambush", main.heroes["engineer"], 26, 1)
	await _snap("ambush")
	main.hud.tactics.visible = false
	# Alysia: the crash site, and her hero screen
	main.heroes["gunslinger"] = HeroState.new("gunslinger")
	main.hud.tactics.start("crash_site", main.heroes["gunslinger"], 26, 1)
	await _snap("crash")
	main.hud.tactics.visible = false
	Story.unlock_hero("engineer")
	Story.unlock_hero("gunslinger")
	map.open_region("engineer")
	map.open_region("gunslinger")
	main.active = "gunslinger"
	main.mode = "territory"
	main.hud.set_mode("territory")
	main._refresh_hud()
	main.focus_camera(true)
	await _snap("pallas")
	main.active = "oracle"
	main.fx.set_hero("oracle")
	await get_tree().create_timer(1.8).timeout
	main.open_screen("town")
	await _snap("town")
	# a rumour
	main.hud.screens.close()
	Story.state["rumour_day"] = {}
	var rumour := ""
	for i in range(20):
		Story.state["rumour_day"] = {}
		rumour = main.town_chatter("maren")
		if rumour != "":
			break
	main.hud.screens.say("Maren Holt", [rumour], Callable())
	await _snap("rumour")
	main.hud.screens.advance()
	main.mode = "territory"
	main.hud.set_mode("territory")
	main.focus_camera(true)
	await _snap("rumour_map")
	main.active = "engineer"
	main.fx.set_hero("engineer")
	main._refresh_hud()
	main.focus_camera(true)
	await get_tree().create_timer(1.8).timeout
	await _snap("grade_engineer")
	main.active = "gunslinger"
	main.fx.set_hero("gunslinger")
	main._refresh_hud()
	main.focus_camera(true)
	await get_tree().create_timer(1.8).timeout
	await _snap("grade_gunslinger")
	main.active = "oracle"
	main.fx.set_hero("oracle")
	main.hud.screens.close()
	main.hud.screens._tab = "Build"
	main.open_screen("town")
	await _snap("town_build")
	main.hud.screens.close()
	main.hud.screens._tab = "Worlds"
	main.open_screen("chronicle")
	await _snap("chronicle")
	main.hud.screens.close()
	main.active = "gunslinger"
	main.heroes["gunslinger"].give("ammo_silver")
	main.heroes["gunslinger"].give("python_longbarrel")
	main.open_screen("hero")
	await _snap("alysia")
	main.hud.screens.close()
	main.active = "engineer"
	main.heroes["engineer"].gain_xp(45)
	main.hud.screens._tab = "Growth"
	main.open_screen("hero")
	await _snap("engineer")
	main.hud.screens.close()
	main.hud.screens.scene(Story.SCENES["meet_gunslinger"].slice(0, 2), Callable())
	main.hud.screens.advance()
	await _snap("scene")
	get_tree().quit()
