extends Node
## Builds tile textures following the style anchor.
##
## Godot draws the hex itself (mask, outline, edge light, side face). The art you
## supply only covers what goes ON the hex:
##   res://art/ground/<world>.png      a 32x32 (or larger) ground texture, e.g. eroded.png
##   res://art/features/<feature>.png  a transparent sprite, anchored bottom-center, e.g. tree.png
## Anything missing falls back to the built-in placeholder pixel art below.

const TEX_W := 40
const TEX_H := 64
const CENTER := Vector2i(20, 36)  # hex center inside the texture

var _ground_cache := {}
var _feature_cache := {}
var _icon_cache := {}
var _png_cache := {}
var highlight_texture: ImageTexture
var settle_texture: ImageTexture


func _ready() -> void:
	highlight_texture = _make_outline(Color(1, 1, 1, 1), false)
	settle_texture = _make_outline(Worlds.SETTLE, true)


## Offset that places a tile texture so its hex center sits on the node position.
func tile_offset() -> Vector2:
	return -Vector2(CENTER)


func ground(world_id: String, seed: int) -> ImageTexture:
	var key := "%s|%d" % [world_id, seed % 4]
	if not _ground_cache.has(key):
		_ground_cache[key] = ImageTexture.create_from_image(_build_ground(world_id, seed % 4))
	return _ground_cache[key]


func features(layout: String, seed: int) -> ImageTexture:
	var key := "%s|%d" % [layout, seed % 4]
	if not _feature_cache.has(key):
		_feature_cache[key] = ImageTexture.create_from_image(_build_features(layout, seed % 4))
	return _feature_cache[key]


# ------------------------------------------------------------------ structures
## What each world's ground builds with: a structure keeps one silhouette everywhere and
## takes its body, trim and accent from the material under it.
const MATERIALS := {
	"kingdom": {"body": "stone", "body_d": "stone_d", "body_l": "stone_l", "trim": "marble_d", "accent": "window", "accent_d": "window_d"},
	"eroded": {"body": "steel", "body_d": "steel_d", "body_l": "steel_l", "trim": "rust", "accent": "pane_lit", "accent_d": "rust"},
	"hollow": {"body": "bone_d", "body_d": "trunk_d", "body_l": "bone", "trim": "trunk", "accent": "glass_v", "accent_d": "iron"},
	"frozen": {"body": "ice_m", "body_d": "ice_d", "body_l": "ice_l", "trim": "crack", "accent": "amber", "accent_d": "sun"},
	"leader": {"body": "iron", "body_d": "neon_d", "body_l": "iron_l", "trim": "neon_m", "accent": "neon_c", "accent_d": "neon_d"},
	"coven": {"body": "iron", "body_d": "thorn", "body_l": "iron_l", "trim": "sigil", "accent": "ember_l", "accent_d": "ember"},
}
var _structure_cache := {}


func structure(id: String, world_id: String, seed: int, damaged: bool, dark: bool) -> ImageTexture:
	var key := "%s|%s|%d|%s|%s" % [id, world_id, seed % 2, damaged, dark]
	if not _structure_cache.has(key):
		_structure_cache[key] = ImageTexture.create_from_image(_build_structure(id, world_id, seed % 2, damaged, dark))
	return _structure_cache[key]


func _build_structure(id: String, world_id: String, variant: int, damaged: bool, dark: bool) -> Image:
	var img := _new_image()
	var custom := _load_png("res://art/structures/%s_%s.png" % [id, world_id])
	if custom:
		var pos := Vector2i(CENTER.x - custom.get_width() / 2, CENTER.y + 5 - custom.get_height())
		img.blend_rect(custom, Rect2i(Vector2i.ZERO, custom.get_size()), pos)
	else:
		var m: Dictionary = MATERIALS.get(world_id, MATERIALS["kingdom"])
		var pal := {}
		for k in m:
			pal[k] = _c(m[k])
		if dark or damaged:
			pal["accent"] = pal["body_d"]
			pal["accent_d"] = pal["body_d"]
		call("_s_" + id, img, CENTER.x, CENTER.y + 4, pal, variant)
	if damaged:
		_crack(img, CENTER.x, CENTER.y + 4)
	return img


## Cracks and a missing corner: the Drift has been at it.
func _crack(img: Image, x: int, y: int) -> void:
	var dk := Color("#0c0a0e")
	for k in range(7):
		_put(img, x - 2 + (k % 3), y - 2 - k, dk)
	for k in range(4):
		_put(img, x + 3 + k, y - 9 + k, dk)
	for dy in range(-16, -11):
		for dx in range(4, 9):
			if noise(dx, dy, 3) > 0.35:
				img.set_pixel(clampi(x + dx, 0, TEX_W - 1), clampi(y + dy, 0, TEX_H - 1), Color(0, 0, 0, 0))


