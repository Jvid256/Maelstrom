class_name Hud
extends CanvasLayer
## Streamlined interface: a thin top bar, a side panel (territory or hero),
## a card tray during expeditions, a tooltip at the cursor and a short banner.

signal card_pressed(index: int)
signal wait_pressed
signal retreat_pressed
signal pause_pressed
signal map_pressed
signal bandage_pressed
signal screen_pressed(view: String)
signal hero_pressed(hero_id: String)

## Interface colors from style anchor v0.2: slate-violet metal, ashen paper, functional color only.
const TEXT := Color("#dcd6e8")
const DIM := Color("#9a90b2")
const GOLD := Color("#f0b050")  # amber: progress and selection
const PANEL_EDGE := Color("#0c0912")
const PANEL_BG := Color("#191322")
const PANEL_BEVEL := Color("#2a2138")
const PANEL_LIGHT := Color("#3e3254")
const IRON := Color("#6e6488")
const PAPER := Color("#bcb6c6")
const PAPER_D := Color("#9e98a8")
const PAPER_EDGE := Color("#726c80")
const INK := Color("#1a1420")
const BLOOD := Color("#9a2e3e")
const LINE := PANEL_LIGHT

var battle: Battle
var tactics: Tactics
var screens: Screens
var _town_button: Button
var _chronicle_button: Button
var _hero_row: HBoxContainer
var _portrait: TextureRect
var _hero_name: Label

var _res_labels := {}
var _day: Label
var _progress_back: ColorRect
var _progress_fill: ColorRect
var _combos: Label
var _drift: Label

var _side: PanelContainer
var _territory_box: VBoxContainer
var _yield_grid: GridContainer
var _expedition_box: VBoxContainer
var _hp_fill: ColorRect
var _hp_label: Label
var _foresight_row: HBoxContainer
var _loot_grid: GridContainer
var _fragment_label: Label
var _pause_button: Button

var _tray: PanelContainer
var _cards: HBoxContainer
var _card_buttons: Array[Button] = []

var _tip: PanelContainer
var _tip_label: Label
var _banner: PanelContainer
var _banner_label: Label
var _banner_tween: Tween


func _ready() -> void:
	layer = 2  # above the lighting pass, below the screen finish
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _make_theme()
	add_child(root)
	_build_top_bar(root)
	_build_side(root)
	_build_tray(root)

	_banner = _panel(root, true)
	_pin(_banner, 0.5, 0.0, 0, 24)
	_banner_label = _label(_banner, GOLD)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_label.custom_minimum_size = Vector2(340, 0)
	_banner.visible = false

	battle = Battle.new()
	root.add_child(battle)
	tactics = Tactics.new()
	root.add_child(tactics)
	screens = Screens.new()
	root.add_child(screens)

	_build_documenter(root)

	_tip = _panel(root, true)
	_tip_label = _label(_tip, TEXT)
	_tip_label.add_theme_constant_override("line_spacing", -1)
	_tip.visible = false


## The Documenter's panel: another system's interface laid over ours. Bottom-left, teal on
## near-black, a blinking cursor pip, text typed out and left to fade.
const DOC_INK := Color("#8fd4c6")
const DOC_DIM := Color("#4e7a76")
const DOC_BG := Color("#070b0c")
var _doc: PanelContainer
var _doc_label: Label
var _doc_pip: ColorRect
var _doc_tween: Tween
var _doc_time := 0.0


func _build_documenter(root: Control) -> void:
	_doc = PanelContainer.new()
	_doc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := _box(DOC_BG, DOC_DIM, 1, 3)
	style.border_width_left = 2
	style.border_color = DOC_DIM
	_doc.add_theme_stylebox_override("panel", style)
	root.add_child(_doc)
	root.move_child(_doc, 0)  # under every other panel: screens and dialogs draw over it
	_pin(_doc, 0.0, 1.0, 4, -4)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	_doc.add_child(row)
	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 0)
	row.add_child(head)
	var tag := _label(head, DOC_DIM)
	tag.text = "DOC"
	_doc_pip = ColorRect.new()
	_doc_pip.color = DOC_INK
	_doc_pip.custom_minimum_size = Vector2(3, 5)
	var holder := CenterContainer.new()
	holder.add_child(_doc_pip)
	head.add_child(holder)
	_doc_label = _label(row, DOC_INK)
	_doc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_doc_label.custom_minimum_size = Vector2(170, 0)
	_doc_label.add_theme_constant_override("line_spacing", -1)
	_doc.visible = false


