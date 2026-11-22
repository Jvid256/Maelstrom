class_name Screens
extends Control
## Modal screens over the map: the active region's town (or camp, or station), the
## Chronicle, the active hero and their gear and growth, and story dialog and scenes.
## Each screen is rebuilt when opened, from the game's current state. `game` is main.gd.

signal closed

var game: Node
var current := ""
var _dim: ColorRect
var _panel: PanelContainer
var _dialog: PanelContainer
var _dialog_name: Label
var _dialog_text: Label
var _dialog_pages: Array = []  # [speaker, text]
var _dialog_done: Callable
var _choice_box: VBoxContainer
var _choice_cb: Callable
var _hint: Label
var _detail: Label
var _tab := ""
var _person := ""
var _choice_open := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.01, 0.04, 0.6)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	add_child(_dim)
	_build_dialog()


func is_open() -> bool:
	return current != "" or _dialog.visible


func hero() -> HeroState:
	return game.hero()


# ------------------------------------------------------------------ frame
func _open_frame(title: String, tabs: Array, active: String) -> VBoxContainer:
	if _panel:
		_panel.queue_free()
	_dim.visible = true
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(560, 300)
	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.position.y += 4
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	_panel.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 4)
	col.add_child(head)
	var t := Label.new()
	t.text = title
	t.add_theme_color_override("font_color", Hud.GOLD)
	head.add_child(t)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(6, 0)
	head.add_child(spacer)
	for tab in tabs:
		var b := _list_button(head, tab, tab == active)
		b.clip_text = false
		b.pressed.connect(func() -> void: _switch_tab(tab))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(fill)
	var x := _list_button(head, "Close (Esc)", false)
	x.clip_text = false
	x.pressed.connect(close)
	var rule := ColorRect.new()
	rule.color = Hud.PANEL_LIGHT
	rule.custom_minimum_size = Vector2(0, 1)
	col.add_child(rule)
	return col


func close() -> void:
	if _panel:
		_panel.queue_free()
		_panel = null
	current = ""
	_dim.visible = _dialog.visible
	closed.emit()


func _switch_tab(tab: String) -> void:
	_tab = tab
	open(current)


func open(view: String) -> void:
	current = view
	match view:
		"town":
			_open_town()
		"chronicle":
			_open_chronicle()
		"hero":
			_open_hero()


func _split(col: VBoxContainer) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(row)
	return row


# ------------------------------------------------------------------ town
func _open_town() -> void:
	var region: String = game.active
	var people: Array = Story.people_in(region)
	if not people.has(_person):
		_person = people[0]
	var tabs := ["People"]
	var bench_name := ""
	match region:
		"oracle":
			if Story.flag("workbench"):
				bench_name = "Bench"
		"engineer":
			bench_name = "Bench"
		"gunslinger":
			if Story.flag("outpost"):
				bench_name = "Stores"
	if bench_name != "":
		tabs.append(bench_name)
	tabs.append("Build")
	if not tabs.has(_tab):
		_tab = "People"
	var title: String = {"oracle": "TOWN", "engineer": "THE CAMP", "gunslinger": "PALLAS"}[region]
	if region == "gunslinger":
		title += "  (%d people, %s)" % [int(Story.state["people"]), _settlement_name()]
	var col := _open_frame(title, tabs, _tab)
	var row := _split(col)
	if _tab == "Build":
		_town_build(row, region)
		return
	if _tab != "People":
		_town_bench(row, region)
		return
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(160, 0)
	list.add_theme_constant_override("separation", 1)
	row.add_child(list)
	for id in people:
		var p: Dictionary = Story.PEOPLE[id]
		var b := _list_button(list, ("! " if Story.has_news(id) else ("* " if TownTalk.has_word(id) else "  ")) + p["name"], id == _person)
		b.pressed.connect(func() -> void:
			_person = id
			open("town"))
	if hero().injured:
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 6)
		list.add_child(gap)
		var rest := _list_button(list, "  Rest (%d Food)" % game.rest_cost(), false)
		rest.pressed.connect(func() -> void:
			game.rest()
			open("town"))
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 3)
	row.add_child(right)
	var p: Dictionary = Story.PEOPLE[_person]
	_text(right, p["name"], Hud.TEXT)
	_text(right, p["origin"], Hud.DIM)
	_text(right, p["about"], Hud.TEXT)
	var leads := []
	for lid in Story.state["leads_active"]:
		if Story.LEADS[lid]["giver"] == _person:
			leads.append(Story.LEADS[lid]["name"])
	if leads:
		_text(right, "Lead: " + ", ".join(leads) + " (cyan marker in the fog)", Color("#9fe0e6"))
	var b := Button.new()
	b.text = "Talk" if Story.has_news(_person) else ("Visit" if _person == "grave" else ("Hear their news" if TownTalk.has_word(_person) else "Say hello"))
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	right.add_child(b)
	b.pressed.connect(func() -> void:
		var person := _person
		if Story.has_news(person):
			var t := Story.next_talk(person)
			say(Story.PEOPLE[person]["name"], t["pages"], func() -> void:
				game.on_heard(person, Story.hear(person))
				open("town"))
		else:
			var chat: String = game.town_chatter(person)
			say(Story.PEOPLE[person]["name"], [chat if chat != "" else Story.PEOPLE[person]["idle"]], func() -> void: open("town")))


