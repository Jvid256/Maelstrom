class_name MaelstromMap
extends Node2D
## The hex map: cell data, tile visuals, glimpses, heroes and mouse picking.
## Game rules live in main.gd; this node stores and draws.
##
## Cell states:
##   stable    settled territory (owner = the hero whose method holds it)
##   settling  a fused fragment that can still be released
##   shaped    land placed beside the route during an expedition (temporary)
##   unstable  fogged wasteland
## Three regions share one map; each hero's land is the connected component around
## their home. Regions connect when land grows until it touches.

signal cell_hovered(pos: Vector2i, inside: bool)
signal cell_clicked(pos: Vector2i, button: int)

## A wide world: the three homes sit in its middle third, with deep fog on every side for
## later acts. 64 x 38 cells; structures need room, so the town starts two rings wide.
const HOMES := {"oracle": Vector2i(21, 15), "engineer": Vector2i(38, 11), "gunslinger": Vector2i(30, 25)}
const ORIGIN := Vector2(24, 12)
const COLS := Vector2i(0, 64)
const ROWS := Vector2i(0, 38)
const NONE := Vector2i(-9999, -9999)
const SEAM_COLORS := {"oracle": Color("#9fd6dc"), "engineer": Color("#f0b050"), "gunslinger": Color("#8f5a3a")}

const GLIMPSE_TEXT := {
	"felled": "something tall and broken, lying across the land", "dunes_tower": "a steel tower, half buried",
	"dunes": "wind-carved dunes", "rocks_sand": "a rocky stretch of desert", "bunker": "a concrete bunker in the sand",
	"saloon": "wooden buildings with a hanging sign",
	"bones": "a field of great ribs", "deadwood": "a forest of bone-white trees", "rocks_ash": "ash and broken stone",
	"graves": "a cluster of tilted stones", "crypt": "a low stone building with a sealed door",
	"ice": "a sheet of old ice", "ice_house": "a roof under the ice", "spikes": "jagged spires of ice", "beacon": "a dead beacon with a dull red core",
	"plaza": "cracked plaza tiles with faint lines of light", "questboard": "a board of flickering notices",
	"drone_field": "the wrecks of small machines", "server": "a rack of machines, one light blinking",
	"thorns": "a mat of black thorns", "cauldron": "a great iron vessel on its side", "hexstone": "a standing stone with a violet mark",
	"trench": "a trench lined with thorns",
	"bare": "an empty stretch of ground",
}

var tile_shader: Shader = preload("res://shaders/tile.gdshader")
var cells := {}
var glimpses := {"oracle": [], "engineer": [], "gunslinger": []}
var glimpse_count := {"oracle": 3, "engineer": 3, "gunslinger": 3}
var open_regions: Array = ["oracle"]
var revealed := {}
var active_hero := "oracle"
var _nodes := {}
var _fog := {}
var _markers := {}
var _hover_sprite: Sprite2D
var _hovered := NONE
var hero: Sprite2D
var _route_line: Line2D
var _seams: Node2D
var _land_cache := {}


func _ready() -> void:
	y_sort_enabled = true
	_hover_sprite = Sprite2D.new()
	_hover_sprite.texture = TileFactory.highlight_texture
	_hover_sprite.centered = false
	_hover_sprite.offset = TileFactory.tile_offset()
	_hover_sprite.z_index = 20
	_hover_sprite.visible = false
	add_child(_hover_sprite)

	_route_line = Line2D.new()
	_route_line.width = 1.0
	_route_line.default_color = Color("#f0b050")
	_route_line.texture = _dot_texture()
	_route_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	_route_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_route_line.z_index = 15
	add_child(_route_line)

	_seams = Node2D.new()
	_seams.z_index = 6
	_seams.draw.connect(_draw_seams)
	add_child(_seams)

	hero = Sprite2D.new()
	hero.texture = TileFactory.hero_texture("oracle")
	hero.offset = Vector2(0, -11)
	hero.z_index = 18
	hero.visible = false
	add_child(hero)