## Shows a Documenter line, typed out, then fades. Called by main through Documenter.bind.
func documenter_line(text: String) -> void:
	_doc_label.text = text
	_doc_label.visible_characters = 0
	_doc.visible = true
	_doc.modulate.a = 1.0
	_doc.reset_size()
	_doc.call_deferred("reset_size")
	if _doc_tween:
		_doc_tween.kill()
	_doc_tween = create_tween()
	_doc_tween.tween_property(_doc_label, "visible_characters", text.length(), minf(2.2, 0.03 * text.length()))
	_doc_tween.tween_interval(4.5 + 0.04 * text.length())
	_doc_tween.tween_property(_doc, "modulate:a", 0.0, 1.2)
	_doc_tween.tween_callback(func() -> void: _doc.visible = false)


func _process(delta: float) -> void:
	if _doc.visible:
		_doc_time += delta
		_doc_pip.visible = fmod(_doc_time, 0.9) < 0.55
		if tactics.visible:
			_doc.visible = false
	if (battle.visible or tactics.visible or screens.is_open()) and _tip.visible:
		_tip.visible = false
	if _tip.visible:
		var m := _tip.get_viewport().get_mouse_position()
		var s := _tip.size
		var p := m + Vector2(8, 8)
		if p.x + s.x > 640 - 2:
			p.x = m.x - s.x - 6
		if p.y + s.y > 360 - 2:
			p.y = m.y - s.y - 6
		_tip.position = p


# ------------------------------------------------------------------ building
func _build_top_bar(root: Control) -> void:
	var bar := _panel(root, false)
	bar.anchor_right = 1.0
	bar.offset_bottom = 13
	var bar_style := _box(PANEL_BG, PANEL_EDGE, 0, 3)
	bar_style.border_width_bottom = 1
	bar_style.content_margin_top = 2
	bar_style.content_margin_bottom = 2
	bar.add_theme_stylebox_override("panel", bar_style)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	bar.add_child(box)
	for r in Worlds.RESOURCES:
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 1)
		box.add_child(cell)
		var icon := TextureRect.new()
		icon.texture = TileFactory.resource_icon(r)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		cell.add_child(icon)
		var l := _label(cell, TEXT)
		l.text = "0"
		_res_labels[r] = l
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	_day = _label(box, GOLD)
	var holder := CenterContainer.new()
	box.add_child(holder)
	_progress_back = ColorRect.new()
	_progress_back.color = PANEL_EDGE
	_progress_back.custom_minimum_size = Vector2(70, 4)
	holder.add_child(_progress_back)
	_progress_fill = ColorRect.new()
	_progress_fill.color = GOLD
	_progress_fill.size = Vector2(0, 3)
	_progress_back.add_child(_progress_fill)
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(spacer2)
	_drift = _label(box, DIM)
	_combos = _label(box, TEXT)