func _settlement_name() -> String:
	var n: int = int(Story.state["people"])
	if n >= 14:
		return "a town"
	if n >= 8:
		return "an outpost"
	return "a camp"


func _town_bench(row: HBoxContainer, region: String) -> void:
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(list)
	var recipes := {}
	match region:
		"oracle":
			recipes = Items.RECIPES.duplicate()
			if not Story.flag("coven_recipes"):
				recipes.erase("hexwood_charm")
				recipes.erase("trench_coat")
			_text(list, "Ysolde makes gear from materials. Hover a recipe to see what it does.", Hud.DIM)
		"engineer":
			for bp in hero().blueprints:
				if Items.BLUEPRINTS.has(bp):
					recipes[bp] = Items.BLUEPRINTS[bp]
			_text(list, "The Engineer's bench builds studied blueprints. Fugue builds in fights become blueprints once the Blueprints skill is learned." if recipes.is_empty()
				else "Blueprints studied from fugue builds. Hover one to see what it does.", Hud.DIM)
			if Story.law_known("frozen"):
				var burn := Button.new()
				burn.text = "Burn 2 Sunstone for 3 Power (%d Sunstone)" % game.stock["sunstone"]
				burn.focus_mode = Control.FOCUS_NONE
				burn.disabled = game.stock["sunstone"] < 2
				burn.pressed.connect(func() -> void:
					game.burn_sunstone()
					open("town"))
				list.add_child(burn)
		"gunslinger":
			for id in Items.PALLAS_SHOP:
				var it := Items.item(id)
				if it.has("gun") and not Story.flag("workshop"):
					continue
				recipes[id] = Items.PALLAS_SHOP[id]
			_text(list, "Arthur and Louis trade Pallas's stores for what you bring. Gun work opens when Pallas is a town.", Hud.DIM)
	for id in recipes:
		var cost: Dictionary = recipes[id]
		var parts := []
		var ok := true
		for r in cost:
			parts.append("%d %s" % [cost[r], Worlds.RESOURCE_NAMES[r]])
			if game.stock.get(r, 0) < cost[r]:
				ok = false
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 4)
		list.add_child(line)
		var b := Button.new()
		b.text = "Make"
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = not ok
		line.add_child(b)
		var l := Label.new()
		l.text = "%s  (%s)" % [Items.item(id)["name"], ", ".join(parts)]
		l.add_theme_color_override("font_color", Hud.TEXT if ok else Hud.DIM)
		line.add_child(l)
		var item_id: String = id
		b.mouse_entered.connect(func() -> void: _detail.text = _item_detail(item_id))
		b.pressed.connect(func() -> void:
			game.craft(item_id, cost)
			open("town"))
	_detail = _text(list, "", Hud.DIM)


