class_name Rules
extends RefCounted
## Combination rules. Each stabilized tile yields its world's resource, then neighbors
## change that through tag-based combinations, and the Book of Laws adds to worlds the
## Engineer has written down.
##
## Add a combination by adding an entry to COMBOS and a case in _apply().

const COMBOS := {
	"resonance": {"name": "Resonance", "text": "Same-world neighbors add +1 yield each (up to +2). Home land does not resonate."},
	"thaw_basin": {"name": "Thaw basin", "text": "Sand beside Ice: a seam of temperate ground, +2 Food per pair."},
	"rot_garden": {"name": "Rot garden", "text": "Decay beside Fertile land grows reagents, +1 per neighbor."},
	"clash": {"name": "Clash", "text": "Ice beside Decay: -1 Sunstone, but +1 rare Clash shard."},
	"echo": {"name": "Echo resonance", "text": "Two Great Wars side by side: Coven land beside Eroded Earth gives +1 Salvage and +1 Reagents."},
	"relay": {"name": "Signal relay", "text": "Signal beside Machine: the Leaderboard's land feeds +1 Power to the anchors."},
	"steam": {"name": "Steam vent", "text": "Fire beside Ice: +1 Power per pair, and the ice holds."},
	"glitch_garden": {"name": "Glitch garden", "text": "Neon beside Fertile land: +1 Parts and +1 Food, and something flickers."},
}

## A cell counts as land for its neighbors once it is shaped, settling or stable.
static func is_land(cell: Dictionary) -> bool:
	return cell.get("state", "") in ["stable", "settling", "shaped"]


## Yields of a single tile given its neighbors (used for expedition payouts).
static func tile_yields(pos: Vector2i, cells: Dictionary) -> Array:
	return _apply(pos, cells[pos], cells)


## Only settled land produces. Hero homes and story places don't.
static func produces(cell: Dictionary) -> bool:
	return cell.get("state", "") == "stable" and not cell.has("structure") and not cell.get("layout", "") in ["pillar", "mast", "pallas_core", "hall", "grave"]


## Returns { Vector2i: Array of {res, amt, combo, text} } for every producing cell.
static func evaluate(cells: Dictionary) -> Dictionary:
	var out := {}
	for pos in cells:
		var cell: Dictionary = cells[pos]
		if produces(cell):
			out[pos] = _apply(pos, cell, cells)
	return out


static func totals(breakdown: Dictionary) -> Dictionary:
	var sum := {}
	for r in Worlds.RESOURCES:
		sum[r] = 0
	for pos in breakdown:
		for e in breakdown[pos]:
			sum[e["res"]] += e["amt"]
	return sum


## Combos present anywhere in a breakdown.
static func combos_in(breakdown: Dictionary) -> Array:
	var found := []
	for pos in breakdown:
		for e in breakdown[pos]:
			if e["combo"] != "" and not found.has(e["combo"]):
				found.append(e["combo"])
	return found


static func _apply(pos: Vector2i, cell: Dictionary, cells: Dictionary) -> Array:
	var world_id: String = cell["world"]
	var my_tags: Array = Worlds.tags(world_id)
	var yield_res: String = Worlds.world(world_id)["yield"]
	var entries := [{"res": yield_res, "amt": 1, "combo": "", "text": "Base yield"}]
	var same := 0
	var count := {}
	for n in Hex.neighbors(pos):
		if not cells.has(n) or not is_land(cells[n]):
			continue
		var other: Dictionary = cells[n]
		if other["world"] == world_id:
			same += 1
		for t in Worlds.tags(other["world"]):
			count[t] = count.get(t, 0) + 1
		count["@" + other["world"]] = count.get("@" + other["world"], 0) + 1
	if same > 0 and world_id != "kingdom":
		entries.append({"res": yield_res, "amt": mini(same, 2), "combo": "resonance",
				"text": "Resonance (%d same-world neighbor%s)" % [same, "" if same == 1 else "s"]})
	if "Sand" in my_tags and count.get("Ice", 0) > 0:
		entries.append({"res": "food", "amt": 2 * mini(count["Ice"], 2), "combo": "thaw_basin", "text": "Thaw basin seam"})
	if "Decay" in my_tags and count.get("Fertile", 0) > 0:
		entries.append({"res": "reagents", "amt": mini(count["Fertile"], 2), "combo": "rot_garden", "text": "Rot garden"})
	if "Ice" in my_tags and count.get("Decay", 0) > 0:
		entries.append({"res": yield_res, "amt": -1, "combo": "clash", "text": "Clash with Decay"})
		entries.append({"res": "shards", "amt": 1, "combo": "clash", "text": "Clash shard"})
	if world_id == "coven" and count.get("@eroded", 0) > 0:
		entries.append({"res": "salvage", "amt": 1, "combo": "echo", "text": "Echo of two wars"})
		entries.append({"res": "reagents", "amt": 1, "combo": "echo", "text": "Echo of two wars"})
	if "Signal" in my_tags and count.get("Machine", 0) > 0:
		entries.append({"res": "power", "amt": 1, "combo": "relay", "text": "Signal relay"})
	if "Fire" in my_tags and count.get("Ice", 0) > 0:
		entries.append({"res": "power", "amt": mini(count["Ice"], 2), "combo": "steam", "text": "Steam vent"})
	if "Neon" in my_tags and count.get("Fertile", 0) > 0:
		entries.append({"res": "parts", "amt": 1, "combo": "glitch_garden", "text": "Glitch garden"})
		entries.append({"res": "food", "amt": 1, "combo": "glitch_garden", "text": "Glitch garden"})
	# the Book of Laws: written-down worlds give a little more
	if Story.law_known(world_id):
		entries.append({"res": yield_res, "amt": 1, "combo": "", "text": "Law of the %s" % Worlds.world(world_id)["name"]})
		if world_id == "leader":
			entries.append({"res": "power", "amt": 1, "combo": "", "text": "Law of the Leaderboard"})
	return entries
