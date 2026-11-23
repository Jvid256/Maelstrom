class_name Way
extends Node2D
## The Way: an expedition played on its own map, built from the world tiles the route
## crosses. Each world tile becomes a stretch of road, a small top-down field in that
## world's ground with its world-map neighbours bleeding in at the edges. The hero walks a
## path through the stretches past notables (Notables) and whatever the fog sends.
##
## The Way is geometry and pictures. main.gd decides what happens at each stop.

signal notable_hovered(text: String)
signal notable_clicked(stretch: int, index: int)

const W := 9          # columns per stretch
const H := 7          # rows
const FINAL_W := 6    # the destination stretch is shorter: the road ends at the place
const ORIGIN := Vector2(24, 28)
const AMBIENT := 0.44 # darker than home: the lantern carries
const LANTERN := 78.0
## Layouts too particular to scatter as roadside clutter; they appear only as a stretch's landmark.
const LANDMARK_ONLY := ["saloon", "questboard", "crypt", "bunker", "beacon", "dunes_tower", "server", "town", "ice_house", "cauldron", "drone_field", "plaza"]

var stretches: Array = []     # [{cell, world, layout, col0, cols, first, last, notables, landmark, final}]
var path: Array[Vector2i] = []
var path_stretch := PackedInt32Array()
var stops := {}               # path index -> [{"type": "notable"|"encounter"|"exit", "s": k, "i": j}]
var cells := {}               # way pos -> {world, layout, seed, hole}
var hero: Sprite2D
var dest_marker: Sprite2D
var _nodes := {}
var _ground_mat: ShaderMaterial
var _feat_mat: ShaderMaterial
var _void: Sprite2D
var _notable_sprites := {}    # "k:j" -> {cell, sprite, glint, look, n}
var _enemies := {}            # stretch -> Node2D
var _notable_at := {}         # way pos -> [k, j]
var _hovered := Vector2i(-99, -99)
var _camp_spots := []         # global positions of camp fires, for the light
var _time := 0.0
var tile_shader: Shader = preload("res://shaders/tile.gdshader")


func _ready() -> void:
	y_sort_enabled = true
	_ground_mat = _material()
	_feat_mat = _material()


func _material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = tile_shader
	m.set_shader_parameter("unstable", false)
	m.set_shader_parameter("fog", 0.0)
	m.set_shader_parameter("erode", 0.0)
	m.set_shader_parameter("deep", 0.0)
	m.set_shader_parameter("ambient", AMBIENT)
	return m


static func center_of(pos: Vector2i) -> Vector2:
	return Hex.to_pixel(pos) + ORIGIN


func pick(p: Vector2) -> Vector2i:
	var col := roundi((p.x - ORIGIN.x) / Hex.COL_STEP)
	for c in range(col - 1, col + 2):
		var row := roundi((p.y - ORIGIN.y - (c & 1) * (Hex.ROW_STEP / 2)) / Hex.ROW_STEP)
		for r in range(row - 1, row + 2):
			var pos := Vector2i(c, r)
			var d := p - center_of(pos)
			if Hex.in_top(floorf(d.x), floorf(d.y)):
				return pos
	return Vector2i(-99, -99)


func pixel_size() -> Vector2:
	var cols := 0
	for st in stretches:
		cols += int(st["cols"])
	return Vector2(cols * Hex.COL_STEP + ORIGIN.x * 2, H * Hex.ROW_STEP + ORIGIN.y * 2 + 30)