func _town_build(row: HBoxContainer, region: String) -> void:
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(list)
	var joined := []
	for h in game.heroes:
		if h != region and game.map.connected(region, h):
			joined.append(HeroState.HEROES[h]["short"])
	var intro: String = {"oracle": "Structures stand on settled tiles of the town's land. The ground beneath decides what they do and what they're made of.",
		"engineer": "The camp builds what the mast can power. Join the land to the town and the rest opens.",
		"gunslinger": "Pallas builds for its people. Join the land to the town and the rest opens."}[region]
	if not joined.is_empty():
		intro += " Joined with %s: their structures can be built here too." % " and ".join(joined)
	_text(list, intro, Hud.DIM)
	var standing: Array = game.structures()
	for id in game.structures_for(region):
		var d: Dictionary = Items.STRUCTURES[id]
		var count: int = game.struct_count(id)
		var maxed: bool = count >= int(d["limit"])
		var cost: Dictionary = game.struct_cost(id)
		var parts := []
		for r in cost:
			parts.append("%d %s" % [cost[r], Worlds.RESOURCE_NAMES[r]])
		var ok: bool = not maxed and game.can_afford(cost)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 4)
		list.add_child(line)
		var b := Button.new()
		b.text = "Standing" if maxed else "Place"
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = not ok
		line.add_child(b)
		var l := Label.new()
		l.text = "%s%s  (%s)" % [d["name"], " %d/%d" % [count, d["limit"]] if int(d["limit"]) > 1 else "", "all built" if maxed else ", ".join(parts)]
		l.add_theme_color_override("font_color", Hud.TEXT if (ok or maxed) else Hud.DIM)
		line.add_child(l)
		_text(list, "    " + d["text"], Hud.DIM)
		var sid: String = id
		b.pressed.connect(func() -> void: game.begin_build(sid))
	var damaged := []
	for st in standing:
		if st["damaged"]:
			damaged.append("%s (%d %s)" % [Items.STRUCTURES[st["id"]]["name"], game.REPAIR_COST, Worlds.RESOURCE_NAMES[Worlds.MATERIAL[st["world"]]]])
	if not damaged.is_empty():
		_text(list, "Damaged, click on the map to repair: " + ", ".join(damaged), Hud.BLOOD)
	_detail = _text(list, "", Hud.DIM)