func _dot_texture() -> ImageTexture:
	var img := Image.create_empty(3, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.set_pixel(0, 0, Color.WHITE)
	return ImageTexture.create_from_image(img)


func center_of(pos: Vector2i) -> Vector2:
	return Hex.to_pixel(pos) + ORIGIN


## Pixel size of the whole map, for the camera and the sky.
func pixel_size() -> Vector2:
	return Vector2(COLS.y * Hex.COL_STEP + 48, ROWS.y * Hex.ROW_STEP + 48)


# ------------------------------------------------------------------ generation
func generate(seed_value: int = 1) -> void:
	cells.clear()
	open_regions = ["oracle"]
	for col in range(COLS.x, COLS.y):
		for row in range(ROWS.x, ROWS.y):
			var pos := Vector2i(col, row)
			var d := _nearest_home_distance(pos, true)
			var n := TileFactory.noise(col, row, 11 + seed_value)
			var void_chance := 0.5 if d >= 7 else (0.25 if d >= 5 else 0.0)
			if _in_corridor(pos):
				void_chance *= 0.4  # the ways between the homes are broken, not gone
			if n < void_chance or (d >= 3 and n > 0.84 and not _in_corridor(pos)):
				continue  # gaps of void between the loose pieces
			var w := _world_for(pos)
			cells[pos] = _cell(w, _random_layout(w, pos, seed_value), "unstable", pos)
	open_region("oracle")
	pick_glimpses("oracle", seed_value)
	rebuild_all()


## Stabilizes a hero's starting ground. The Oracleborn's town, the Engineer's camp, or Pallas.
func open_region(hero_id: String) -> void:
	if not open_regions.has(hero_id):
		open_regions.append(hero_id)
	var home: Vector2i = HOMES[hero_id]
	var ring := Hex.neighbors(home)
	match hero_id:
		"oracle":
			cells[home] = _cell("kingdom", "pillar", "stable", home)
			var layouts := ["town", "grove", "town", "ruin", "grove", "grove"]
			for i in range(6):
				cells[ring[i]] = _cell("kingdom", layouts[i], "stable", ring[i])
			# the town's fields: a second ring of settled ground, room to build on
			var outer: Array[Vector2i] = []
			for r in ring:
				for n in Hex.neighbors(r):
					if n != home and not ring.has(n) and not outer.has(n) and _in_bounds(n):
						outer.append(n)
			var outer_layouts := ["grove", "bare", "ruin", "grove", "town", "bare", "grove", "ruin", "bare", "grove", "bare", "grove"]
			for i in range(outer.size()):
				cells[outer[i]] = _cell("kingdom", outer_layouts[i % outer_layouts.size()], "stable", outer[i])
			ring = ring + outer
		"engineer":
			cells[home] = _cell("leader", "mast", "stable", home)
			var layouts := ["camp", "grave", "plaza", "cache"]
			for i in range(4):
				cells[ring[i]] = _cell("leader", layouts[i], "stable", ring[i])
			for i in range(4, 6):
				if not cells.has(ring[i]):
					cells[ring[i]] = _cell("coven", "thorns", "unstable", ring[i])
		"gunslinger":
			cells[home] = _cell("eroded", "pallas_core", "stable", home)
			var layouts := ["pallas_hab", "pallas_dock", "dunes", "rocks_sand"]
			for i in range(4):
				cells[ring[i]] = _cell("eroded", layouts[i], "stable", ring[i])
			for i in range(4, 6):
				if not cells.has(ring[i]):
					cells[ring[i]] = _cell("eroded", "dunes", "unstable", ring[i])
	for pos in [home] + ring:
		if cells.has(pos) and cells[pos]["state"] == "stable":
			cells[pos]["owner"] = hero_id
			cells[pos].erase("lead")
	# the ground around a new region is settled fog, never void
	for pos in ring:
		for n in Hex.neighbors(pos):
			if not cells.has(n) and _in_bounds(n):
				var w := _world_for(n)
				cells[n] = _cell(w, _random_layout(w, n, 7), "unstable", n)
	_land_cache.clear()
	pick_glimpses(hero_id, 3)
	rebuild_all()


## Within a hex or two of the straight way between two homes. Land is likelier to exist
## there, so each region can grow toward another without a sea of void in between.
func _in_corridor(pos: Vector2i) -> bool:
	var ids := HOMES.keys()
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			var a: Vector2i = HOMES[ids[i]]
			var b: Vector2i = HOMES[ids[j]]
			if Hex.distance(pos, a) + Hex.distance(pos, b) <= Hex.distance(a, b) + 3:
				return true
	return false


func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= COLS.x and pos.x < COLS.y and pos.y >= ROWS.x and pos.y < ROWS.y


func _cell(world_id: String, layout: String, state: String, pos: Vector2i) -> Dictionary:
	return {"world": world_id, "layout": layout, "state": state, "settle": 0, "seed": absi(pos.x * 31 + pos.y * 7)}


func _nearest_home(pos: Vector2i, all: bool = false) -> String:
	var best := "oracle"
	var bd := 9999
	for h in HOMES:
		if not all and not open_regions.has(h):
			continue
		var d := Hex.distance(pos, HOMES[h])
		if d < bd:
			bd = d
			best = h
	return best


func _nearest_home_distance(pos: Vector2i, all: bool = false) -> int:
	return Hex.distance(pos, HOMES[_nearest_home(pos, all)])


## Which world's land a fogged cell belongs to: each region has its own neighborhood.
func _world_for(pos: Vector2i) -> String:
	var home := _nearest_home(pos, true)
	var off := center_of(pos) - center_of(HOMES[home])
	var ang := rad_to_deg(atan2(off.y, off.x))
	var n := TileFactory.noise(pos.x, pos.y, 5)
	var zones: Array
	match home:
		"engineer":
			zones = ["leader", "coven", "eroded", "leader"]
		"gunslinger":
			zones = ["eroded", "frozen", "eroded", "leader"]
		_:
			zones = ["eroded", "frozen", "hollow", "eroded"]
	if n > 0.85:
		return zones[int(n * 100) % 4]
	if ang >= -45.0 and ang <= 45.0:
		return zones[0]
	if ang > -135.0 and ang < -45.0:
		return zones[1]
	if ang > 45.0 and ang < 135.0:
		return zones[2]
	return zones[3]


func _random_layout(world_id: String, pos: Vector2i, salt: int) -> String:
	var options: Array = Worlds.world(world_id)["layouts"]
	return options[int(TileFactory.noise(pos.x, pos.y, 3 + salt * 13) * options.size()) % options.size()]


# ------------------------------------------------------------------ land and regions
## All stable or settling land connected to a hero's home.
func land_of(hero_id: String) -> Dictionary:
	if _land_cache.has(hero_id):
		return _land_cache[hero_id]
	var out := {}
	var home: Vector2i = HOMES[hero_id]
	if cells.has(home) and cells[home]["state"] in ["stable", "settling"]:
		var frontier: Array[Vector2i] = [home]
		out[home] = true
		while not frontier.is_empty():
			var next: Array[Vector2i] = []
			for pos in frontier:
				for n in Hex.neighbors(pos):
					if cells.has(n) and not out.has(n) and cells[n]["state"] in ["stable", "settling"]:
						out[n] = true
						next.append(n)
			frontier = next
	_land_cache[hero_id] = out
	return out


func connected(a: String, b: String) -> bool:
	if b == "any":
		for h in open_regions:
			if h != a and connected(a, h):
				return true
		return false
	return open_regions.has(a) and open_regions.has(b) and land_of(a).has(HOMES[b])


func touches_land_of(pos: Vector2i, hero_id: String) -> bool:
	var land := land_of(hero_id)
	for n in Hex.neighbors(pos):
		if land.has(n):
			return true
	return false


func touches_land(pos: Vector2i) -> bool:
	for n in Hex.neighbors(pos):
		if cells.has(n) and cells[n]["state"] in ["stable", "settling"]:
			return true
	return false


## Center of a hero's land, for the camera.
func region_center(hero_id: String) -> Vector2:
	var land := land_of(hero_id)
	if land.is_empty():
		return center_of(HOMES[hero_id])
	var sum := Vector2.ZERO
	for pos in land:
		sum += center_of(pos)
	return sum / land.size()


## Stable tiles of a world in a hero's land.
func stable_count(hero_id: String, world_id: String) -> int:
	var n := 0
	for pos in land_of(hero_id):
		if cells[pos]["state"] == "stable" and cells[pos]["world"] == world_id:
			n += 1
	return n


# ------------------------------------------------------------------ glimpses and leads
## Fragments glimpsed through the fog near a hero's land, 3-5 hexes out.
func pick_glimpses(hero_id: String, salt: int) -> void:
	glimpses[hero_id] = []
	var land_dist := _distance_from(land_of(hero_id))
	var candidates := []
	for pos in cells:
		var d: int = land_dist.get(pos, 99)
		if cells[pos]["state"] == "unstable" and d >= 3 and d <= 5 and not cells[pos].has("lead") and not _is_glimpse(pos):
			candidates.append(pos)
	candidates.sort_custom(func(a, b): return TileFactory.noise(a.x, a.y, salt) < TileFactory.noise(b.x, b.y, salt))
	# one glimpse always leans toward each other home, so there is a way to grow toward
	# the others; the rest are wherever the fog thins
	for h in HOMES:
		if h == hero_id or land_of(hero_id).has(HOMES[h]) or glimpses[hero_id].size() >= glimpse_count[hero_id]:
			continue
		var best := NONE
		var bd := 999
		for pos in candidates:
			var d := Hex.distance(pos, HOMES[h])
			if d < bd:
				bd = d
				best = pos
		if best != NONE:
			glimpses[hero_id].append(best)
	for pos in candidates:
		var ok := true
		for g in glimpses[hero_id]:
			if Hex.distance(g, pos) < 4:
				ok = false
		if ok:
			glimpses[hero_id].append(pos)
		if glimpses[hero_id].size() >= glimpse_count[hero_id]:
			break


func _is_glimpse(pos: Vector2i) -> bool:
	for h in glimpses:
		if glimpses[h].has(pos):
			return true
	return false


func glimpse_text(pos: Vector2i) -> String:
	if cells[pos].has("lead"):
		return Story.LEADS[cells[pos]["lead"]]["glimpse"]
	return GLIMPSE_TEXT.get(cells[pos]["layout"], "something in the fog")


## Cells holding a lead's fragment: {pos: lead id}.
func lead_cells() -> Dictionary:
	var out := {}
	for pos in cells:
		if cells[pos].has("lead") and cells[pos]["state"] == "unstable":
			out[pos] = cells[pos]["lead"]
	return out


## Puts a lead's fragment out in the fog, 3-5 hexes from its hero's land.
func place_lead(lead_id: String) -> Vector2i:
	for pos in cells:
		if cells[pos].get("lead", "") == lead_id and cells[pos]["state"] == "unstable":
			return pos
	var lead: Dictionary = Story.LEADS[lead_id]
	var hero_id: String = lead["hero"]
	var land_dist := _distance_from(land_of(hero_id))
	var best := NONE
	var best_score := -INF
	for pos in cells:
		var d: int = land_dist.get(pos, 99)
		# far enough that getting there is a journey: two or three days on the road
		if cells[pos]["state"] != "unstable" or cells[pos].has("lead") or _is_glimpse(pos) or d < 5 or d > 8:
			continue
		var score := (10.0 if _world_for(pos) == lead["world"] else 0.0) - absf(d - 6.0) + TileFactory.noise(pos.x, pos.y, 404)
		for other in lead_cells():
			if Hex.distance(other, pos) < 4:
				score -= 6.0
		if score > best_score:
			best_score = score
			best = pos
	if best != NONE:
		cells[best] = _cell(lead["world"], lead["layout"], "unstable", best)
		cells[best]["lead"] = lead_id
		rebuild_all()
	return best


## The Drift shifts: unstable land far from any territory re-rolls, the outer edge breaks
## apart and re-forms, and new glimpses appear for every open region.
## Cells the Drift must leave alone: the road and destination of a hero who is out on it.
var protect := {}


func drift_shift(day: int) -> void:
	var all_land := {}
	for h in open_regions:
		all_land.merge(land_of(h))
	var dist := _distance_from(all_land)
	for col in range(COLS.x, COLS.y):
		for row in range(ROWS.x, ROWS.y):
			var pos := Vector2i(col, row)
			if cells.has(pos) and (cells[pos]["state"] != "unstable" or cells[pos].has("lead")):
				continue
			if protect.has(pos):
				continue
			var d: int = dist.get(pos, 99)
			if d < 2:
				continue
			var n := TileFactory.noise(col, row, 200 + day)
			var gone := (d >= 6 and n < 0.3) or (d >= 3 and n > 0.86)
			if gone and _in_corridor(pos):
				gone = n < 0.12
			if gone:
				cells.erase(pos)
				continue
			var worlds := BASE_WORLDS_FOR(pos)
			var w: String = worlds[int(TileFactory.noise(col, row, 300 + day) * worlds.size()) % worlds.size()]
			cells[pos] = _cell(w, _random_layout(w, pos, day), "unstable", pos)
	for h in open_regions:
		pick_glimpses(h, day)
	rebuild_all()


## Worlds that may drift into a spot: its region's neighborhood, with the discovered worlds mixed in.
func BASE_WORLDS_FOR(pos: Vector2i) -> Array:
	var out := [_world_for(pos)]
	for w in Worlds.BASE_DRAFTABLE:
		if not out.has(w):
			out.append(w)
	if open_regions.has("engineer"):
		for w in ["leader", "coven"]:
			if not out.has(w):
				out.append(w)
	return out


# ------------------------------------------------------------------ expeditions
## Shortest route from a hero's land to a target, through cells that exist.
## Returns [start_land_cell, first_step, ..., target].
func route_to(target: Vector2i, hero_id: String) -> Array[Vector2i]:
	var land := land_of(hero_id)
	var came := {target: target}
	var frontier: Array[Vector2i] = [target]
	var found := NONE
	while not frontier.is_empty() and found == NONE:
		var next: Array[Vector2i] = []
		for pos in frontier:
			for n in Hex.neighbors(pos):
				if not cells.has(n) or came.has(n):
					continue
				came[n] = pos
				if land.has(n):
					found = n
					break
				if cells[n]["state"] == "unstable":
					next.append(n)
			if found != NONE:
				break
		frontier = next
	var route: Array[Vector2i] = []
	if found == NONE:
		return route
	var cur := found
	route.append(cur)
	while cur != target:
		cur = came[cur]
		route.append(cur)
	return route


## The shortest way between two cells over any land that exists. Empty if there is none.
func path_between(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var came := {a: a}
	var frontier: Array[Vector2i] = [a]
	while not frontier.is_empty() and not came.has(b):
		var next: Array[Vector2i] = []
		for pos in frontier:
			for n in Hex.neighbors(pos):
				if cells.has(n) and not came.has(n):
					came[n] = pos
					next.append(n)
		frontier = next
	var out: Array[Vector2i] = []
	if not came.has(b):
		return out
	var cur := b
	while cur != a:
		out.push_front(cur)
		cur = came[cur]
	out.push_front(a)
	return out


# ------------------------------------------------------------------ known notables
## Tiles whose notables the heroes know about (walked past them, or were told) carry a
## small mark: a glint while something there is unexamined, a dim dot once all of it is.
var _note_layer: Node2D
var _wp_layer: Node2D


func refresh_notes() -> void:
	if _note_layer == null:
		_note_layer = Node2D.new()
		_note_layer.z_index = 15
		add_child(_note_layer)
		_wp_layer = Node2D.new()
		_wp_layer.z_index = 16
		add_child(_wp_layer)
	for c in _note_layer.get_children():
		c.queue_free()
	for pos in cells:
		var c: Dictionary = cells[pos]
		if not c.get("known", false) or c.get("notables", []).is_empty():
			continue
		var open: bool = c["notables"].any(func(n): return not n["done"] or (n["type"] == "story" and int(n.get("stage", 0)) < Notables.STORIES[n["id"]]["stages"].size() and Story.day >= int(n.get("ready_day", 0))))
		var s := Sprite2D.new()
		s.texture = TileFactory.glint_texture() if open else TileFactory.dot_texture()
		s.position = center_of(pos) + Vector2(7, -9)
		s.modulate = Color(1, 1, 1, 1.0 if open else 0.7)
		_note_layer.add_child(s)


func show_waypoints(points: Array) -> void:
	if _wp_layer == null:
		refresh_notes()
	for c in _wp_layer.get_children():
		c.queue_free()
	for i in range(points.size()):
		var l := Label.new()
		l.text = str(i + 1)
		l.add_theme_color_override("font_color", Color("#f0b050"))
		l.add_theme_color_override("font_outline_color", Color("#0c0a0e"))
		l.add_theme_constant_override("outline_size", 3)
		l.add_theme_font_size_override("font_size", 11)
		l.position = center_of(points[i]) + Vector2(-3, -24)
		_wp_layer.add_child(l)


## What the heroes know is on a tile, for the tooltip.
func notes_text(pos: Vector2i) -> String:
	if not cells.has(pos) or not cells[pos].get("known", false):
		return ""
	var lines := []
	for n in cells[pos].get("notables", []):
		var look := Notables.look(n)
		if n["type"] == "story":
			var stages: int = Notables.STORIES[n["id"]]["stages"].size()
			var stage: int = int(n.get("stage", 0))
			var state := "its story is told" if stage >= stages else ("something has changed there" if Story.day >= int(n.get("ready_day", 0)) else "quiet, for now")
			lines.append("  %s (%s)" % [look["story"], state])
		else:
			lines.append(("  %s (examined)" if n["done"] else "  %s") % look["name"])
	return "" if lines.is_empty() else "Known here:\n" + "\n".join(lines)


func show_route(route: Array[Vector2i]) -> void:
	var pts := PackedVector2Array()
	for pos in route:
		pts.append(center_of(pos) + Vector2(0, 3))
	_route_line.points = pts


func can_shape(pos: Vector2i, route: Array[Vector2i]) -> bool:
	if not cells.has(pos) or cells[pos]["state"] != "unstable" or route.has(pos) or cells[pos].has("lead"):
		return false
	for r in route:
		if Hex.distance(r, pos) == 1 and cells[r]["state"] == "unstable":
			return true
	return false


func shape(pos: Vector2i, card: Dictionary) -> void:
	var previous: Dictionary = cells[pos].duplicate()
	cells[pos] = {"world": card["world"], "layout": card["layout"], "state": "shaped", "settle": 0,
			"seed": previous["seed"], "previous": previous}
	revealed[pos] = true
	_refresh_local(pos)


## Shaped land fades back into the fog when an expedition ends.
func clear_shaped() -> void:
	for pos in cells.keys():
		if cells[pos]["state"] == "shaped":
			cells[pos] = cells[pos]["previous"]
	revealed.clear()
	_route_line.points = PackedVector2Array()
	rebuild_all()


func reveal_around(pos: Vector2i) -> void:
	revealed[pos] = true
	for n in Hex.neighbors(pos):
		revealed[n] = true
	_refresh_local(pos)


## Redraws one cell and its ring. Shaping and revealing don't move land, so the fog
## field and the lights stand; only these tiles need new textures and parameters.
func _refresh_local(pos: Vector2i) -> void:
	if cells.has(pos):
		refresh(pos)
	for n in Hex.neighbors(pos):
		if cells.has(n):
			refresh(n)
	_seams.queue_redraw()


## Fuse a brought-home fragment onto the edge of a hero's territory, at the point nearest
## to where it was found. Void next to the land counts: new ground forms there.
## Returns the cells it now occupies.
func fuse(tiles: Array, toward: Vector2, hero_id: String) -> Array[Vector2i]:
	var placed: Array[Vector2i] = []
	for t in tiles:
		var best := NONE
		var best_score := -INF
		var candidates := {}
		var anchors: Array = placed.duplicate() if not placed.is_empty() else land_of(hero_id).keys()
		for a in anchors:
			for n in Hex.neighbors(a):
				if not _in_bounds(n) or placed.has(n):
					continue
				if cells.has(n) and (cells[n]["state"] != "unstable" or cells[n].has("lead")):
					continue
				candidates[n] = true
		for pos in candidates:
			var score := -center_of(pos).distance_to(toward) + TileFactory.noise(pos.x, pos.y, 505) * 4.0
			if not cells.has(pos):
				score -= 6.0  # prefer real ground over forming new ground in the void
			if score > best_score:
				best_score = score
				best = pos
		if best == NONE:
			break
		var previous: Dictionary = cells[best].duplicate() if cells.has(best) else _cell(t["world"], "bare", "unstable", best)
		cells[best] = {"world": t["world"], "layout": t["layout"], "state": "settling", "settle": 2,
				"seed": previous["seed"], "previous": previous, "fragment": placed.size(), "owner": hero_id}
		placed.append(best)
	_land_cache.clear()
	rebuild_all()
	return placed


## Land that loses its hold (a failed anchor) drifts back into the fog.
func release(pos: Vector2i) -> void:
	if cells.has(pos) and cells[pos].has("previous"):
		cells[pos] = cells[pos]["previous"]
	elif cells.has(pos):
		cells[pos]["state"] = "unstable"
		cells[pos].erase("owner")
	_land_cache.clear()
	rebuild_all()


# ------------------------------------------------------------------ visuals
func rebuild_all() -> void:
	_land_cache.clear()
	update_lights(false)
	call_deferred("refresh_notes")
	for pos in _nodes.keys():
		if not cells.has(pos):
			_nodes[pos].queue_free()
			_nodes.erase(pos)
	_compute_fog()
	for pos in cells:
		refresh(pos)
	_refresh_markers()
	_seams.queue_redraw()


func refresh(pos: Vector2i) -> void:
	var cell: Dictionary = cells[pos]
	var node: Node2D = _nodes.get(pos)
	if node == null:
		node = Node2D.new()
		node.position = center_of(pos)
		for i in range(3):
			var s := Sprite2D.new()
			s.centered = false
			s.offset = TileFactory.tile_offset()
			if i < 2:
				var m := ShaderMaterial.new()
				m.shader = tile_shader
				s.material = m
			node.add_child(s)
		add_child(node)
		_nodes[pos] = node
	var ground: Sprite2D = node.get_child(0)
	var feats: Sprite2D = node.get_child(1)
	var outline: Sprite2D = node.get_child(2)
	ground.texture = TileFactory.ground(cell["world"], cell["seed"])
	if cell.has("structure"):
		feats.texture = TileFactory.structure(cell["structure"]["id"], cell["world"], cell["seed"],
			bool(cell["structure"].get("damaged", false)), bool(cell["structure"].get("dark", false)))
	else:
		feats.texture = TileFactory.features(cell["layout"], cell["seed"])
	outline.texture = TileFactory.settle_texture
	outline.visible = cell["state"] in ["settling", "shaped"]
	outline.modulate = Color(1, 1, 1, 1) if cell["state"] == "settling" else Color(0.75, 0.68, 0.9, 0.8)
	var unstable: bool = cell["state"] == "unstable"
	node.position = center_of(pos) + drift_offset(pos)
	var fog: float = _fog.get(pos, 0.0) if unstable else 0.0
	if revealed.has(pos):
		fog = 0.0
	var deep := 0.0
	if unstable:
		var off := center_of(pos) - center_of(HOMES["oracle"])
		deep = clampf((off.x * 0.4 + off.y) / 400.0, 0.0, 1.0)
	for pair in [[ground, -1, fog], [feats, -2 if not revealed.has(pos) else -1, fog * 0.25]]:
		var m: ShaderMaterial = pair[0].material
		m.set_shader_parameter("unstable", unstable)
		m.set_shader_parameter("shift", pair[1])
		m.set_shader_parameter("fog", pair[2])
		m.set_shader_parameter("deep", deep)
		m.set_shader_parameter("erode", (1.0 if pair[0] == ground else 0.0) if unstable and not revealed.has(pos) else 0.0)
		m.set_shader_parameter("seed", float(cell["seed"] % 97))
		_set_lights(m)


## Small lights from structures: what each one gives off when it stands and works.
const STRUCTURE_LIGHT := {
	"lamps": [52.0, Color("#f0b050")], "shrine": [30.0, Color("#9fd6dc")], "forge": [26.0, Color("#e0803c")],
	"mess_hall": [28.0, Color("#f0b050")], "capacitor": [20.0, Color("#5fb8c4")], "infirmary": [18.0, Color("#f0b050")],
}
var _small_pos := PackedVector2Array()
var _small_radius := PackedFloat32Array()
var _small_tint := PackedColorArray()


## Gathers the structures' lights. Called by rebuild_all and whenever a structure changes.
func update_lights(apply: bool = true) -> void:
	_small_pos = PackedVector2Array()
	_small_radius = PackedFloat32Array()
	_small_tint = PackedColorArray()
	for pos in cells:
		var c: Dictionary = cells[pos]
		if not c.has("structure") or c["state"] != "stable":
			continue
		var st: Dictionary = c["structure"]
		if st.get("damaged", false) or st.get("dark", false) or not STRUCTURE_LIGHT.has(st["id"]):
			continue
		if _small_pos.size() >= 24:
			break
		_small_pos.append(center_of(pos) + Vector2(0, -6))
		_small_radius.append(STRUCTURE_LIGHT[st["id"]][0])
		_small_tint.append(STRUCTURE_LIGHT[st["id"]][1])
	if apply:
		for p in _nodes:
			for i in range(2):
				_set_lights(_nodes[p].get_child(i).material)


## The light sources: one per open region (the pillar, the mast, Pallas's windows), plus the small lights.
func _set_lights(m: ShaderMaterial) -> void:
	m.set_shader_parameter("small_count", _small_pos.size())
	if _small_pos.size() > 0:
		m.set_shader_parameter("small_pos", _small_pos)
		m.set_shader_parameter("small_radius", _small_radius)
		m.set_shader_parameter("small_tint", _small_tint)
	var names := ["oracle", "engineer", "gunslinger"]
	var tints := [Color("#e6fbff"), Color("#f0c060"), Color("#f0b050")]
	for i in range(3):
		var on: bool = open_regions.has(names[i])
		var c := center_of(HOMES[names[i]]) + Vector2(0, -20)
		m.set_shader_parameter("light_pos%d" % (i + 1), c)
		m.set_shader_parameter("light_radius%d" % (i + 1), (95.0 if i == 0 else 80.0) if on else 0.0)
		m.set_shader_parameter("light_tint%d" % (i + 1), tints[i])


## Unstable pieces drift out of line; settling pieces sit a pixel off; stable land is level.
func drift_offset(pos: Vector2i) -> Vector2:
	var state: String = cells[pos]["state"]
	if state == "unstable" and not revealed.has(pos):
		var a := TileFactory.noise(pos.x, pos.y, 71)
		var b := TileFactory.noise(pos.x, pos.y, 72)
		return Vector2(roundf((a - 0.5) * 7.0), roundf(b * 4.0 + 1.0))
	if state == "settling":
		return Vector2(0, 1)
	return Vector2.ZERO


const HEX_VERTS := [Vector2(-8, -12), Vector2(8, -12), Vector2(16, 0), Vector2(8, 12), Vector2(-8, 12), Vector2(-16, 0)]


## Faint dotted seams where two stable pieces are bound together, in the color of the
## method that holds them: the pillar's light, the anchors' glow, Pallas's cables.
func _draw_seams() -> void:
	for pos in cells:
		if cells[pos]["state"] != "stable":
			continue
		for n in Hex.neighbors(pos):
			if not cells.has(n) or cells[n]["state"] != "stable" or n.x * 1000 + n.y < pos.x * 1000 + pos.y:
				continue
			var owner: String = cells[pos].get("owner", cells[n].get("owner", "oracle"))
			var col: Color = SEAM_COLORS.get(owner, SEAM_COLORS["oracle"])
			var c := center_of(pos)
			var d := center_of(n) - c
			var verts := HEX_VERTS.duplicate()
			verts.sort_custom(func(p1, p2): return p1.distance_to(d) < p2.distance_to(d))
			var a: Vector2 = c + verts[0]
			var b: Vector2 = c + verts[1]
			var steps := int(a.distance_to(b) / 3.0)
			for i in range(1, steps):
				var pt := a.lerp(b, float(i) / steps).floor()
				_seams.draw_rect(Rect2(pt, Vector2.ONE), Color(col, 0.75))


func _distance_from(sources: Dictionary) -> Dictionary:
	var dist := {}
	var frontier: Array[Vector2i] = []
	for pos in sources:
		dist[pos] = 0
		frontier.append(pos)
	while not frontier.is_empty():
		var next: Array[Vector2i] = []
		for pos in frontier:
			for n in Hex.neighbors(pos):
				if cells.has(n) and not dist.has(n):
					dist[n] = dist[pos] + 1
					next.append(n)
		frontier = next
	return dist


func _compute_fog() -> void:
	_fog.clear()
	var all_land := {}
	for pos in cells:
		if cells[pos]["state"] in ["stable", "settling"]:
			all_land[pos] = true
	var dist := _distance_from(all_land)
	for pos in cells:
		var d: int = dist.get(pos, 8)
		_fog[pos] = minf(0.75, 0.18 + 0.1 * maxi(0, d - 1) + TileFactory.noise(pos.x, pos.y, 21) * 0.12)


func _refresh_markers() -> void:
	var leads := lead_cells()
	var wanted: Array = []
	for h in open_regions:
		wanted.append_array(glimpses[h])
	wanted.append_array(leads.keys())
	for pos in _markers.keys():
		if not wanted.has(pos):
			_markers[pos].queue_free()
			_markers.erase(pos)
	for pos in wanted:
		if _markers.has(pos) or not cells.has(pos):
			continue
		var m := Sprite2D.new()
		m.texture = TileFactory.lead_marker_texture() if leads.has(pos) else TileFactory.marker_texture()
		m.z_index = 19
		m.position = center_of(pos) + Vector2(0, -14)
		add_child(m)
		var tw := m.create_tween().set_loops()
		tw.tween_property(m, "position:y", m.position.y - 2, 0.5)
		tw.tween_property(m, "position:y", m.position.y, 0.5)
		_markers[pos] = m


func show_markers(on: bool) -> void:
	for pos in _markers:
		_markers[pos].visible = on


## Whether a marker belongs to the active hero (glimpse or lead in their region).
func is_target_for(pos: Vector2i, hero_id: String) -> bool:
	if glimpses[hero_id].has(pos):
		return true
	var leads := lead_cells()
	return leads.has(pos) and Story.LEADS[leads[pos]]["hero"] == hero_id


## -1 hidden, 0 neutral, 1 valid, 2 invalid
func set_hover_style(style: int) -> void:
	_hover_sprite.visible = style >= 0 and cells.has(_hovered)
	if style >= 0:
		_hover_sprite.modulate = [Color(1, 1, 1, 0.45), Color("#9fe0e6"), Color("#9a2e3e")][style]


# ------------------------------------------------------------------ picking
func pick(p: Vector2) -> Vector2i:
	var col := roundi((p.x - ORIGIN.x) / Hex.COL_STEP)
	for c in range(col - 1, col + 2):
		var row := roundi((p.y - ORIGIN.y - (c & 1) * (Hex.ROW_STEP / 2)) / Hex.ROW_STEP)
		for r in range(row - 1, row + 2):
			var pos := Vector2i(c, r)
			var d := p - center_of(pos)
			if Hex.in_top(floorf(d.x), floorf(d.y)):
				return pos
	return NONE


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var pos := pick(get_local_mouse_position())
		if pos != _hovered:
			_hovered = pos
			if cells.has(pos):
				_hover_sprite.position = center_of(pos)
			cell_hovered.emit(pos, cells.has(pos))
	elif event is InputEventMouseButton and event.pressed:
		var pos := pick(get_local_mouse_position())
		if cells.has(pos):
			cell_clicked.emit(pos, event.button_index)
			get_viewport().set_input_as_handled()