# ------------------------------------------------------------------ building
## Builds the road. `notes` holds, per stretch, the notables to place there (dicts that
## live on the world cells, so marking one done marks it on the map too).
func build(route: Array, map: MaelstromMap, notes: Array) -> void:
	for c in get_children():
		c.queue_free()
	_nodes.clear()
	_notable_sprites.clear()
	_enemies.clear()
	_notable_at.clear()
	_camp_spots.clear()
	cells.clear()
	stretches.clear()
	path.clear()
	path_stretch = PackedInt32Array()
	stops.clear()

	var col0 := 0
	var row := H / 2
	for k in range(route.size()):
		var wpos: Vector2i = route[k]
		var wc: Dictionary = map.cells[wpos] if map.cells.has(wpos) else {"world": "eroded", "layout": "bare", "seed": 0}
		var final := k == route.size() - 1
		var cols := FINAL_W if final else W
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(Vector3i(wpos.x, wpos.y, k * 31 + int(wc.get("seed", 0))))
		var st := {"cell": wpos, "world": wc["world"], "layout": wc["layout"], "col0": col0, "cols": cols,
			"first": path.size(), "notables": [], "landmark": Vector2i(-99, -99), "final": final}
		row = _lay_path(k, col0, cols, row, rng, final)
		st["last"] = path.size() - 1
		stretches.append(st)
		_lay_ground(k, st, wpos, map, rng)
		_lay_landmark(st, rng)
		_place_notables(k, st, notes[k] if k < notes.size() else [], rng)
		_add_stop(st["last"], {"type": "exit", "s": k})
		col0 += cols

	var size := pixel_size()
	_void = Sprite2D.new()
	_void.centered = false
	_void.z_index = -10
	_void.texture = TileFactory.make_void(int(size.x / 2) + 40, int(size.y / 2) + 60)
	_void.scale = Vector2(2, 2)
	_void.position = Vector2(-40, -40)
	add_child(_void)
	for pos in cells:
		if not cells[pos]["hole"]:
			_draw_cell(pos)
	hero = Sprite2D.new()
	hero.offset = Vector2(0, -11)
	add_child(hero)
	dest_marker = Sprite2D.new()
	dest_marker.z_index = 20
	add_child(dest_marker)
	var end: Vector2i = path[path.size() - 1]
	dest_marker.position = center_of(end) + Vector2(0, -30)


func _add_stop(index: int, stop: Dictionary) -> void:
	if not stops.has(index):
		stops[index] = []
	stops[index].append(stop)


## Walks column by column, drifting toward a wandering target row. Returns the end row.
func _lay_path(k: int, col0: int, cols: int, row: int, rng: RandomNumberGenerator, final: bool) -> int:
	var aim := rng.randi_range(1, H - 2)
	var cur := Vector2i(col0, clampi(row, 1, H - 2))
	var last_col := col0 + (cols - 1 if not final else cols / 2 + 1)
	_push_path(cur, k)
	while cur.x < last_col:
		if (cur.x - col0) % 3 == 2:
			aim = rng.randi_range(1, H - 2)
		# now and then the road bends along a column before moving on
		if rng.randf() < 0.22 and cur.y != aim:
			var up := Vector2i(cur.x, cur.y + (1 if aim > cur.y else -1))
			if up.y >= 1 and up.y <= H - 2:
				cur = up
				_push_path(cur, k)
				continue
		var best := cur
		var bd := 999.0
		for n in Hex.neighbors(cur):
			if n.x != cur.x + 1 or n.y < 1 or n.y > H - 2:
				continue
			var d := absf(n.y - aim) + rng.randf() * 0.4
			if d < bd:
				bd = d
				best = n
		cur = best
		_push_path(cur, k)
	return cur.y


func _push_path(pos: Vector2i, k: int) -> void:
	path.append(pos)
	path_stretch.append(k)