# ------------------------------------------------------------------ chronicle
func _open_chronicle() -> void:
	var tabs := ["People", "Places", "Worlds", "Story", "Omens", "Visions", "Combos"]
	if not Story.state["laws"].is_empty():
		tabs.insert(3, "Laws")
	if not Documenter.record().is_empty():
		tabs.append("Record")
	if not tabs.has(_tab):
		_tab = "People"
	Story.state["new_chronicle"] = 0
	var col := _open_frame("CHRONICLE", tabs, _tab)
	var row := _split(col)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(190, 0)
	list.add_theme_constant_override("separation", 1)
	row.add_child(list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	_detail = _text(right, "", Hud.TEXT)
	var entries := []  # [title, text]
	match _tab:
		"Visions":
			var o: HeroState = game.heroes["oracle"]
			for v in o.visions:
				entries.append([Story.VISIONS[v]["name"], Story.VISIONS[v]["text"]])
			if entries.is_empty():
				_detail.text = "No visions yet. As the Oracleborn, click a settled tile of another world in his territory to read its past."
		"Omens":
			for id in Story.state["chronicle"]:
				var e := Story.entry(id)
				if e["tab"] == "Omens":
					entries.append([e["title"], e["text"]])
			var n := 1
			for o in Story.state.get("omens", []):
				entries.append(["Omen %d" % n, o])
				n += 1
			if entries.is_empty():
				_detail.text = "Nothing seen yet. The fog keeps its own counsel."
		"Record":
			_text(list, "Lines the Documenter has spoken, as it spoke them.", Hud.DIM)
			for r in Documenter.record():
				var tense: String = {"now": "logged", "then": "recalled", "raw": "transmitted"}.get(r.get("tense", "raw"), "")
				entries.append(["Day %d, %s" % [int(r["day"]), tense], r["text"]])
		"Combos":
			for id in Rules.COMBOS:
				if game.discovered.has(id):
					entries.append([Rules.COMBOS[id]["name"], Rules.COMBOS[id]["text"]])
				else:
					entries.append(["???", "Not yet discovered. Try placing different worlds side by side."])
		"Worlds":
			for w in Story.READINGS:
				var n: int = Story.state["readings"].get(w, 0)
				_text(list, "%s %d/3" % [Worlds.world(w)["name"], n], Hud.DIM)
			for id in Story.state["chronicle"]:
				var e := Story.entry(id)
				if e["tab"] == "Worlds":
					entries.append([e["title"], e["text"]])
		_:
			for id in Story.state["chronicle"]:
				var e := Story.entry(id)
				if e["tab"] == _tab:
					entries.append([e["title"], e["text"]])
	for e in entries:
		var b := _list_button(list, e[0], false)
		b.pressed.connect(func() -> void: _detail.text = "%s\n\n%s" % [e[0], e[1]])
		b.mouse_entered.connect(func() -> void: _detail.text = "%s\n\n%s" % [e[0], e[1]])
	if entries and _detail.text == "":
		_detail.text = "%s\n\n%s" % [entries[-1][0], entries[-1][1]]
	if entries.is_empty() and _detail.text == "":
		_detail.text = "Nothing here yet."


# ------------------------------------------------------------------ hero
func _open_hero() -> void:
	var h := hero()
	var tabs := ["Gear", "Growth", "Behaviors"]
	if not tabs.has(_tab):
		_tab = "Gear"
	var col := _open_frame(h.def()["name"].to_upper(), tabs, _tab)
	var row := _split(col)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(120, 0)
	left.add_theme_constant_override("separation", 0)
	row.add_child(left)
	var pic := TextureRect.new()
	pic.texture = TileFactory.portrait_texture(h.id)
	pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	pic.custom_minimum_size = Vector2(32, 34)
	pic.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_child(pic)
	var s: Dictionary = h.stats()
	var lines := [["Health", str(s["hp"])], ["Armor", str(s["armor"])]]
	match h.id:
		"oracle":
			lines.append_array([["Attack", str(s["atk"])], ["Speed", "%.2f" % s["spd"]], ["Foresight", str(s["fs"])],
				["Dodges", "hits %d+" % maxi(1, 5 - s["dodge"])]])
		"engineer":
			lines.append_array([["Attack", str(s["atk"])], ["Speed", "%.2f" % s["spd"]], ["Level", str(h.level)],
				["XP", "%d / %d" % [h.xp, h.xp_to_next()]]])
		"gunslinger":
			for slot in ["python", "glock", "energy"]:
				if h.guns().has(slot):
					lines.append([h.guns()[slot]["name"], "%d dmg" % h.guns()[slot]["dmg"]])
			lines.append(["Charge", str(h.charge)])
	lines.append_array([["Pack", "%d tiles" % (game.FRAGMENT_LIMIT + s["pack"])], ["Draughts", str(s["supplies"])],
		["Step", "%.2fs" % maxf(0.5, game.STEP_TIME + s["step"])], ["Encounters", "%+d%%" % roundi(s["fog"] * 100)]])
	if h.injured:
		lines.append(["Injured", "rest in town"])
	for line in lines:
		var hb := HBoxContainer.new()
		left.add_child(hb)
		var a := Label.new()
		a.text = line[0]
		a.add_theme_color_override("font_color", Hud.DIM)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(a)
		var v := Label.new()
		v.text = line[1]
		hb.add_child(v)
	match _tab:
		"Gear":
			_hero_gear(row, h)
		"Growth":
			_hero_growth(row, h)
		"Behaviors":
			_hero_behaviors(row, h)


func _hero_gear(row: HBoxContainer, h: HeroState) -> void:
	var slots := VBoxContainer.new()
	slots.custom_minimum_size = Vector2(190, 0)
	slots.add_theme_constant_override("separation", 0)
	row.add_child(slots)
	_text(slots, "Equipped (click to remove)", Hud.DIM)
	for sl in Items.slots_for(h.id):
		var id: String = h.equipped.get(sl[0], "")
		var locked: bool = Items.LOCKED.has(sl[0]) and not h.unlocked.has(sl[0])
		var label: String = "%s: %s" % [sl[1], "locked" if locked else (Items.item(id)["name"] if id != "" else "-")]
		var b := _list_button(slots, label, false)
		b.disabled = locked or id == ""
		var slot_id: String = sl[0]
		if id != "":
			b.mouse_entered.connect(func() -> void: _detail.text = _item_detail(id))
			b.pressed.connect(func() -> void:
				h.unequip(slot_id)
				game.on_gear_changed()
				open("hero"))
		elif locked:
			b.mouse_entered.connect(func() -> void: _detail.text = "%s: %s." % [sl[1], Items.LOCKED[slot_id]])
	var inv := VBoxContainer.new()
	inv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv.add_theme_constant_override("separation", 0)
	row.add_child(inv)
	_text(inv, "Carried (click to equip)", Hud.DIM)
	if h.inventory.is_empty():
		_text(inv, "Nothing spare. Gear drops in the fog and comes from the people you help.", Hud.DIM)
	for id in h.inventory:
		var why: String = h.cannot_equip(id)
		var b := _list_button(inv, Items.item(id)["name"], false)
		if why != "":
			b.add_theme_color_override("font_color", Hud.DIM)
		var item_id: String = id
		b.mouse_entered.connect(func() -> void: _detail.text = _item_detail(item_id) + ("\n" + why if why != "" else ""))
		b.pressed.connect(func() -> void:
			var err: String = h.equip(item_id)
			if err != "":
				_detail.text = err
				return
			game.on_gear_changed()
			open("hero"))
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inv.add_child(gap)
	_detail = _text(inv, "Hover an item to see what it does.", Hud.DIM)
	var over := _list_button(inv, "Start over...", false)
	over.add_theme_color_override("font_color", Hud.DIM)
	over.pressed.connect(func() -> void:
		if over.text == "Start over...":
			over.text = "Click again: erase the save"
			over.add_theme_color_override("font_color", Hud.BLOOD)
		else:
			game.start_over())


func _hero_growth(row: HBoxContainer, h: HeroState) -> void:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	row.add_child(box)
	match h.id:
		"oracle":
			_text(box, "The Oracleborn grows through knowledge. Reading the past of stabilized land grants visions.", Hud.DIM)
			for v in h.visions:
				_text(box, "%s: %s" % [Story.VISIONS[v]["name"], Story.VISIONS[v]["text"]], Hud.TEXT)
			if h.visions.is_empty():
				_text(box, "No visions yet. Click a settled tile of another world in his territory.", Hud.TEXT)
		"engineer":
			_text(box, "Level %d. %d skill point%s. XP comes from fights and the attack on the plaza." % [h.level, h.skill_points, "" if h.skill_points == 1 else "s"], Hud.DIM)
			for branch in HeroState.SKILLS:
				var ranks: Array = HeroState.SKILLS[branch]
				var have: int = h.skills[branch]
				var line := HBoxContainer.new()
				line.add_theme_constant_override("separation", 4)
				box.add_child(line)
				var b := Button.new()
				b.text = "Learn"
				b.focus_mode = Control.FOCUS_NONE
				b.disabled = not h.can_learn(branch)
				line.add_child(b)
				var l := Label.new()
				var next_name: String = ranks[have]["name"] if have < ranks.size() else "complete"
				l.text = "%s %d/%d: next %s" % [branch.capitalize(), have, ranks.size(), next_name]
				line.add_child(l)
				var br: String = branch
				b.pressed.connect(func() -> void:
					h.learn(br)
					game.on_gear_changed()
					open("hero"))
				if have < ranks.size():
					b.mouse_entered.connect(func() -> void: _detail.text = "%s: %s" % [ranks[have]["name"], ranks[have]["text"]])
				for i in range(have):
					_text(box, "  %s: %s" % [ranks[i]["name"], ranks[i]["text"]], Hud.TEXT)
			_text(box, "Book of Laws: %d of %d worlds written. Anchor enough of a world's land and the Documenter writes its law." % [Story.state["laws"].size(), Story.LAWS.size()], Hud.DIM)
			for w in Story.LAWS:
				var known := Story.law_known(w)
				_text(box, "  %s: %s" % [Worlds.world(w)["name"], Story.LAWS[w]["name"] if known else "%d/%d tiles anchored" % [game.map.stable_count("engineer", w), Story.LAWS[w]["tiles"]]], Hud.TEXT if known else Hud.DIM)
		"gunslinger":
			_text(box, "Each gun improves with use (+1 damage per %d shots, up to +%d). Pallas grows as survivors join." % [HeroState.MASTERY_STEP, HeroState.MASTERY_MAX], Hud.DIM)
			for slot in ["python", "glock", "energy"]:
				if h.guns().has(slot):
					_text(box, "%s: mastery %d (%d shots)" % [h.guns()[slot]["name"], h.mastery(slot), int(h.shots.get(slot, 0))], Hud.TEXT)
			var ammo := h.ammo()
			_text(box, "Ammo: %s" % (Items.item(h.equipped["ammo"])["name"] if h.equipped.has("ammo") else "standard rounds"), Hud.TEXT)
			_text(box, "Pallas: %d people, %s. 8 makes an outpost (stores open); 14 makes a town (gun work)." % [int(Story.state["people"]), _settlement_name()], Hud.TEXT)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(gap)
	_detail = _text(box, "", Hud.DIM)


func _hero_behaviors(row: HBoxContainer, h: HeroState) -> void:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	row.add_child(box)
	_text(box, "Behaviors decide what %s does in auto-combat. Click to toggle." % h.short_name(), Hud.DIM)
	for b in HeroState.BEHAVIORS[h.id]:
		var def: Dictionary = HeroState.BEHAVIORS[h.id][b]
		var on: bool = h.behaviors.get(b, def["default"])
		var btn := _list_button(box, ("[x] " if on else "[ ] ") + def["name"], false)
		var key: String = b
		btn.pressed.connect(func() -> void:
			h.behaviors[key] = not h.behaviors.get(key, def["default"])
			open("hero"))
		_text(box, "    " + def["text"], Hud.DIM)
	_detail = _text(box, "", Hud.DIM)


func _item_detail(id: String) -> String:
	var it := Items.item(id)
	return "%s (%s)\n%s\n%s" % [it["name"], Items.slot_name(it["slot"]), Items.stat_text(id), it["text"]]


# ------------------------------------------------------------------ dialog and scenes
func _build_dialog() -> void:
	_dialog = PanelContainer.new()
	_dialog.custom_minimum_size = Vector2(520, 86)
	_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dialog)
	_dialog.anchor_left = 0.5
	_dialog.anchor_right = 0.5
	_dialog.anchor_top = 1.0
	_dialog.anchor_bottom = 1.0
	_dialog.offset_left = -260
	_dialog.offset_right = 260
	_dialog.offset_top = -98
	_dialog.offset_bottom = -12
	_dialog.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_dialog.grow_vertical = Control.GROW_DIRECTION_BEGIN  # extra choices push it up, not off the screen
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	_dialog.add_child(col)
	_dialog_name = Label.new()
	_dialog_name.add_theme_color_override("font_color", Hud.GOLD)
	col.add_child(_dialog_name)
	_dialog_text = Label.new()
	_dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_text.custom_minimum_size = Vector2(500, 44)
	_dialog_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_dialog_text)
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 2)
	_choice_box.visible = false
	col.add_child(_choice_box)
	_hint = Label.new()
	_hint.text = "Click to continue"
	_hint.add_theme_color_override("font_color", Hud.DIM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(_hint)
	_dialog.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			advance())
	_dialog.visible = false