func _box_fill(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for yy in range(y0, y1 + 1):
		for xx in range(x0, x1 + 1):
			_put(img, xx, yy, c)


## Two posts with lanterns, set a little apart.
func _s_lamps(img: Image, x: int, y: int, p: Dictionary, _v: int) -> void:
	for dx in [-6, 6]:
		for k in range(10):
			_put(img, x + dx, y - k, p["body"] if k < 8 else p["trim"])
			_put(img, x + dx + 1, y - k, p["body_d"])
		_box_fill(img, x + dx - 1, y - 13, x + dx + 2, y - 10, p["body_d"])
		_put(img, x + dx, y - 12, p["accent"])
		_put(img, x + dx + 1, y - 12, p["accent"])
		_put(img, x + dx, y - 11, p["accent_d"])
		_put(img, x + dx + 1, y - 11, p["accent_d"])
		_put(img, x + dx, y - 14, p["trim"])
		_put(img, x + dx + 1, y - 14, p["trim"])
		if p["accent"] != p["body_d"]:
			_put(img, x + dx - 2, y - 12, p["accent_d"])
			_put(img, x + dx + 3, y - 12, p["accent_d"])
			_put(img, x + dx, y - 15, p["accent_d"])
	for dx in range(-7, 9):
		_put(img, x + dx, y + 1, p["body_d"])


## A low hall behind a row of palisade stakes, a mark over the door.
func _s_infirmary(img: Image, x: int, y: int, p: Dictionary, _v: int) -> void:
	_box_fill(img, x - 7, y - 6, x + 6, y - 1, p["body"])
	_box_fill(img, x, y - 6, x + 6, y - 1, p["body_d"])
	for r in range(3):
		for dx in range(-8 + r, 8 - r):
			_put(img, x + dx, y - 7 - r, p["trim"] if dx < 0 else p["body_d"])
	_box_fill(img, x - 1, y - 3, x, y - 1, p["body_d"])
	_put(img, x - 1, y - 5, p["accent"])
	_put(img, x, y - 5, p["accent"])
	_put(img, x - 1, y - 4, p["accent_d"])
	_put(img, x, y - 4, p["accent_d"])
	for dx in range(-9, 10, 2):
		_put(img, x + dx, y + 1, p["body_l"])
		_put(img, x + dx, y, p["body_l"])
		_put(img, x + dx, y + 2, p["body_d"])


## A stepped dais and a tall lens of oracle glass.
func _s_shrine(img: Image, x: int, y: int, p: Dictionary, _v: int) -> void:
	_box_fill(img, x - 6, y, x + 6, y + 1, p["body_d"])
	_box_fill(img, x - 4, y - 2, x + 4, y - 1, p["body"])
	_box_fill(img, x - 2, y - 4, x + 2, y - 3, p["body_l"])
	for k in range(5, 15):
		_put(img, x - 1, y - k, p["trim"])
		_put(img, x + 1, y - k, p["trim"])
	var glass: Color = _c("glass_c") if p["accent"] != p["body_d"] else p["body_d"]
	for k in range(6, 14):
		_put(img, x, y - k, glass)
	_put(img, x, y - 15, p["trim"])
	_put(img, x - 1, y - 15, p["trim"])
	_put(img, x + 1, y - 15, p["trim"])
	if p["accent"] != p["body_d"]:
		_put(img, x, y - 10, _c("glow"))
		_put(img, x - 3, y - 11, p["accent_d"])
		_put(img, x + 3, y - 8, p["accent_d"])


## Two drums with coils and a cable between.
func _s_capacitor(img: Image, x: int, y: int, p: Dictionary, _v: int) -> void:
	for dx in [-5, 3]:
		_box_fill(img, x + dx, y - 9, x + dx + 3, y, p["body"])
		_box_fill(img, x + dx + 2, y - 9, x + dx + 3, y, p["body_d"])
		for k in range(2, 9, 2):
			_put(img, x + dx - 1, y - k, p["trim"])
			_put(img, x + dx + 4, y - k, p["trim"])
		_put(img, x + dx + 1, y - 10, p["accent"])
		_put(img, x + dx + 2, y - 10, p["accent_d"])
	for dx in range(-1, 3):
		_put(img, x + dx, y - 8 + (1 if dx in [0, 1] else 0), _c("cable"))
	_box_fill(img, x - 7, y + 1, x + 7, y + 1, p["body_d"])


## A squat block with a chimney, embers in its mouth, an anvil beside.
func _s_forge(img: Image, x: int, y: int, p: Dictionary, _v: int) -> void:
	_box_fill(img, x - 6, y - 7, x + 2, y, p["body"])
	_box_fill(img, x - 1, y - 7, x + 2, y, p["body_d"])
	_box_fill(img, x - 5, y - 11, x - 3, y - 8, p["body_d"])
	_put(img, x - 4, y - 12, p["trim"])
	_box_fill(img, x - 4, y - 4, x - 1, y - 2, p["accent_d"])
	_put(img, x - 3, y - 3, p["accent"])
	_put(img, x - 2, y - 4, p["accent"])
	_box_fill(img, x + 4, y - 3, x + 7, y - 2, p["body_l"])
	_box_fill(img, x + 5, y - 1, x + 6, y, p["body_d"])
	for dx in range(-7, 9):
		_put(img, x + dx, y + 1, p["body_d"])


## A drum on a frame with chain paying out to the right.
func _s_winch(img: Image, x: int, y: int, p: Dictionary, _v: int) -> void:
	for dx in [-5, 1]:
		for k in range(8):
			_put(img, x + dx, y - k, p["body"])
			_put(img, x + dx + 1, y - k, p["body_d"])
	_box_fill(img, x - 6, y - 9, x + 2, y - 8, p["trim"])
	_box_fill(img, x - 4, y - 7, x, y - 3, p["body_l"])
	_box_fill(img, x - 3, y - 6, x - 1, y - 4, p["body_d"])
	_put(img, x - 2, y - 5, p["accent"])
	var ch := _c("chain")
	for k in range(7):
		_put(img, x + 2 + k, y - 6 + (k / 2), ch if k % 2 == 0 else _c("chain_d"))
	_box_fill(img, x - 7, y + 1, x + 9, y + 1, p["body_d"])


## A long hall, lit windows, a stovepipe.
func _s_mess_hall(img: Image, x: int, y: int, p: Dictionary, _v: int) -> void:
	_box_fill(img, x - 9, y - 5, x + 8, y, p["body"])
	_box_fill(img, x + 1, y - 5, x + 8, y, p["body_d"])
	for r in range(3):
		for dx in range(-10 + r, 10 - r):
			_put(img, x + dx, y - 6 - r, p["trim"] if dx < 1 else p["body_d"])
	for dx in [-7, -3, 3, 6]:
		_put(img, x + dx, y - 3, p["accent"])
		_put(img, x + dx, y - 2, p["accent_d"])
	_box_fill(img, x - 1, y - 2, x, y, p["body_d"])
	_box_fill(img, x + 5, y - 11, x + 5, y - 9, p["body_d"])
	if p["accent"] != p["body_d"]:
		_put(img, x + 5, y - 12, p["body_l"])
		_put(img, x + 6, y - 13, p["body_l"])


# ------------------------------------------------------------------ the Way
## Notables: the places worth stopping for on the road. One silhouette per kind, in the
## materials of the ground it stands on (as structures are). Examined ones dim.
var _notable_cache := {}


func notable(kind: String, world_id: String, done: bool) -> ImageTexture:
	var key := "%s|%s|%s" % [kind, world_id, done]
	if not _notable_cache.has(key):
		var img := _new_image()
		var custom := _load_png("res://art/notables/%s_%s.png" % [kind, world_id])
		if custom:
			img.blend_rect(custom, Rect2i(Vector2i.ZERO, custom.get_size()), Vector2i(CENTER.x - custom.get_width() / 2, CENTER.y + 4 - custom.get_height()))
		else:
			var m: Dictionary = MATERIALS.get(world_id, MATERIALS["kingdom"])
			var pal := {}
			for k in m:
				pal[k] = _c(m[k])
			if done:
				pal["accent"] = pal["body_d"]
				pal["accent_d"] = pal["body_d"]
			call("_n_" + kind, img, CENTER.x, CENTER.y + 3, pal)
		_notable_cache[key] = ImageTexture.create_from_image(img)
	return _notable_cache[key]


func _n_wreck(img: Image, x: int, y: int, p: Dictionary) -> void:
	# a hull tipped on its nose, a broken strut
	for r in range(6):
		for dx in range(-7 + r, 5 - r / 2):
			_put(img, x + dx, y - r, p["body"] if dx < 0 else p["body_d"])
	_box_fill(img, x - 4, y - 8, x - 1, y - 6, p["body_l"])
	_put(img, x - 3, y - 7, p["accent"])
	for k in range(5):
		_put(img, x + 4 + k / 2, y - 3 - k, p["trim"])
	_box_fill(img, x - 8, y + 1, x + 7, y + 1, p["body_d"])


func _n_remains(img: Image, x: int, y: int, p: Dictionary) -> void:
	# something lying in the ash, a hand outstretched
	var bone := _c("bone")
	_box_fill(img, x - 5, y - 2, x + 2, y - 1, p["body_d"])
	_box_fill(img, x - 6, y - 3, x - 4, y - 2, bone)
	_put(img, x - 5, y - 4, bone)
	for k in range(4):
		_put(img, x + 3 + k, y - 1, bone if k % 2 == 0 else p["body_d"])
	_put(img, x + 1, y - 3, p["accent"])
	for dx in range(-8, 9, 3):
		_put(img, x + dx, y + 1, _c("ash_d"))


func _n_door(img: Image, x: int, y: int, p: Dictionary) -> void:
	# a frame half sunk in the ground, the door ajar
	_box_fill(img, x - 6, y - 13, x + 5, y, p["body"])
	_box_fill(img, x - 4, y - 11, x + 3, y, _c("void_d"))
	_box_fill(img, x - 4, y - 11, x - 1, y, p["body_d"])
	_put(img, x - 2, y - 6, p["accent"])
	for dx in range(-6, 6):
		_put(img, x + dx, y - 14, p["trim"])
	_box_fill(img, x - 8, y + 1, x + 7, y + 1, p["body_d"])


func _n_machine(img: Image, x: int, y: int, p: Dictionary) -> void:
	# a cabinet with a lit panel and a mast
	_box_fill(img, x - 4, y - 9, x + 3, y, p["body"])
	_box_fill(img, x + 1, y - 9, x + 3, y, p["body_d"])
	_box_fill(img, x - 3, y - 7, x, y - 5, _c("void_d"))
	_put(img, x - 2, y - 6, p["accent"])
	_put(img, x - 1, y - 6, p["accent_d"])
	for k in range(10, 15):
		_put(img, x + 2, y - k, p["trim"])
	_put(img, x + 2, y - 15, p["accent"])
	_box_fill(img, x - 6, y + 1, x + 5, y + 1, p["body_d"])


func _n_stone(img: Image, x: int, y: int, p: Dictionary) -> void:
	# a standing stone with a carved mark
	for k in range(13):
		var w := 3 if k < 10 else 2
		for dx in range(-w, w + 1):
			_put(img, x + dx, y - k, p["body_l"] if dx < 0 else (p["body"] if dx == 0 else p["body_d"]))
	_put(img, x, y - 7, p["accent"])
	_put(img, x, y - 8, p["accent_d"])
	_put(img, x - 1, y - 8, p["accent_d"])
	_box_fill(img, x - 6, y + 1, x + 6, y + 1, p["body_d"])


func _n_cache(img: Image, x: int, y: int, p: Dictionary) -> void:
	# a chest or crate, lid cracked
	_box_fill(img, x - 5, y - 5, x + 4, y, p["body"])
	_box_fill(img, x + 1, y - 5, x + 4, y, p["body_d"])
	_box_fill(img, x - 5, y - 7, x + 4, y - 6, p["trim"])
	_put(img, x - 1, y - 3, p["accent"])
	_put(img, x - 3, y - 8, p["accent_d"])
	_put(img, x + 2, y - 8, p["accent_d"])
	_box_fill(img, x - 7, y + 1, x + 6, y + 1, p["body_d"])


func _n_light(img: Image, x: int, y: int, p: Dictionary) -> void:
	# a post with a lantern or a lit window in a broken wall
	_box_fill(img, x - 6, y - 8, x - 3, y, p["body_d"])
	for k in range(12):
		_put(img, x + 1, y - k, p["body"])
	_box_fill(img, x, y - 15, x + 3, y - 12, p["body_d"])
	_box_fill(img, x + 1, y - 14, x + 2, y - 13, _c("amber") if p["accent"] != p["body_d"] else p["body_d"])
	_put(img, x + 1, y - 16, p["trim"])
	_box_fill(img, x - 7, y + 1, x + 5, y + 1, p["body_d"])


func _n_tree(img: Image, x: int, y: int, p: Dictionary) -> void:
	# a dead tree with things hanging from it
	var bark := _c("trunk_d")
	for k in range(14):
		_put(img, x, y - k, bark)
		_put(img, x + 1, y - k, _c("trunk"))
	for k in range(5):
		_put(img, x - 1 - k, y - 9 - k / 2, bark)
		_put(img, x + 2 + k, y - 11 - k / 2, bark)
	for hx in [-4, -2, 4, 6]:
		_put(img, x + hx, y - 9 + (hx & 1), p["accent"])
		_put(img, x + hx, y - 8 + (hx & 1), p["accent_d"])
	_box_fill(img, x - 4, y + 1, x + 5, y + 1, p["body_d"])


func _n_well(img: Image, x: int, y: int, p: Dictionary) -> void:
	# a low ring of stone with a crossbeam and rope
	_box_fill(img, x - 5, y - 3, x + 4, y, p["body"])
	_box_fill(img, x - 3, y - 3, x + 2, y - 2, _c("void_d"))
	for k in range(4, 11):
		_put(img, x - 5, y - k, p["trim"])
		_put(img, x + 4, y - k, p["trim"])
	_box_fill(img, x - 5, y - 11, x + 4, y - 11, p["body_l"])
	for k in range(4, 10):
		_put(img, x, y - k, _c("chain"))
	_put(img, x, y - 3, p["accent"])
	_box_fill(img, x - 7, y + 1, x + 6, y + 1, p["body_d"])


## The small mark that hangs over an unexamined notable.
var _glint_tex: ImageTexture
func glint_texture() -> ImageTexture:
	if _glint_tex == null:
		_glint_tex = _from_rows(["..c..", ".cWc.", "cWWWc", ".cWc.", "..c.."], {"c": Color("#4f9aa6"), "W": Color("#e6fbff")})
	return _glint_tex


var _dot_tex: ImageTexture
func dot_texture() -> ImageTexture:
	if _dot_tex == null:
		_dot_tex = _from_rows([".c.", "cdc", ".c."], {"c": Color("#3e5a60"), "d": Color("#6f9aa2")})
	return _dot_tex


## A ring of stones and a low fire: camp on the Way.
var _camp_tex: ImageTexture
func camp_texture() -> ImageTexture:
	if _camp_tex == null:
		var img := _new_image()
		var x := CENTER.x
		var y := CENTER.y + 2
		var stone := Color("#4a4452")
		var stone_d := Color("#2e2a36")
		for a in range(10):
			var ang := a * TAU / 10.0
			var px := x + roundi(cos(ang) * 5.0)
			var py := y + roundi(sin(ang) * 2.5)
			_put(img, px, py, stone if a < 5 else stone_d)
		for k in range(4):
			_put(img, x - 2 + k, y - 1 + (k & 1), Color("#3a2418"))
		_put(img, x, y - 2, Color("#e0803c"))
		_put(img, x - 1, y - 2, Color("#f0b050"))
		_put(img, x, y - 3, Color("#f0b050"))
		_put(img, x, y - 4, Color("#ffe6a8"))
		_put(img, x + 1, y - 3, Color("#e0803c"))
		# a bedroll
		for k in range(6):
			_put(img, x + 6 + k, y + 2, Color("#5a3f2e"))
			_put(img, x + 6 + k, y + 3, Color("#3f2c20"))
		_camp_tex = ImageTexture.create_from_image(img)
	return _camp_tex


## Trodden ground: the path the hero walks on the Way.
var _trail_tex: ImageTexture
func trail_texture() -> ImageTexture:
	if _trail_tex == null:
		var img := _new_image()
		# worn ash: paler than the ground around it, so the road reads in the dark
		var dk := Color("#7e7688")
		var mid := Color("#625a6c")
		var lt := Color("#9a92a4")
		for dy in range(-6, 7):
			for dx in range(-10, 11):
				if not Hex.in_top(dx, dy):
					continue
				var n := noise(dx, dy, 77)
				var band: int = abs(dy)
				if band <= 3 and n > 0.28:
					_put(img, CENTER.x + dx, CENTER.y + dy, dk if n > 0.62 else mid)
				elif band <= 4 and n > 0.6:
					_put(img, CENTER.x + dx, CENTER.y + dy, mid)
				elif band <= 5 and n > 0.93:
					_put(img, CENTER.x + dx, CENTER.y + dy, lt)
		_trail_tex = ImageTexture.create_from_image(img)
	return _trail_tex


## Ground and features combined, for the hand of tiles.
func icon(world_id: String, layout: String) -> ImageTexture:
	var key := "%s|%s" % [world_id, layout]
	if not _icon_cache.has(key):
		var img := _build_ground(world_id, 1)
		var f := _build_features(layout, 1)
		img.blend_rect(f, Rect2i(0, 0, TEX_W, TEX_H), Vector2i.ZERO)
		_icon_cache[key] = ImageTexture.create_from_image(img)
	return _icon_cache[key]


# ------------------------------------------------------------------ helpers
static func noise(x: int, y: int, s: int = 0) -> float:
	var n: int = (x * 374761393 + y * 668265263 + s * 2147483647) & 0xFFFFFFFF
	n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
	return float((n ^ (n >> 16)) & 0xFFFF) / 65535.0


func _new_image() -> Image:
	var img := Image.create_empty(TEX_W, TEX_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


func _put(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < TEX_W and y < TEX_H:
		img.set_pixel(x, y, c)


func _load_png(path: String) -> Image:
	if _png_cache.has(path):
		return _png_cache[path]
	var img: Image = null
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex:
			img = tex.get_image()
			if img.is_compressed():
				img.decompress()
			img.convert(Image.FORMAT_RGBA8)
	_png_cache[path] = img
	return img


# ------------------------------------------------------------------ ground
const DECOR := {
	"kingdom": [["l.l", ".l."], ["d"], ["l", "l"], ["h.", ".l"]],
	"eroded": [["lll"], ["d"], ["ll.", "..l"], ["h"]],
	"hollow": [["d.", "dd"], ["l"], [".d", "d."], ["ll"]],
	"frozen": [["h"], ["hh"], ["d.", ".d"], ["l.l"]],
}


func _build_ground(world_id: String, variant: int) -> Image:
	var p: Dictionary = Worlds.world(world_id)["pal"]
	var img := _new_image()
	var custom := _load_png("res://art/ground/%s.png" % world_id)
	var seed := variant * 97 + world_id.length()
	var mask := {}
	# top face
	for dy in range(-Hex.TOP_HEIGHT / 2 - 1, Hex.TOP_HEIGHT / 2 + 1):
		for dx in range(-Hex.WIDTH / 2 - 1, Hex.WIDTH / 2 + 2):
			if not Hex.in_top(dx, dy):
				continue
			var c: Color = p["base"]
			if custom:
				var sx := posmod(dx + Hex.WIDTH / 2 + variant * 7, custom.get_width())
				var sy := posmod(dy + Hex.TOP_HEIGHT / 2 + variant * 5, custom.get_height())
				c = custom.get_pixel(sx, sy)
			# only a faint rim: there is no sun, the real light comes from the pillar and lamps
			if not Hex.in_top(dx, dy - 1) or (not Hex.in_top(dx - 1, dy) and dy < 0):
				c = c.lerp(p["light"], 0.6) if custom else p["light"]
			elif not Hex.in_top(dx, dy + 1) or (not Hex.in_top(dx + 1, dy) and dy > 0):
				c = c.lerp(p["dark"], 0.75) if custom else p["dark"]
			_put(img, CENTER.x + dx, CENTER.y + dy, c)
			mask[Vector2i(dx, dy)] = true
	_underside(img, p, seed, mask)
	# outline around the whole silhouette
	var outline: Color = p["outline"]
	for key in mask.keys():
		for n in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = key + n
			if not mask.has(q):
				_put(img, CENTER.x + q.x, CENTER.y + q.y, outline)
	if not custom:
		_decor(img, world_id, p, seed)
	# damage that never heals: short cracks and a purple speck
	for i in range(4):
		var cx := int(noise(i, 41, seed) * 22) - 11
		var cy := int(noise(i, 42, seed) * 16) - 8
		if Hex.in_top(cx, cy) and Hex.in_top(cx + 2, cy + 1):
			_put(img, CENTER.x + cx, CENTER.y + cy, p["side3"])
			_put(img, CENTER.x + cx + 1, CENTER.y + cy + 1, p["side3"])
			if i < 2:
				_put(img, CENTER.x + cx + 2, CENTER.y + cy, Color("#5a3a72"))
	return img


## A jagged, blocky rock underside hanging below the top face. Deepest in the middle,
## darkest at the tip, with a faint violet underglow from the abyss on the last pixel.
func _underside(img: Image, p: Dictionary, seed: int, mask: Dictionary) -> void:
	var half := Hex.WIDTH / 2
	for dx in range(-half, half + 1):
		var bottom := -999
		for dy in range(Hex.TOP_HEIGHT / 2, -Hex.TOP_HEIGHT / 2 - 1, -1):
			if Hex.in_top(dx, dy):
				bottom = dy
				break
		if bottom == -999:
			continue
		var block := int(floor((dx + half) / 2.0))  # 2 px wide steps keep it blocky
		var t := 1.0 - absf(float(block * 2 - half + 1)) / float(half)
		var depth := 3 + int(t * 9.0 * (0.55 + 0.45 * noise(block, 7, seed))) + int(noise(block, 8, seed) * 2.0)
		for k in range(1, depth + 1):
			var y := bottom + k
			var f := float(k) / float(depth)
			var c: Color = p["side"]
			if f > 0.75:
				c = p["side3"]
			elif f > 0.35:
				c = p["side2"]
			if k == 1 and noise(dx, 9, seed) > 0.6:
				c = p["dark"]  # the broken lip of the top face
			if k == depth and depth > 5:
				c = c.lerp(Worlds.UNDERGLOW, 0.45)
			_put(img, CENTER.x + dx, CENTER.y + y, c)
			mask[Vector2i(dx, y)] = true


func _decor(img: Image, world_id: String, p: Dictionary, seed: int) -> void:
	var glyphs: Array = DECOR.get(world_id, [])
	if glyphs.is_empty():
		return
	var placed := 0
	for i in range(24):
		if placed >= 7:
			break
		var g: Array = glyphs[int(noise(i, 61, seed) * glyphs.size()) % glyphs.size()]
		var gx := int(noise(i, 62, seed) * 24) - 12
		var gy := int(noise(i, 63, seed) * 16) - 8
		var cells := []
		for b in range(g.size()):
			var row: String = g[b]
			for a in range(row.length()):
				if row[a] != ".":
					cells.append([gx + a, gy + b, row[a]])
		var ok := true
		for cell in cells:
			var a2: int = cell[0]
			var b2: int = cell[1]
			if not (Hex.in_top(a2, b2) and Hex.in_top(a2 + 1, b2) and Hex.in_top(a2 - 1, b2)
					and Hex.in_top(a2, b2 + 1) and Hex.in_top(a2, b2 - 1)):
				ok = false
				break
		if ok:
			for cell in cells:
				var key: String = {"l": "light", "d": "dark", "h": "hi"}[cell[2]]
				_put(img, CENTER.x + cell[0], CENTER.y + cell[1], p[key])
			placed += 1


# ------------------------------------------------------------------ features
func _build_features(layout: String, variant: int) -> Image:
	var img := _new_image()
	for f in Worlds.LAYOUTS.get(layout, []):
		var x: int = CENTER.x + int(f[1])
		var y: int = CENTER.y + int(f[2])
		var custom := _load_png("res://art/features/%s.png" % f[0])
		if custom:
			var pos := Vector2i(x - custom.get_width() / 2, y - custom.get_height() + 1)
			img.blend_rect(custom, Rect2i(Vector2i.ZERO, custom.get_size()), pos)
		else:
			call("_f_" + String(f[0]), img, x, y, variant)
	return img


func _c(name: String) -> Color:
	return Worlds.FEAT[name]


func _f_tree(img: Image, x: int, y: int, s: int) -> void:
	# a dead, leafless orchard tree: dark wood, a few crooked branches
	for k in range(6):
		_put(img, x, y - k, _c("trunk") if k < 4 else _c("trunk_l"))
		_put(img, x + 1, y - k, _c("trunk_d"))
	var lean := 1 if noise(x, y, s) > 0.5 else -1
	for k in range(1, 4):
		_put(img, x - k * lean, y - 5 - k, _c("trunk_l"))
		_put(img, x + 1 + k * lean, y - 3 - k, _c("trunk"))
	_put(img, x - 3 * lean, y - 9, _c("trunk_d"))
	_put(img, x, y - 7, _c("trunk_l"))
	_put(img, x + 2 * lean, y - 8, _c("trunk_d"))


func _f_dead_tree(img: Image, x: int, y: int, _s: int) -> void:
	for k in range(7):
		_put(img, x, y - k, _c("bone_d") if k < 3 else _c("bone"))
	for k in range(1, 4):
		_put(img, x - k, y - 4 - k, _c("bone"))
		_put(img, x + k, y - 3 - k, _c("bone"))
	_put(img, x - 1, y - 8, _c("bone"))
	_put(img, x + 2, y - 7, _c("bone_d"))


func _f_house(img: Image, x: int, y: int, _s: int) -> void:
	for dy in range(4):
		for dx in range(-3, 3):
			_put(img, x + dx, y - dy, _c("wall") if dx < 1 else _c("wall_d"))
	for r in range(3):
		for dx in range(-4 + r, 4 - r):
			_put(img, x + dx, y - 4 - r, _c("roof") if dx < 0 else _c("roof_d"))
	_put(img, x - 1, y, _c("door"))
	_put(img, x - 1, y - 1, _c("door"))
	_put(img, x + 1, y - 2, _c("window"))
	_put(img, x + 1, y - 1, _c("window_d"))


func _f_pillar(img: Image, x: int, y: int, _s: int) -> void:
	for dx in range(-4, 5):
		_put(img, x + dx, y, _c("marble_d"))
		_put(img, x + dx, y - 1, _c("marble"))
	for k in range(2, 22):
		for dx in range(-2, 3):
			var c := _c("marble") if dx < 1 else _c("marble_d")
			if k == 5 or k == 15:
				c = _c("gold") if dx < 1 else _c("gold_d")
			_put(img, x + dx, y - k, c)
	for dx in range(-3, 4):
		_put(img, x + dx, y - 22, _c("gold"))
	for k in [23, 24]:
		for dx in range(-1, 2):
			_put(img, x + dx, y - k, _c("glow2"))
	_put(img, x, y - 25, _c("glow2"))
	for g in [[-6, -8, "glow"], [6, -12, "glow"], [-5, -17, "glow2"], [5, -20, "glow2"], [-7, -13, "glow2"],
			[7, -5, "glow2"], [0, -29, "glow"], [-1, -27, "glow2"], [1, -27, "glow2"]]:
		_put(img, x + g[0], y + g[1], _c(g[2]))


func _f_ruin(img: Image, x: int, y: int, s: int) -> void:
	var segs := [[-6, 3], [-3, 5], [1, 2], [4, 4]]
	for i in range(segs.size()):
		var dx: int = segs[i][0]
		var h: int = maxi(1, segs[i][1] - int(noise(x, i, s) * 2))
		for k in range(h):
			_put(img, x + dx, y - k, _c("stone") if k < h - 1 else _c("stone_l"))
			_put(img, x + dx + 1, y - k, _c("stone_d"))
	for i in range(4):
		_put(img, x - 4 + i * 3, y + 2, _c("stone_d"))


func _f_rocks(img: Image, x: int, y: int, s: int) -> void:
	for i in range(3):
		var rx := x + int(noise(i, 9, s) * 16) - 8
		var ry := y + int(noise(i, 8, s) * 10) - 5
		_put(img, rx, ry, _c("stone_l"))
		_put(img, rx + 1, ry, _c("stone"))
		_put(img, rx, ry + 1, _c("stone"))
		_put(img, rx + 1, ry + 1, _c("stone_d"))


func _f_felled_tower(img: Image, x: int, y: int, _s: int) -> void:
	var ca := cos(-0.32)
	var sa := sin(-0.32)
	var length := 24
	for t in range(length):
		for w in range(5):
			if t > length - 4 and w > 4 - (length - t):
				continue
			var px := x + t * ca - w * sa
			var py := y + t * sa + w * ca * 0.6
			var c := _c("steel") if w > 0 else _c("steel_l")
			if w == 4:
				c = _c("steel_d")
			if (w == 1 or w == 3) and t % 3 == 1:
				c = _c("pane")
			if (t + w) % 7 == 0:
				c = _c("rust")
			_put(img, roundi(px), roundi(py), c)
	for k in range(5):
		_put(img, x - 1, y + k - 2, _c("steel_d"))


func _f_stump_tower(img: Image, x: int, y: int, s: int) -> void:
	for k in range(13):
		for dx in range(-3, 3):
			if k > 9 and noise(dx + 3, k, s) < 0.45:
				continue
			var c := _c("steel") if dx < 0 else _c("steel_d")
			if (dx == -2 or dx == 0) and k % 3 == 1 and k < 10:
				c = _c("pane_lit") if noise(dx + 9, k, s) > 0.85 else _c("pane")
			_put(img, x + dx, y - k, c)


func _f_dunes(img: Image, x: int, y: int, s: int) -> void:
	for row in [-6, 0, 6]:
		for dx in range(-10, 11):
			var yy: int = y + row + roundi(1.5 * sin((dx + s * 3) / 3.0))
			if Hex.in_top(dx, yy - CENTER.y) and noise(dx + 10, row + 6, s) > 0.2:
				_put(img, x + dx, yy, _c("sand_l"))


func _f_bones(img: Image, x: int, y: int, _s: int) -> void:
	for i in range(4):
		var bx := x - 5 + i * 3
		for k in range(5):
			_put(img, bx + (1 if k in [1, 2, 3] else 0), y - k, _c("bone") if k < 4 else _c("bone_d"))
	for dx in range(-6, 7):
		_put(img, x + dx, y + 1, _c("bone_d"))


func _f_ice(img: Image, x: int, y: int, s: int) -> void:
	var px := x - 8
	var py := y - 3
	for k in range(18):
		_put(img, px, py, _c("crack"))
		px += 1
		if noise(k, 1, s) > 0.6:
			py += 1
		elif noise(k, 2, s) > 0.7:
			py -= 1
	for i in range(8):
		var dx := int(noise(i, 3, s) * 18) - 9
		var dy := int(noise(i, 4, s) * 14) - 7
		if Hex.in_top(dx, dy):
			_put(img, x + dx, y + dy, _c("ice_l"))
			_put(img, x + dx + 1, y + dy, _c("ice_l"))


func _f_frozen_house(img: Image, x: int, y: int, _s: int) -> void:
	for dy in range(5):
		for dx in range(-4, 4):
			_put(img, x + dx, y - dy, _c("ice_d") if dx >= 1 else _c("ice_m"))
	for dx in range(-5, 5):
		_put(img, x + dx, y - 5, _c("ice_l"))
		_put(img, x + dx, y - 6, _c("ice_l") if absi(dx) < 4 else _c("ice_d"))
	_put(img, x - 2, y - 2, _c("sun"))


func _f_crypt(img: Image, x: int, y: int, _s: int) -> void:
	# a squat stone crypt with a sealed door
	for dy in range(6):
		for dx in range(-5, 5):
			_put(img, x + dx, y - dy, _c("stone") if dx < 1 else _c("stone_d"))
	for r in range(3):
		for dx in range(-6 + r, 6 - r):
			_put(img, x + dx, y - 6 - r, _c("stone_l") if dx < 0 else _c("stone"))
	for dy in range(4):
		_put(img, x - 1, y - dy, _c("door"))
		_put(img, x, y - dy, _c("door"))
	_put(img, x - 1, y - 2, _c("chain"))
	_put(img, x, y - 2, _c("chain_d"))


func _f_throne(img: Image, x: int, y: int, _s: int) -> void:
	# a broken marble throne under shards of colored window glass
	for dx in range(-4, 5):
		_put(img, x + dx, y, _c("marble_d"))
	for dy in range(1, 4):
		for dx in range(-3, 4):
			_put(img, x + dx, y - dy, _c("marble") if dx < 1 else _c("marble_d"))
	for dy in range(4, 11):
		for dx in range(-3, 4):
			if dy > 8 and dx > 0:
				continue  # the broken corner of the back
			_put(img, x + dx, y - dy, _c("marble") if dx < 0 else _c("marble_d"))
	_put(img, x - 3, y - 11, _c("gold"))
	_put(img, x, y - 11, _c("gold_d"))
	for g in [[-9, -6, "glass_a"], [-8, -5, "glass_c"], [7, -8, "glass_v"], [8, -7, "glass_a"], [6, -2, "glass_c"],
			[-7, 1, "glass_v"], [9, 2, "glass_a"]]:
		_put(img, x + g[0], y + g[1], _c(g[2]))


func _f_bunker(img: Image, x: int, y: int, _s: int) -> void:
	for dy in range(5):
		for dx in range(-6, 6):
			if dy == 4 and absi(dx) > 4:
				continue
			_put(img, x + dx, y - dy, _c("stone") if dx < 1 else _c("stone_d"))
	for dx in range(-2, 2):
		_put(img, x + dx, y - 2, _c("door"))
	_put(img, x + 3, y - 3, _c("pane"))
	_put(img, x - 4, y - 3, _c("pane"))


func _f_saloon(img: Image, x: int, y: int, _s: int) -> void:
	for dy in range(6):
		for dx in range(-5, 5):
			_put(img, x + dx, y - dy, _c("trunk_l") if dx < 1 else _c("trunk"))
	for dx in range(-6, 6):
		_put(img, x + dx, y - 6, _c("trunk_d"))
		_put(img, x + dx, y - 7, _c("canvas") if absi(dx) < 5 else _c("trunk_d"))
	for dx in [-3, 0, 3]:
		_put(img, x + dx, y - 3, _c("window"))
		_put(img, x + dx, y - 2, _c("window_d"))
	_put(img, x - 1, y, _c("door"))
	_put(img, x - 1, y - 1, _c("door"))


func _f_crates(img: Image, x: int, y: int, _s: int) -> void:
	for dy in range(3):
		for dx in range(-2, 2):
			_put(img, x + dx, y - dy, _c("canvas") if (dx + dy) % 2 == 0 else _c("canvas_d"))
	for dy in range(2):
		for dx in range(-1, 2):
			_put(img, x + dx + 1, y - 3 - dy, _c("canvas_d") if dy == 0 else _c("canvas"))


func _f_graves(img: Image, x: int, y: int, s: int) -> void:
	for i in range(4):
		var gx := x - 7 + i * 4 + int(noise(i, 5, s) * 2)
		var gy := y + int(noise(i, 6, s) * 3) - 1
		_put(img, gx, gy, _c("stone"))
		_put(img, gx, gy - 1, _c("stone_l"))
		_put(img, gx, gy - 2, _c("stone"))
		_put(img, gx + 1, gy, _c("stone_d"))
		_put(img, gx + 1, gy - 1, _c("stone_d"))


func _f_spike(img: Image, x: int, y: int, _s: int) -> void:
	for k in range(9):
		var w := maxi(0, 2 - k / 3)
		for dx in range(-w, w + 1):
			_put(img, x + dx, y - k, _c("ice_l") if dx <= 0 else _c("ice_m"))
	_put(img, x, y - 9, _c("ice_l"))


func _f_beacon(img: Image, x: int, y: int, _s: int) -> void:
	for dy in range(3):
		for dx in range(-3, 3):
			_put(img, x + dx, y - dy, _c("steel") if dx < 0 else _c("steel_d"))
	for k in range(3, 9):
		_put(img, x - 1, y - k, _c("steel_l"))
		_put(img, x, y - k, _c("steel"))
	_put(img, x - 1, y - 9, _c("sun"))
	_put(img, x, y - 9, _c("sun"))
	_put(img, x - 1, y - 10, _c("sun"))


func _f_plaza(img: Image, x: int, y: int, s: int) -> void:
	# cracked plaza tiles with a faint neon line
	for i in range(6):
		var px := x + int(noise(i, 11, s) * 20) - 10
		var py := y + int(noise(i, 12, s) * 14) - 7
		if Hex.in_top(px - x, py - y):
			_put(img, px, py, _c("stone_d"))
			_put(img, px + 1, py, _c("stone_d"))
	for dx in range(-6, 7):
		if Hex.in_top(dx, 2) and noise(dx + 6, 13, s) > 0.4:
			_put(img, x + dx, y + 2, _c("neon_d") if noise(dx, 14, s) > 0.3 else _c("neon_c"))


func _f_questboard(img: Image, x: int, y: int, _s: int) -> void:
	for k in range(7):
		_put(img, x - 4, y - k, _c("steel_d"))
		_put(img, x + 4, y - k, _c("steel_d"))
	for dy in range(2, 7):
		for dx in range(-3, 4):
			_put(img, x + dx, y - dy, _c("pane") if (dx + dy) % 3 else _c("neon_c"))
	for dx in range(-4, 5):
		_put(img, x + dx, y - 7, _c("steel"))
	_put(img, x - 2, y - 4, _c("neon_m"))


func _f_drone(img: Image, x: int, y: int, _s: int) -> void:
	for dx in range(-3, 4):
		_put(img, x + dx, y - 2, _c("steel"))
	for dx in range(-2, 3):
		_put(img, x + dx, y - 3, _c("steel_l"))
		_put(img, x + dx, y - 1, _c("steel_d"))
	_put(img, x, y - 2, _c("neon_c"))
	_put(img, x - 4, y - 1, _c("steel_d"))
	_put(img, x + 4, y, _c("steel_d"))


func _f_server(img: Image, x: int, y: int, s: int) -> void:
	for dy in range(10):
		for dx in range(-3, 3):
			_put(img, x + dx, y - dy, _c("steel_d") if dx < 0 else _c("steel"))
	for k in range(1, 10, 2):
		_put(img, x - 2, y - k, _c("neon_c") if noise(k, 17, s) > 0.6 else _c("pane"))
		_put(img, x + 1, y - k, _c("neon_m") if noise(k, 18, s) > 0.8 else _c("pane"))
	_put(img, x + 3, y, _c("cable"))
	_put(img, x + 4, y + 1, _c("cable"))


func _f_thorns(img: Image, x: int, y: int, s: int) -> void:
	for i in range(10):
		var px := x + int(noise(i, 21, s) * 22) - 11
		var py := y + int(noise(i, 22, s) * 14) - 7
		if Hex.in_top(px - x, py - y) and Hex.in_top(px - x + 2, py - y - 1):
			_put(img, px, py, _c("thorn"))
			_put(img, px + 1, py, _c("thorn_l"))
			_put(img, px + 2, py - 1, _c("thorn"))
			if i % 3 == 0:
				_put(img, px + 1, py - 1, _c("ember"))


func _f_cauldron(img: Image, x: int, y: int, _s: int) -> void:
	for dy in range(6):
		var w := 6 - absi(dy - 3) / 2
		for dx in range(-w, w + 1):
			_put(img, x + dx, y - dy, _c("iron") if dx < 1 else _c("steel_d"))
	for dx in range(-5, 6):
		_put(img, x + dx, y - 6, _c("iron_l"))
	for dx in range(-6, -2):
		_put(img, x + dx, y + 1, _c("thorn"))
	_put(img, x - 4, y - 1, _c("ember"))
	_put(img, x - 3, y - 2, _c("ember_l"))
	_put(img, x + 2, y - 4, _c("rust"))


func _f_hexstone(img: Image, x: int, y: int, _s: int) -> void:
	for k in range(8):
		_put(img, x, y - k, _c("stone"))
		_put(img, x + 1, y - k, _c("stone_d"))
		_put(img, x - 1, y - k, _c("stone_l") if k > 1 else _c("stone"))
	_put(img, x, y - 8, _c("stone_l"))
	_put(img, x, y - 5, _c("sigil"))
	_put(img, x, y - 3, _c("sigil"))
	_put(img, x - 1, y - 4, _c("sigil"))


func _f_trench(img: Image, x: int, y: int, s: int) -> void:
	for dx in range(-10, 11):
		var yy := y + roundi(sin((dx + s) / 4.0) * 1.5)
		if Hex.in_top(dx, yy - y):
			_put(img, x + dx, yy, _c("trunk_d"))
			_put(img, x + dx, yy + 1, _c("thorn"))
			if dx % 3 == 0:
				_put(img, x + dx, yy - 1, _c("thorn_l"))


func _f_mast(img: Image, x: int, y: int, _s: int) -> void:
	# the Engineer's anchor mast: a steel pylon with an amber light and cables staked into the ground
	for dx in range(-4, 5):
		_put(img, x + dx, y, _c("steel_d"))
	for k in range(1, 20):
		var w := 2 if k < 6 else 1
		for dx in range(-w, w + 1):
			_put(img, x + dx, y - k, _c("steel_l") if dx < 0 else _c("steel"))
	for k in [6, 12, 18]:
		for dx in range(-3, 4):
			_put(img, x + dx, y - k, _c("steel_d"))
	for k in range(20, 23):
		_put(img, x, y - k, _c("amber"))
		_put(img, x - 1, y - k, _c("ember"))
	_put(img, x, y - 23, _c("ember_l"))
	for t in range(1, 7):
		_put(img, x - 2 - t, y - 12 + t, _c("cable"))
		_put(img, x + 2 + t, y - 12 + t, _c("cable"))
	for g in [[-7, -2, "amber"], [8, -4, "amber"], [-9, -8, "ember"], [9, -10, "ember"], [0, -26, "ember_l"]]:
		_put(img, x + g[0], y + g[1], _c(g[2]))


func _f_grave(img: Image, x: int, y: int, _s: int) -> void:
	for dy in range(3):
		for dx in range(-3 + dy, 4 - dy):
			_put(img, x + dx, y - dy, _c("stone") if (dx + dy) % 2 else _c("stone_d"))
	_put(img, x, y - 3, _c("steel_d"))
	_put(img, x - 1, y - 3, _c("steel_d"))
	_put(img, x, y - 4, _c("neon_c"))


func _f_camp(img: Image, x: int, y: int, _s: int) -> void:
	for dy in range(5):
		for dx in range(-4 + dy, 5 - dy):
			_put(img, x + dx, y - dy, _c("canvas") if dx < 0 else _c("canvas_d"))
	_put(img, x, y - 1, _c("door"))
	_put(img, x, y, _c("door"))
	_put(img, x + 6, y, _c("ember"))
	_put(img, x + 7, y, _c("ember_l"))
	_put(img, x + 6, y - 1, _c("ember_l"))


func _f_cache(img: Image, x: int, y: int, _s: int) -> void:
	for dy in range(4):
		for dx in range(-4, 4):
			_put(img, x + dx, y - dy, _c("steel") if dx < 0 else _c("steel_d"))
	for dx in range(-4, 4):
		_put(img, x + dx, y - 4, _c("steel_l"))
	_put(img, x - 1, y - 2, _c("neon_c"))
	_put(img, x + 3, y - 1, _c("rust"))


func _f_pallas(img: Image, x: int, y: int, _s: int) -> void:
	# the station's core module: a hull drum half-buried, lit windows, a bent antenna
	for dy in range(10):
		var w := 9 if dy < 7 else 9 - (dy - 6) * 2
		for dx in range(-w, w + 1):
			_put(img, x + dx, y - dy, _c("hull") if dx < 0 else _c("hull_d"))
	for dx in range(-9, 10):
		if Hex.in_top(dx, 1):
			_put(img, x + dx, y + 1, _c("hull_d"))
	for dx in [-6, -3, 0, 3, 6]:
		_put(img, x + dx, y - 5, _c("window"))
		_put(img, x + dx, y - 4, _c("window_d"))
	for dx in range(-8, 9):
		_put(img, x + dx, y - 7, _c("hull_l"))
	for k in range(10, 17):
		_put(img, x + 4, y - k, _c("steel_l"))
	_put(img, x + 5, y - 17, _c("ember_l"))
	_put(img, x - 7, y - 9, _c("rust"))
	_put(img, x - 8, y - 8, _c("rust"))


func _f_hab(img: Image, x: int, y: int, _s: int) -> void:
	for dy in range(6):
		for dx in range(-5, 5):
			_put(img, x + dx, y - dy, _c("hull") if dx < 0 else _c("hull_d"))
	for dx in range(-5, 5):
		_put(img, x + dx, y - 6, _c("hull_l"))
	for dx in [-3, 1]:
		_put(img, x + dx, y - 3, _c("window"))
	_put(img, x - 1, y - 1, _c("door"))
	_put(img, x - 1, y, _c("door"))


func _f_tether(img: Image, x: int, y: int, _s: int) -> void:
	# a tether winch: a squat drum with cable running off into the ground
	for dy in range(4):
		for dx in range(-3, 3):
			_put(img, x + dx, y - dy, _c("steel") if dx < 0 else _c("steel_d"))
	for dx in range(-3, 3):
		_put(img, x + dx, y - 4, _c("steel_l"))
	for t in range(1, 9):
		_put(img, x + 3 + t, y - 2 + t / 2, _c("cable"))
	_put(img, x + 12, y + 2, _c("steel_d"))
	_put(img, x - 1, y - 2, _c("amber"))


# ------------------------------------------------------------------ overlays
func _make_outline(color: Color, dashed: bool) -> ImageTexture:
	var img := _new_image()
	for dy in range(-Hex.TOP_HEIGHT / 2 - 1, Hex.TOP_HEIGHT / 2 + 1):
		for dx in range(-Hex.WIDTH / 2 - 1, Hex.WIDTH / 2 + 1):
			if not Hex.in_top(dx, dy):
				continue
			var edge := not Hex.in_top(dx - 1, dy) or not Hex.in_top(dx + 1, dy) \
					or not Hex.in_top(dx, dy - 1) or not Hex.in_top(dx, dy + 1)
			if edge and (not dashed or (dx + dy) % 3 != 0):
				_put(img, CENTER.x + dx, CENTER.y + dy, color)
	return ImageTexture.create_from_image(img)


## The sky and abyss behind the map: no sun, dark violet cloud banks, a faint glow
## rising from the abyss below and a few distant drifting pieces of debris.
func make_void(w: int, h: int) -> ImageTexture:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var t := float(y) / float(h)
		for x in range(w):
			var c: Color = Worlds.VOID[0].lerp(Worlds.VOID[1], t)
			var band := sin(x / 37.0 + sin(y / 13.0) * 1.7) + sin((x + y * 2) / 61.0)
			if y < 150 and band > 1.2:
				c = Worlds.VOID[2]
			if y < 150 and band > 1.6:
				c = Worlds.VOID[3]
			var g := clampf((y - 120) / 150.0, 0.0, 1.0) * (0.6 + 0.4 * sin(x / 47.0))
			c = c.lerp(Worlds.VOID[4], g * 0.5)
			img.set_pixel(x, y, c)
	for i in range(26):
		var cx := noise(i, 1, 99) * w
		var cy := 10.0 + noise(i, 2, 99) * (h - 10)
		var r := 2.0 + noise(i, 3, 99) * 5.0
		for dy in range(-int(r), int(r * 1.6)):
			for dx in range(-int(r * 1.4), int(r * 1.4)):
				var inside := (dy < 0 and absf(dx) < r * 1.4 - absf(dy) * 0.3) or (dy >= 0 and absf(dx) < r * 1.4 * (1.0 - dy / (r * 1.6)))
				var px := int(cx) + dx
				var py := int(cy) + dy
				if inside and px >= 0 and py >= 0 and px < w and py < h:
					img.set_pixel(px, py, Color("#18121f") if dy < 0 else Color("#120d18"))
	return ImageTexture.create_from_image(img)


const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


static func _bayer(x: int, y: int) -> float:
	return (BAYER[(y % 4) * 4 + (x % 4)] + 0.5) / 16.0


# ------------------------------------------------------------------ sprites and icons
var _sprite_cache := {}


func _from_rows(rows: Array, cmap: Dictionary) -> ImageTexture:
	var h := rows.size()
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(h):
		var row: String = rows[y]
		for x in range(row.length()):
			if cmap.has(row[x]):
				img.set_pixel(x, y, cmap[row[x]])
	return ImageTexture.create_from_image(img)


## Any character sprite by name (art/characters/<name>.png overrides the placeholder).
func character(name: String) -> ImageTexture:
	if not _sprite_cache.has(name):
		var custom := _load_png("res://art/characters/%s.png" % name)
		if custom:
			_sprite_cache[name] = ImageTexture.create_from_image(custom)
		else:
			var art := CharArt.lookup(name)
			_sprite_cache[name] = _from_rows(art[0], art[1])
	return _sprite_cache[name]


## The active hero's map sprite and portrait.
func hero_texture(hero_id: String = "oracle") -> ImageTexture:
	return character(HeroState.HEROES[hero_id]["sprite"])


func portrait_texture(hero_id: String = "oracle") -> ImageTexture:
	return character(HeroState.HEROES[hero_id]["portrait"])


func afterimage_texture(boss: bool) -> ImageTexture:
	return character("enemy_afterimage_guard" if boss else "enemy_afterimage_echo")


func enemy_texture(enemy_id: String) -> ImageTexture:
	if Bestiary.data.has(enemy_id):
		return character(Bestiary.enemy(enemy_id)["sprite"])
	return character("enemy_restless_dead")


## A nearest-neighbor enlargement (whole-number scale) for the battle board.
func scaled(tex: Texture2D, factor: int) -> ImageTexture:
	var key := "%d|%d" % [tex.get_instance_id(), factor]
	if not _sprite_cache.has(key):
		var img := tex.get_image()
		img.resize(img.get_width() * factor, img.get_height() * factor, Image.INTERPOLATE_NEAREST)
		_sprite_cache[key] = ImageTexture.create_from_image(img)
	return _sprite_cache[key]


const ICON_ROWS := {
	"food": ["...g...", "..gGg..", ".yYyYy.", "yYyYyYy", ".yYyYy.", "..yYy..", "...y..."],
	"salvage": [".m.m.m.", "mMMMMMm", ".MkkkM.", "mMk.kMm", ".MkkkM.", "mMMMMMm", ".m.m.m."],
	"bone": ["b.....b", "bb...bb", ".bBBBb.", "..BBB..", ".bBBBb.", "bb...bb", "b.....b"],
	"sunstone": ["...o...", "..oOo..", ".oOYOo.", "oOYYYOo", ".oOYOo.", "..oOo..", "...o..."],
	"reagents": ["..ggg..", "...g...", "..gGg..", ".gGGGg.", "gGLGGGg", "gGGGLGg", ".ggggg."],
	"shards": ["...p...", "..pP...", "..pPp..", ".pPPp.p", ".pPPpPp", "pPPPPPp", ".ppppp."],
	"parts": ["..mMm..", ".M.k.M.", "mMkkkMm", ".M.k.M.", "..mMm..", "..mMm..", "...m..."],
	"power": ["....LL.", "...LL..", "..LLLL.", ".LLLL..", "...LL..", "..LL...", ".L....."],
}


func resource_icon(res: String) -> ImageTexture:
	var key := "icon_" + res
	if not _sprite_cache.has(key):
		var base: Color = Worlds.RESOURCE_COLORS[res]
		_sprite_cache[key] = _from_rows(ICON_ROWS[res], {
			"g": base.darkened(0.3), "G": base, "y": Color("#c9a54a"), "Y": Color("#e6c96a"),
			"m": Color("#5f6468"), "M": base, "k": Color("#3a3d40"), "b": base.darkened(0.25), "B": base,
			"o": Color("#9a5530"), "O": base, "L": base.lightened(0.5), "p": base.darkened(0.35), "P": base,
		})
	return _sprite_cache[key]


## A cyan marker for leads: fragments someone in town asked you to bring in.
func lead_marker_texture() -> ImageTexture:
	if not _sprite_cache.has("lead_marker"):
		_sprite_cache["lead_marker"] = _from_rows([
			"...c...", "..cCc..", ".cCWCc.", "cCWWWCc", ".cCWCc.", "..cCc..", "...c...",
		], {"c": Color("#2f7f8a"), "C": Color("#9fe0e6"), "W": Color("#e6fbff")})
	return _sprite_cache["lead_marker"]


## A small bobbing marker for glimpses in the fog.
func marker_texture() -> ImageTexture:
	if not _sprite_cache.has("marker"):
		_sprite_cache["marker"] = _from_rows([
			"...g...", "..gGg..", ".gG.Gg.", "gG...Gg", ".gG.Gg.", "..gGg..", "...g...",
		], {"g": Color("#c8782e"), "G": Color("#f0b050")})
	return _sprite_cache["marker"]