## Neighbours in the world above and below the route bleed into the stretch's edge rows.
## Where the world has void beside the route, the edge of the road breaks off into it.
func _lay_ground(k: int, st: Dictionary, wpos: Vector2i, map: MaelstromMap, rng: RandomNumberGenerator) -> void:
	var north := Vector2i(-99, -99)
	var south := Vector2i(-99, -99)
	var ny := INF
	var sy := -INF
	for n in Hex.neighbors(wpos):
		var y := Hex.to_pixel(n).y - Hex.to_pixel(wpos).y
		if y < ny:
			ny = y
			north = n
		if y > sy:
			sy = y
			south = n
	var prev_world: String = stretches[k - 1]["world"] if k > 0 else st["world"]
	var on_path := {}
	for i in range(st["first"], path.size()):
		on_path[path[i]] = true
	var scatter := []
	for l in Worlds.world(st["world"])["layouts"]:
		if not LANDMARK_ONLY.has(l):
			scatter.append(l)
	for c in range(st["col0"], st["col0"] + st["cols"]):
		for r in range(H):
			var pos := Vector2i(c, r)
			var world: String = st["world"]
			var hole := false
			var off := c - int(st["col0"])
			if off == 0 and rng.randf() < 0.5:
				world = prev_world
			elif off == 1 and rng.randf() < 0.2:
				world = prev_world
			for side in [[north, r, 0], [south, H - 1 - r, 1]]:
				var depth: int = side[1]
				if depth > 1:
					continue
				var nb: Vector2i = side[0]
				if map.cells.has(nb):
					var shaped: bool = map.cells[nb]["state"] == "shaped"
					var p: float = (0.9 if depth == 0 else 0.5) if shaped else (0.75 if depth == 0 else 0.3)
					if rng.randf() < p:
						world = map.cells[nb]["world"]
				elif rng.randf() < (0.6 if depth == 0 else 0.12):
					hole = true
			if on_path.has(pos):
				hole = false
			var layout := "bare"
			if not on_path.has(pos) and rng.randf() < 0.32:
				var wl: Array = Worlds.world(world)["layouts"].filter(func(l): return not LANDMARK_ONLY.has(l))
				if wl.is_empty():
					wl = scatter
				if not wl.is_empty():
					layout = wl[rng.randi_range(0, wl.size() - 1)]
			cells[pos] = {"world": world, "layout": layout, "seed": rng.randi_range(0, 9999), "hole": hole}


## The world tile's own layout, standing beside the road near the middle of its stretch.
func _lay_landmark(st: Dictionary, rng: RandomNumberGenerator) -> void:
	if st["layout"] == "bare":
		return
	var mid: int = (int(st["first"]) + int(st["last"])) / 2
	if st["final"]:
		mid = st["last"]
	for tries in range(6):
		var i: int = clampi(mid + rng.randi_range(-1, 1), st["first"], st["last"])
		for n in Hex.neighbors(path[i]):
			if cells.has(n) and not path.has(n) and not _notable_at.has(n):
				cells[n]["layout"] = st["layout"]
				cells[n]["world"] = st["world"]
				cells[n]["hole"] = false
				st["landmark"] = n
				return


func _place_notables(k: int, st: Dictionary, notes: Array, rng: RandomNumberGenerator) -> void:
	var first: int = st["first"] + 2
	var last: int = st["last"] - (0 if st["final"] else 1)
	var used := []
	for j in range(notes.size()):
		var spot := -1
		var cell := Vector2i(-99, -99)
		for tries in range(12):
			var i := rng.randi_range(first, maxi(first, last))
			if used.has(i):
				continue
			var options := []
			for n in Hex.neighbors(path[i]):
				if cells.has(n) and not path.has(n) and not _notable_at.has(n) and n != st["landmark"] and n.y >= 0 and n.y < H:
					options.append(n)
			if options.is_empty():
				continue
			spot = i
			cell = options[rng.randi_range(0, options.size() - 1)]
			break
		if spot < 0:
			continue
		used.append(spot)
		cells[cell]["hole"] = false
		cells[cell]["layout"] = "bare"
		_notable_at[cell] = [k, j]
		st["notables"].append({"n": notes[j], "cell": cell, "stop": spot})
		_add_stop(spot, {"type": "notable", "s": k, "i": st["notables"].size() - 1})


# ------------------------------------------------------------------ drawing
func _draw_cell(pos: Vector2i) -> void:
	var c: Dictionary = cells[pos]
	var node := Node2D.new()
	node.position = center_of(pos)
	var ground := Sprite2D.new()
	ground.centered = false
	ground.offset = TileFactory.tile_offset()
	ground.texture = TileFactory.ground(c["world"], c["seed"])
	ground.material = _ground_mat
	node.add_child(ground)
	if path.has(pos):
		var trail := Sprite2D.new()
		trail.centered = false
		trail.offset = TileFactory.tile_offset()
		trail.texture = TileFactory.trail_texture()
		trail.material = _feat_mat
		node.add_child(trail)
	var feats := Sprite2D.new()
	feats.centered = false
	feats.offset = TileFactory.tile_offset()
	feats.material = _feat_mat
	if _notable_at.has(pos):
		var kj: Array = _notable_at[pos]
		var entry: Dictionary = stretches[kj[0]]["notables"][_index_of(kj[0], pos)]
		var look := Notables.look(entry["n"])
		feats.texture = TileFactory.notable(look["kind"], c["world"], entry["n"]["done"])
		var glint := Sprite2D.new()
		glint.texture = TileFactory.glint_texture()
		glint.position = Vector2(0, -26)
		glint.visible = not entry["n"]["done"]
		node.add_child(feats)
		node.add_child(glint)
		_notable_sprites["%d:%d" % [kj[0], _index_of(kj[0], pos)]] = {"cell": pos, "sprite": feats, "glint": glint, "entry": entry}
	else:
		feats.texture = TileFactory.features(c["layout"], c["seed"])
		node.add_child(feats)
	add_child(node)
	_nodes[pos] = node