## Shows pages of dialog from one speaker; `done` runs after the last page.
func say(speaker: String, pages: Array, done: Callable) -> void:
	var lines := []
	for p in pages:
		lines.append([speaker, p])
	scene(lines, done)


## A multi-speaker scene: lines are [speaker, text]. An empty speaker is narration.
func scene(lines: Array, done: Callable) -> void:
	_dialog_pages = lines.duplicate()
	_dialog_done = done
	_dim.visible = true
	_dialog.visible = true
	move_child(_dialog, get_child_count() - 1)
	advance()


## A scene that ends in a choice. `options` are {label, text, effects}; `cb` gets the index.
func choice(speaker: String, text: String, options: Array, cb: Callable) -> void:
	_dialog_pages = []
	_dialog_done = Callable()
	_dim.visible = true
	_dialog.visible = true
	move_child(_dialog, get_child_count() - 1)
	_dialog_name.text = speaker
	_dialog_name.visible = speaker != ""
	_dialog_text.text = Story.voice(text)
	_dialog_text.add_theme_color_override("font_color", Hud.TEXT)
	_seat_dialog()
	_choice_open = true
	_choice_cb = cb
	_hint.visible = false
	for c in _choice_box.get_children():
		c.queue_free()
	_choice_box.visible = true
	for i in range(options.size()):
		var b := _list_button(_choice_box, "> " + Story.voice(options[i]["label"]), false)
		b.clip_text = false
		var idx := i
		b.pressed.connect(func() -> void: resolve_choice(idx))