func _build_side(root: Control) -> void:
	_side = _panel(root, false)
	_pin(_side, 1.0, 0.0, -4, 22)
	_side.custom_minimum_size = Vector2(150, 0)
	var stack := VBoxContainer.new()
	_side.add_child(stack)
	_hero_row = HBoxContainer.new()
	_hero_row.add_theme_constant_override("separation", 2)
	stack.add_child(_hero_row)

	_territory_box = VBoxContainer.new()
	_territory_box.add_theme_constant_override("separation", 3)
	stack.add_child(_territory_box)
	_label(_territory_box, GOLD).text = "TERRITORY"
	_label(_territory_box, DIM).text = "Each day"
	_yield_grid = GridContainer.new()
	_yield_grid.columns = 2
	_yield_grid.add_theme_constant_override("h_separation", 8)
	_territory_box.add_child(_yield_grid)
	var hint := _label(_territory_box, DIM)
	hint.text = "Orange markers are glimpses of land in the fog: pick one to set out. When someone in town asks for something, a cyan marker shows where. WASD pans, F recenters."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(140, 0)
	var nav := GridContainer.new()
	nav.columns = 2
	nav.add_theme_constant_override("h_separation", 3)
	nav.add_theme_constant_override("v_separation", 3)
	_territory_box.add_child(nav)
	_town_button = _nav_button(nav, "Town", "town")
	_chronicle_button = _nav_button(nav, "Chronicle", "chronicle")
	_nav_button(nav, "Hero", "hero")
	var wait := Button.new()
	wait.text = "Wait a day"
	wait.focus_mode = Control.FOCUS_NONE
	wait.pressed.connect(func() -> void: wait_pressed.emit())
	_territory_box.add_child(wait)

	_expedition_box = VBoxContainer.new()
	_expedition_box.add_theme_constant_override("separation", 3)
	stack.add_child(_expedition_box)
	var portrait_row := HBoxContainer.new()
	portrait_row.add_theme_constant_override("separation", 4)
	_expedition_box.add_child(portrait_row)
	_portrait = TextureRect.new()
	_portrait.texture = TileFactory.portrait_texture()
	_portrait.custom_minimum_size = Vector2(32, 32)
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _box(PANEL_EDGE, IRON, 1, 1))
	frame.add_child(_portrait)
	portrait_row.add_child(frame)
	var name_col := VBoxContainer.new()
	name_col.add_theme_constant_override("separation", 1)
	portrait_row.add_child(name_col)
	_hero_name = _label(name_col, TEXT)
	_hero_name.text = "ORACLEBORN"
	var hp_back := ColorRect.new()
	hp_back.color = PANEL_EDGE
	hp_back.custom_minimum_size = Vector2(80, 4)
	name_col.add_child(hp_back)
	_hp_fill = ColorRect.new()
	_hp_fill.color = BLOOD
	_hp_fill.size = Vector2(56, 3)
	hp_back.add_child(_hp_fill)
	_hp_label = _label(name_col, DIM)
	_foresight_row = HBoxContainer.new()
	_foresight_row.add_theme_constant_override("separation", 2)
	_expedition_box.add_child(_foresight_row)
	_label(_expedition_box, DIM).text = "Loot"
	_loot_grid = GridContainer.new()
	_loot_grid.columns = 2
	_loot_grid.add_theme_constant_override("h_separation", 8)
	_expedition_box.add_child(_loot_grid)
	_fragment_label = _label(_expedition_box, DIM)
	_fragment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fragment_label.custom_minimum_size = Vector2(140, 0)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 3)
	_expedition_box.add_child(buttons)
	_pause_button = Button.new()
	_pause_button.text = "Pause"
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	buttons.add_child(_pause_button)
	_map_button = Button.new()
	_map_button.text = "Map"
	_map_button.focus_mode = Control.FOCUS_NONE
	_map_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_button.pressed.connect(func() -> void: map_pressed.emit())
	buttons.add_child(_map_button)
	_bandage_button = Button.new()
	_bandage_button.text = "Bandage"
	_bandage_button.tooltip_text = "B: a supply for +6 health"
	_bandage_button.focus_mode = Control.FOCUS_NONE
	_bandage_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bandage_button.pressed.connect(func() -> void: bandage_pressed.emit())
	buttons.add_child(_bandage_button)
	var retreat := Button.new()
	retreat.text = "Retreat"
	retreat.focus_mode = Control.FOCUS_NONE
	retreat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retreat.pressed.connect(func() -> void: retreat_pressed.emit())
	buttons.add_child(retreat)


func _build_tray(root: Control) -> void:
	_tray = _panel(root, false)
	_pin(_tray, 0.5, 1.0, 0, -4)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 2)
	_tray.add_child(_cards)
	for i in range(6):
		var b := Button.new()
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(36, 34)
		b.expand_icon = false
		b.add_theme_stylebox_override("normal", _paper(false, false))
		b.add_theme_stylebox_override("hover", _paper(true, false))
		b.add_theme_stylebox_override("pressed", _paper(false, true))
		b.add_theme_stylebox_override("hover_pressed", _paper(true, true))
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.pressed.connect(func() -> void: card_pressed.emit(i))
		b.mouse_entered.connect(func() -> void: _card_hover(i, true))
		b.mouse_exited.connect(func() -> void: _card_hover(i, false))
		_cards.add_child(b)
		_card_buttons.append(b)
	_tray.visible = false