func _index_of(k: int, cell: Vector2i) -> int:
	var list: Array = stretches[k]["notables"]
	for i in range(list.size()):
		if list[i]["cell"] == cell:
			return i
	return -1


## Marks a notable examined: its glint goes out and its art dims.
func mark_done(k: int, i: int) -> void:
	var key := "%d:%d" % [k, i]
	if not _notable_sprites.has(key):
		return
	var e: Dictionary = _notable_sprites[key]
	e["entry"]["n"]["done"] = true
	e["glint"].visible = false
	var look := Notables.look(e["entry"]["n"])
	e["sprite"].texture = TileFactory.notable(look["kind"], cells[e["cell"]]["world"], true)


func notable(k: int, i: int) -> Dictionary:
	return stretches[k]["notables"][i]


## Camp at the end of a stretch: a fire ring just off the road.
func add_camp(k: int) -> void:
	var st: Dictionary = stretches[k]
	var at: Vector2i = path[st["last"]]
	var spot := at
	var best := -INF
	for n in Hex.neighbors(at):
		if cells.has(n) and not cells[n]["hole"] and not path.has(n) and not _notable_at.has(n) and n != st["landmark"]:
			# beside or below the road, never straight above it where the hero would hide it
			var score := center_of(n).y - center_of(at).y + absf(center_of(n).x - center_of(at).x) * 0.5
			if score > best:
				best = score
				spot = n
	var s := Sprite2D.new()
	s.centered = false
	s.offset = TileFactory.tile_offset()
	s.texture = TileFactory.camp_texture()
	s.material = _feat_mat
	s.position = center_of(spot) + Vector2(0, 1)
	add_child(s)
	_camp_spots.append(s)


## Something from the fog, standing on the road ahead.
## danger: 0 easy, 1 wary, 2 dangerous, 3 deadly (main.threat). Dangerous and deadly
## things carry a sign over them you can see from far down the road.
func place_encounter(k: int, ids: Array, danger: int = 0) -> int:
	var st: Dictionary = stretches[k]
	var span: int = int(st["last"]) - int(st["first"])
	var idx: int = int(st["first"]) + clampi(int(span * 0.6), 2, maxi(2, span - 1))
	while stops.has(idx - 1) and idx < int(st["last"]):
		idx += 1
	var holder := Node2D.new()
	holder.position = center_of(path[idx]) + Vector2(0, 1)
	for n in range(ids.size()):
		var s := Sprite2D.new()
		s.texture = TileFactory.enemy_texture(ids[n])
		s.offset = Vector2(-5 + n * 10 if ids.size() > 1 else 0, -12)
		s.material = _feat_mat
		holder.add_child(s)
	if danger >= 2:
		var sign := Label.new()
		sign.text = "!!" if danger == 3 else "!"
		sign.add_theme_font_size_override("font_size", 11)
		sign.add_theme_color_override("font_color", Color("#e0503c") if danger == 3 else Color("#e0a03c"))
		sign.add_theme_color_override("font_outline_color", Color("#0c0a0e"))
		sign.add_theme_constant_override("outline_size", 3)
		sign.position = Vector2(-4 if danger == 2 else -6, -40)
		sign.name = "Danger"
		holder.add_child(sign)
	holder.set_meta("danger", danger)
	holder.set_meta("names", " and ".join(ids.map(func(id): return Bestiary.enemy(id)["name"])))
	add_child(holder)
	_enemies[k] = holder
	_add_stop(idx - 1, {"type": "encounter", "s": k})
	return idx - 1