## Back to its resting size at the bottom of the screen; longer content then grows it upward.
func _seat_dialog() -> void:
	_dialog.offset_top = -98
	_dialog.offset_bottom = -12
	_dialog.offset_left = -260
	_dialog.offset_right = 260


func resolve_choice(index: int) -> void:
	if not _choice_open:
		return
	_choice_open = false
	_choice_box.visible = false
	_hint.visible = true
	_dialog.visible = false
	_dim.visible = current != ""
	var cb := _choice_cb
	_choice_cb = Callable()
	if cb.is_valid():
		cb.call(index)


func advance() -> void:
	if _choice_open:
		return
	if _dialog_pages.is_empty():
		_dialog.visible = false
		_dim.visible = current != ""
		if _dialog_done.is_valid():
			var cb := _dialog_done
			_dialog_done = Callable()
			cb.call()
		return
	var page: Array = _dialog_pages.pop_front()
	_seat_dialog()
	var is_doc: bool = page[0] == "The Documenter"
	_dialog_name.text = "DOC // The Documenter" if is_doc else page[0]
	_dialog_name.visible = page[0] != ""
	_dialog_name.add_theme_color_override("font_color", Hud.DOC_INK if is_doc else Hud.GOLD)
	_dialog_text.text = Story.voice(page[1])
	_dialog_text.add_theme_color_override("font_color", Hud.DIM if page[0] == "" else (Hud.DOC_INK if is_doc else Hud.TEXT))


# ------------------------------------------------------------------ helpers
func _list_button(parent: Control, text: String, active: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = false
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	var normal := StyleBoxFlat.new()
	normal.bg_color = Hud.PANEL_BEVEL if active else Color(0, 0, 0, 0)
	normal.set_content_margin_all(1)
	normal.content_margin_left = 2
	normal.content_margin_right = 2
	var hover := normal.duplicate()
	hover.bg_color = Hud.PANEL_LIGHT
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", normal)
	b.add_theme_color_override("font_color", Hud.GOLD if active else Hud.TEXT)
	b.add_theme_color_override("font_disabled_color", Hud.DIM)
	parent.add_child(b)
	return b


func _text(parent: Control, text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(120, 0)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l