func _nav_button(parent: Control, text: String, view: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(func() -> void: screen_pressed.emit(view))
	parent.add_child(b)
	return b


## Marks the Town and Chronicle buttons when there's something new.
func set_news(town: bool, chronicle: int) -> void:
	_town_button.text = "Town !" if town else "Town"
	_town_button.add_theme_color_override("font_color", GOLD if town else TEXT)
	_chronicle_button.text = "Chronicle +%d" % chronicle if chronicle > 0 else "Chronicle"
	_chronicle_button.add_theme_color_override("font_color", GOLD if chronicle > 0 else TEXT)


# ------------------------------------------------------------------ updates
var _hand_cache: Array = []


func set_mode(mode: String) -> void:
	var on_trip := not mode in ["territory", "build"]
	_territory_box.visible = not on_trip
	_expedition_box.visible = on_trip
	_tray.visible = on_trip
	_progress_back.visible = on_trip


func set_resources(stock: Dictionary) -> void:
	for r in Worlds.RESOURCES:
		_res_labels[r].text = str(stock[r])


func set_day(day: int, shift_in: int, progress: float) -> void:
	_day.text = "DAY %d" % day
	_progress_fill.size.x = 50.0 * clampf(progress, 0.0, 1.0)
	_drift.text = "Drift shifts in %dd" % shift_in


func set_combos(found: Array) -> void:
	_combos.text = "Combos %d/%d" % [found.size(), Rules.COMBOS.size()]


func set_territory_yield(per_day: Dictionary) -> void:
	_fill_amounts(_yield_grid, per_day, "+")


## The hero switch row: one button per unlocked hero, the active one in amber.
func set_heroes(ids: Array, active: String) -> void:
	for c in _hero_row.get_children():
		c.queue_free()
	if ids.size() < 2:
		return
	for id in ids:
		var b := Button.new()
		b.text = HeroState.HEROES[id]["short"]
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_color_override("font_color", GOLD if id == active else DIM)
		var hid: String = id
		b.pressed.connect(func() -> void: hero_pressed.emit(hid))
		_hero_row.add_child(b)


func set_hero(hero_id: String, hp: int, max_hp: int, foresight: int, max_foresight: int) -> void:
	_portrait.texture = TileFactory.portrait_texture(hero_id)
	_hero_name.text = HeroState.HEROES[hero_id]["short"].to_upper()
	_hp_fill.size.x = 56.0 * clampf(float(hp) / max_hp, 0.0, 1.0)
	_hp_label.text = "%d / %d" % [hp, max_hp]
	for c in _foresight_row.get_children():
		c.queue_free()
	if max_foresight <= 0:
		return
	var l := Label.new()
	l.text = "Foresight"
	l.add_theme_color_override("font_color", DIM)
	_foresight_row.add_child(l)
	for i in range(max_foresight):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(4, 4)
		pip.color = Color("#9fe0e6") if i < foresight else PANEL_EDGE
		var holder := CenterContainer.new()
		holder.add_child(pip)
		_foresight_row.add_child(holder)


func set_loot(loot: Dictionary, fragment_tiles: int, limit: int = 3) -> void:
	_fill_amounts(_loot_grid, loot, "")
	_fragment_label.text = ("Place tiles beside the route. Land shaped next to the glimpse comes home with it (%d/%d)." if _way_phase != "walk" else "Land beside the glimpse comes home with it (%d/%d). M or a card opens the map.") % [fragment_tiles, limit]


var _map_button: Button
var _bandage_button: Button
var _way_phase := "walk"


func set_paused(paused: bool) -> void:
	if _way_phase == "walk":
		_pause_button.text = "Resume" if paused else "Pause"


## The expedition's phase: plan (on the world map, before leaving), walk (on the Way), map (looking back at the world map mid-trip).
func set_way_phase(phase: String) -> void:
	_way_phase = phase
	match phase:
		"plan":
			_pause_button.text = "Set out"
			_map_button.visible = false
			_bandage_button.visible = false
		"map":
			_pause_button.text = "To the road"
			_map_button.visible = false
			_bandage_button.visible = false
		_:
			_pause_button.text = "Pause"
			_map_button.visible = true
			_bandage_button.visible = true


func set_hand(hand: Array, selected: int) -> void:
	_hand_cache = hand
	for i in range(_card_buttons.size()):
		var b := _card_buttons[i]
		b.visible = i < hand.size()
		if i < hand.size():
			var card: Dictionary = hand[i]
			var atlas := AtlasTexture.new()
			atlas.atlas = TileFactory.icon(card["world"], card["layout"])
			atlas.region = Rect2(4, 20, 32, 30)
			b.icon = atlas
			b.set_pressed_no_signal(i == selected)


func _card_hover(i: int, on: bool) -> void:
	if on and i < _hand_cache.size():
		var card: Dictionary = _hand_cache[i]
		var w: Dictionary = Worlds.world(card["world"])
		show_tip("%s\n%s\n%s" % [Worlds.LAYOUT_NAMES[card["layout"]], w["name"], ", ".join(w["tags"])])
	else:
		show_tip("")


func show_tip(text: String) -> void:
	_tip.visible = text != ""
	_tip_label.text = text
	_tip.reset_size()


func banner(text: String, seconds: float = 2.5) -> void:
	_banner_label.text = text
	_banner.visible = true
	_banner.modulate.a = 1.0
	_banner.reset_size()
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_interval(seconds)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.5)
	_banner_tween.tween_callback(func() -> void: _banner.visible = false)