func clear_encounter(k: int) -> void:
	if _enemies.has(k):
		var h: Node2D = _enemies[k]
		var tw := h.create_tween()
		tw.tween_property(h, "modulate:a", 0.0, 0.4)
		tw.tween_callback(h.queue_free)
		_enemies.erase(k)


func hero_at(index: int) -> Vector2:
	return center_of(path[index]) + Vector2(0, 1)


# ------------------------------------------------------------------ light and input
func _process(delta: float) -> void:
	if not visible or hero == null:
		return
	_time += delta
	var lp := hero.global_position + Vector2(0, -10)
	var dp := dest_marker.global_position + Vector2(0, 24)
	var small := PackedVector2Array()
	var radius := PackedFloat32Array()
	var tint := PackedColorArray()
	for key in _notable_sprites:
		var e: Dictionary = _notable_sprites[key]
		if not e["entry"]["n"]["done"] and small.size() < 20:
			small.append(to_global(center_of(e["cell"])) + Vector2(0, -8))
			radius.append(15.0)
			tint.append(Color("#9fd6dc"))
		e["glint"].position.y = -26 + roundf(sin(_time * 3.0 + e["cell"].x) * 1.5)
	for c in _camp_spots:
		if small.size() < 24:
			small.append(c.global_position + Vector2(0, -6))
			radius.append(40.0 + sin(_time * 7.0) * 2.0)
			tint.append(Color("#f0a050"))
	for k in _enemies:
		var danger: int = int(_enemies[k].get_meta("danger", 0))
		if small.size() < 24:
			small.append(_enemies[k].global_position + Vector2(0, -10))
			radius.append(14.0 + 5.0 * danger + (sin(_time * 4.0) * 3.0 if danger >= 2 else 0.0))
			tint.append(Color("#c0453a"))
		var sign: Node = _enemies[k].get_node_or_null("Danger")
		if sign:
			sign.position.y = -40 + roundf(sin(_time * 3.0) * 1.5)
	dest_marker.position.y = center_of(path[path.size() - 1]).y - 30 + roundf(sin(_time * 2.0) * 2.0)
	for m in [_ground_mat, _feat_mat]:
		m.set_shader_parameter("light_pos1", lp)
		m.set_shader_parameter("light_radius1", LANTERN)
		m.set_shader_parameter("light_tint1", Color("#f0c070"))
		m.set_shader_parameter("light_pos2", dp)
		m.set_shader_parameter("light_radius2", 54.0)
		m.set_shader_parameter("light_tint2", Color("#e6fbff"))
		m.set_shader_parameter("light_radius3", 0.0)
		m.set_shader_parameter("small_count", small.size())
		if small.size() > 0:
			m.set_shader_parameter("small_pos", small)
			m.set_shader_parameter("small_radius", radius)
			m.set_shader_parameter("small_tint", tint)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseMotion:
		var pos := pick(get_local_mouse_position())
		if pos != _hovered:
			_hovered = pos
			notable_hovered.emit(_hover_text(pos))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos := pick(get_local_mouse_position())
		if _notable_at.has(pos):
			var kj: Array = _notable_at[pos]
			notable_clicked.emit(kj[0], _index_of(kj[0], pos))
			get_viewport().set_input_as_handled()


func _hover_text(pos: Vector2i) -> String:
	for k in _enemies:
		var h: Node2D = _enemies[k]
		if pick(h.position - Vector2(0, 1)) == pos:
			return "%s\n%s" % [h.get_meta("names"), ["Looks manageable.", "Be careful.", "This one's dangerous!", "This could kill you!"][int(h.get_meta("danger"))]]
	if _notable_at.has(pos):
		var kj: Array = _notable_at[pos]
		var e: Dictionary = stretches[kj[0]]["notables"][_index_of(kj[0], pos)]
		var look := Notables.look(e["n"])
		if e["n"]["done"]:
			return "%s\n%s" % [look["name"], look.get("seen", "") if look.get("seen", "") != "" else "Examined."]
		return "%s\nClick or press E when the hero is beside it." % look["name"]
	if not cells.has(pos) or cells[pos]["hole"]:
		return ""
	for st in stretches:
		if st["landmark"] == pos:
			return "%s\n%s ground. The place this stretch of road crosses." % [Worlds.LAYOUT_NAMES.get(st["layout"], st["layout"]), Worlds.world(st["world"])["name"]]
	return ""
