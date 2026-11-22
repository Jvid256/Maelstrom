class_name Hex
extends RefCounted
## Hex grid math for flat-top hexes in "odd-q" offset layout.
##
## Tiles follow the style anchor: 32 px wide, 24 px top face, 4 px side face.
## Columns step 24 px, rows step 24 px, odd columns shift down 12 px.

const WIDTH := 32
const TOP_HEIGHT := 24
const SIDE := 4
const COL_STEP := 24
const ROW_STEP := 24

## Pixel position (map space) of a cell's center, relative to the grid origin.
static func to_pixel(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * COL_STEP, cell.y * ROW_STEP + (cell.x & 1) * (ROW_STEP / 2))


## Offset coordinates to cube coordinates (for distances).
static func to_cube(cell: Vector2i) -> Vector3i:
	var q := cell.x
	var r := cell.y - (cell.x - (cell.x & 1)) / 2
	return Vector3i(q, r, -q - r)


static func distance(a: Vector2i, b: Vector2i) -> int:
	var ca := to_cube(a)
	var cb := to_cube(b)
	return maxi(maxi(absi(ca.x - cb.x), absi(ca.y - cb.y)), absi(ca.z - cb.z))


## The six neighbors of a cell.
static func neighbors(cell: Vector2i) -> Array[Vector2i]:
	var odd := cell.x & 1
	var dirs: Array
	if odd == 1:
		dirs = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0)]
	else:
		dirs = [Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(-1, -1)]
	var out: Array[Vector2i] = []
	for d in dirs:
		out.append(cell + d)
	return out


## True if a pixel offset from the center lies on the hex's top face.
static func in_top(dx: float, dy: float) -> bool:
	var ax := absf(dx + 0.5)
	var ay := absf(dy + 0.5)
	return ay <= TOP_HEIGHT / 2.0 and ax <= WIDTH / 2.0 - (WIDTH / 4.0) * ay / (TOP_HEIGHT / 2.0)


## True if a pixel offset lies on the top face or the side face below it.
static func in_tile(dx: float, dy: float) -> bool:
	if in_top(dx, dy):
		return true
	if dy < 0:
		return false
	for k in range(1, SIDE + 1):
		if in_top(dx, dy - k):
			return true
	return false