func _fill_amounts(grid: GridContainer, amounts: Dictionary, prefix: String) -> void:
	for c in grid.get_children():
		c.queue_free()
	var any := false
	for r in Worlds.RESOURCES:
		var v: int = amounts.get(r, 0)
		if v == 0:
			continue
		any = true
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		var icon := TextureRect.new()
		icon.texture = TileFactory.resource_icon(r)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		cell.add_child(icon)
		var l := Label.new()
		l.text = ("%s%d" % [prefix, v]) if v > 0 else str(v)
		cell.add_child(l)
		grid.add_child(cell)
	if not any:
		var l := Label.new()
		l.text = "-"
		l.add_theme_color_override("font_color", DIM)
		grid.add_child(l)


# ------------------------------------------------------------------ building blocks
func _pin(c: Control, ax: float, ay: float, ox: float, oy: float) -> void:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = ox
	c.offset_right = ox
	c.offset_top = oy
	c.offset_bottom = oy
	var grow := [Control.GROW_DIRECTION_END, Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BEGIN]
	c.grow_horizontal = grow[int(ax * 2)]
	c.grow_vertical = grow[int(ay * 2)]


func _panel(parent: Control, floating: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if floating:
		p.add_theme_stylebox_override("panel", _box(Color(PANEL_BG, 0.96), IRON, 1, 3))
	parent.add_child(p)
	return p


func _label(parent: Control, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _box(bg: Color, border: Color, width: int, margin: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_content_margin_all(margin)
	s.anti_aliasing = false
	return s


func _make_theme() -> Theme:
	var t := Theme.new()
	var font := load("res://fonts/PixelifySans.ttf") as FontFile
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	t.default_font = font
	t.default_font_size = 11
	t.set_constant("line_spacing", "Label", -1)
	t.set_stylebox("panel", "PanelContainer", _metal_panel())
	t.set_stylebox("normal", "Button", _box(PANEL_BEVEL, PANEL_EDGE, 1, 2))
	t.set_stylebox("hover", "Button", _box(PANEL_LIGHT, IRON, 1, 2))
	t.set_stylebox("pressed", "Button", _box(PANEL_LIGHT, GOLD, 1, 2))
	t.set_stylebox("hover_pressed", "Button", _box(PANEL_LIGHT, GOLD, 1, 2))
	t.set_stylebox("disabled", "Button", _box(PANEL_EDGE, PANEL_BEVEL, 1, 2))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", TEXT)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_hover_pressed_color", "Button", GOLD)
	t.set_color("font_color", "Label", TEXT)
	return t


## Slate-violet metal plate: near-black edge, a bevel, a top highlight line and iron studs in the corners.
func _metal_panel() -> StyleBoxTexture:
	var img := Image.create_empty(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(PANEL_BG)
	for i in range(12):
		for e in [Vector2i(i, 0), Vector2i(i, 11), Vector2i(0, i), Vector2i(11, i)]:
			img.set_pixelv(e, PANEL_EDGE)
	for i in range(1, 11):
		for e in [Vector2i(i, 1), Vector2i(i, 10), Vector2i(1, i), Vector2i(10, i)]:
			img.set_pixelv(e, PANEL_BEVEL)
	for i in range(2, 10):
		img.set_pixel(i, 2, PANEL_LIGHT)
	for corner in [Vector2i(2, 3), Vector2i(8, 3), Vector2i(2, 8), Vector2i(8, 8)]:
		img.set_pixelv(corner, IRON)
		img.set_pixelv(corner + Vector2i(1, 0), IRON)
		img.set_pixelv(corner + Vector2i(0, 1), PANEL_BEVEL)
		img.set_pixelv(corner + Vector2i(1, 1), PANEL_EDGE)
	var s := StyleBoxTexture.new()
	s.texture = ImageTexture.create_from_image(img)
	s.set_texture_margin_all(5)
	s.content_margin_left = 5
	s.content_margin_right = 5
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s


## Ashen paper tile card; the selected card gets an amber frame.
func _paper(hover: bool, selected: bool) -> StyleBoxFlat:
	var s := _box(PAPER if hover else PAPER_D, GOLD if selected else (INK if hover else PAPER_EDGE), 2 if selected else 1, 2)
	return s
