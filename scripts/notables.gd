extends Node
## Notables: the places on the Way worth stopping for. Every stretch of road holds one to
## three. A notable is either a full event (Events.EXPEDITION, with choices) or a find
## (below: a short scene and a small effect). The world tile remembers its notables and
## whether they've been examined, so the same ground is the same place next time.
##
## kind decides the art: wreck, remains, door, machine, stone, cache, light, tree, well.

## Events placed as notables: id -> [kind, what you see from the road].
const EVENT_LOOK := {
	"footprints": ["remains", "Fresh footprints in the ash"],
	"silhouette": ["remains", "A figure standing very still"],
	"driftwreck": ["wreck", "Wreckage that fell from somewhere"],
	"voice": ["stone", "A stone that seems to hum"],
	"drone_glint": ["light", "A glint above the fog"],
	"drone_tracks": ["remains", "Tracks too regular for an animal"],
	"drone_lens": ["machine", "Something clean in a dirty rack"],
	"buried_car": ["wreck", "A car, nose-down in the sand"],
	"radio": ["machine", "A radio mast, still warm"],
	"bunker_door": ["door", "A bunker door, half buried"],
	"lantern_window": ["light", "A lit window in a dead house"],
	"graves_names": ["stone", "A row of new headstones"],
	"crypt_knock": ["door", "A crypt door, closed from inside"],
	"frozen_crowd": ["remains", "A crowd, frozen mid-step"],
	"beacon_pulse": ["machine", "A beacon, pulsing"],
	"quest_popup": ["machine", "A notice board, glowing"],
	"server_hum": ["machine", "A server rack, humming"],
	"charm_tree": ["tree", "A tree hung with charms"],
	"cauldron_smoke": ["machine", "A cauldron, still smoking"],
	"kingdom_echo": ["stone", "A statue with a familiar face"],
}

## Finds: quick and small. once: only ever placed on one tile per run.
## seen: what the tooltip says once it has been examined.
const FINDS := [
	# ---- anywhere
	{"id": "cairn", "world": "any", "kind": "stone", "name": "A cairn of stacked stones",
		"text": "Someone stacked these to mark the way. The way they mark runs straight off the edge of the land.",
		"seen": "The cairn still points at the edge.", "effects": {"fs": 1}},
	{"id": "dropped_pack", "world": "any", "kind": "cache", "name": "A dropped pack",
		"text": "Canvas, half full. Whoever carried it set it down carefully, meaning to come back.",
		"seen": "The pack lies where it was, empty now.", "effects": {"res": {"salvage": 2}, "supplies": 1}},
	{"id": "ash_shape", "world": "any", "kind": "remains", "name": "A shape in the ash",
		"text": "The ash has settled around the shape of someone lying down. There's nobody in it.",
		"seen": "The shape in the ash hasn't filled in. It should have by now.", "effects": {"omen": "A shape in the ash where someone had been lying down. Nobody in it."}},
	{"id": "well", "world": "any", "kind": "well", "name": "A well with a rope",
		"text": "The rope goes down further than the land is deep. You haul it up anyway. The bucket is full of clean, cold water.",
		"seen": "The well. Still cold, still clean, still too deep.", "effects": {"hp": 5}},
	{"id": "lantern_post", "world": "any", "kind": "light", "name": "A lantern on a post",
		"text": "It's lit. There's no oil in it and no wick. You warm your hands at it anyway.",
		"seen": "The lantern is still lit. Nobody has tended it.", "effects": {"hp": 3, "fs": 1}},
	{"id": "marker_flag", "world": "any", "kind": "remains", "name": "A torn survey flag",
		"text": "Orange plastic on a stake, stamped with Pallas markings. Someone from the station surveyed this ground. Before the station fell here.",
		"seen": "The flag snaps in a wind you can't feel.", "effects": {"res": {"parts": 1}}},
	# lookouts: high places that show what's on the tiles around
	{"id": "lookout_stair", "world": "any", "kind": "stone", "name": "A broken stair to nowhere",
		"text": "A stone stair climbs the side of a ruin and stops in mid-air. From the top step you can see a long way: shapes in the fog on the pieces nearby, and which of them are worth the walk.",
		"seen": "The stair. You've already looked out from it.", "effects": {"reveal": 3}},
	{"id": "lookout_mast", "world": "eroded", "kind": "machine", "name": "A radio mast you could climb",
		"text": "Rusted rungs, most of them holding. From the top the dunes look like a sea, and the places worth going to stick up out of it.",
		"seen": "The mast. The view hasn't changed. Much.", "effects": {"reveal": 3}},
	{"id": "lookout_tower", "world": "leader", "kind": "machine", "name": "A spectator gantry",
		"text": "A camera gantry built so people at home could watch the plaza. The screens are dead, but from up here you can see what they used to show: everywhere nearby.",
		"seen": "The gantry. Still watching nothing.", "effects": {"reveal": 3}},
	# ---- the Kingdom
	{"id": "orchard_bench", "world": "kingdom", "kind": "stone", "name": "A stone bench under dead trees",
		"text": "Two sets of initials carved inside a heart. One of them has been scratched out, slowly and carefully, by someone who took their time.",
		"seen": "The bench. One set of initials, scratched out.", "effects": {"fs": 1}},
	{"id": "tithe_box", "world": "kingdom", "kind": "cache", "name": "A tithe box, unlocked",
		"text": "The king's seal on the lid. Inside, coins nobody will ever spend, and a list of names in a clerk's neat hand. Yours is on it.",
		"seen": "The tithe box. Your name is still on the list.", "effects": {"res": {"salvage": 3}, "omen": "A Kingdom tithe box with a list of names. {Name}'s was on it."}},
	{"id": "banner", "world": "kingdom", "kind": "remains", "name": "A banner in the mud",
		"text": "The royal colors, trampled into the mud. You don't pick it up, but you can't leave it lying there either. You stand it against a tree.",
		"seen": "The banner still leans against the tree.", "effects": {"fs": 1}},
	{"id": "kingdom_well", "world": "kingdom", "kind": "well", "name": "The village well",
		"text": "A bucket on a chain and a painted sign: DO NOT DRINK. BY ORDER OF THE KING. The water smells fine.",
		"seen": "The village well. You didn't drink. Probably.", "effects": {"res": {"food": 2}}},
	# ---- the Eroded Earth
	{"id": "fuel_drum", "world": "eroded", "kind": "cache", "name": "A fuel drum",
		"text": "Dented, sealed, sloshing. Whatever's inside isn't fuel any more, but it's worth carrying.",
		"seen": "The drum lies on its side, empty.", "effects": {"res": {"salvage": 3}}},
	{"id": "billboard", "world": "eroded", "kind": "remains", "name": "A billboard face-down",
		"text": "You lift a corner. A smiling family, the slogan bleached away. Underneath, someone lived for a while: a bedroll, and a tally of days scratched into the board. It stops at 412.",
		"seen": "The billboard. 412.", "effects": {"res": {"salvage": 1}, "omen": "A shelter under a fallen billboard. A tally of days that stops at 412."}},
	{"id": "dead_bike", "world": "eroded", "kind": "wreck", "name": "A motorbike in the dunes",
		"text": "Stripped to the frame. The odometer still works. It counts in a unit you've never seen.",
		"seen": "The bike frame, half buried now.", "effects": {"res": {"parts": 1, "salvage": 1}}},
	{"id": "water_still", "world": "eroded", "kind": "machine", "name": "A solar still",
		"text": "Plastic sheeting and a cup. There's no sun to run it. There's water in the cup anyway.",
		"seen": "The still. Water in the cup again.", "effects": {"hp": 4}},
	# ---- the Hollowing
	{"id": "bone_chimes", "world": "hollow", "kind": "tree", "name": "Bone chimes in a dead tree",
		"text": "Finger bones strung on wire. They're ringing. There's no wind.",
		"seen": "The chimes go quiet whenever you come near.", "effects": {"res": {"bone": 2}, "fs": 1}},
	{"id": "open_grave", "world": "hollow", "kind": "stone", "name": "An open grave",
		"text": "It was dug from the inside. The earth is piled neatly to one side, the way a person tidies up after themselves.",
		"seen": "Still open. Still tidy.", "effects": {"omen": "A grave dug out from inside, the dirt piled neatly."}},
	{"id": "mourners_cart", "world": "hollow", "kind": "wreck", "name": "A mourner's cart",
		"text": "A coffin on two wheels. The lid is nailed shut, and the nails are new. You don't open it. You take the lantern hanging from the shaft and leave the rest.",
		"seen": "The cart. The lid is still nailed shut.", "effects": {"res": {"bone": 1, "reagents": 1}}},
	{"id": "ossuary_niche", "world": "hollow", "kind": "door", "name": "An ossuary niche",
		"text": "A wall of skulls, each with a name painted on its brow. One brow is clean and blank. It's waiting for someone.",
		"seen": "The blank skull is still blank. For now.", "effects": {"res": {"bone": 3}}},
	# ---- the Frozen Sun
	{"id": "ice_figure", "world": "frozen", "kind": "remains", "name": "A figure in the ice",
		"text": "Under a hand's depth of clear ice, a woman lies with her eyes open, looking up at where the sun should be. In her hands, a sunstone.",
		"seen": "She's still looking up.", "effects": {"res": {"sunstone": 2}}},
	{"id": "sun_dial", "world": "frozen", "kind": "stone", "name": "A sundial",
		"text": "The gnomon casts a shadow. There's no light to cast it.",
		"seen": "The sundial's shadow has moved since you were here.", "effects": {"fs": 1, "omen": "A sundial in the dark, casting a shadow with no light to cast it."}},
	{"id": "heat_stone", "world": "frozen", "kind": "cache", "name": "A ring of warm stones",
		"text": "A ring of stones with no fire in it, still warm. Someone sat here and left in a hurry. You sit for a minute, too.",
		"seen": "The stones are cold now.", "effects": {"hp": 4, "res": {"sunstone": 1}}},
	{"id": "frozen_hall_door", "world": "frozen", "kind": "door", "name": "A door frozen shut",
		"text": "Through the ice you can see into the hall. The lamps are lit. You can't see who lit them.",
		"seen": "The hall behind the ice is still lit.", "effects": {"res": {"sunstone": 1}}},
	# ---- the Leaderboard
	{"id": "loot_crate", "world": "leader", "kind": "cache", "name": "A loot crate",
		"text": "RARITY: COMMON. It opens with a fanfare, played for nobody.",
		"seen": "The crate is open. Touch it and the fanfare plays again.", "effects": {"res": {"parts": 2, "salvage": 1}}},
	{"id": "respawn_pad", "world": "leader", "kind": "machine", "name": "A respawn pad",
		"text": "A disc of light set into the plaza. It flickers when you step on it, as if checking for you. It doesn't find you.",
		"seen": "The pad flickers as you pass. Still checking.", "effects": {"hp": 3, "omen": "A respawn pad that checked for {name} and didn't find {him}."}},
	{"id": "scoreboard", "world": "leader", "kind": "machine", "name": "A scoreboard",
		"text": "Ten names. The top one has held its place for nine hundred days. The bottom one is new.",
		"seen": "The scoreboard. The bottom name is different every time.", "effects": {"xp": 4}},
	{"id": "dropped_drone", "world": "leader", "kind": "wreck", "name": "A crashed drone",
		"text": "Small, four rotors, one snapped. Its lens turns to follow you as you walk around it.",
		"seen": "The drone's lens still follows you.", "effects": {"res": {"parts": 2}, "omen": "A crashed drone whose lens followed {name} all the way around it."}},
	# ---- the Covens
	{"id": "witch_jar", "world": "coven", "kind": "cache", "name": "A sealed jar",
		"text": "Wax over the lid, a sigil pressed into the wax. Something inside shifts when you tilt it. You take the reagents tied around its neck and leave the jar alone.",
		"seen": "The jar is where you left it. Almost.", "effects": {"res": {"reagents": 2}}},
	{"id": "salt_circle", "world": "coven", "kind": "stone", "name": "A broken salt circle",
		"text": "Broken from inside.",
		"seen": "The salt circle. Still broken.", "effects": {"fs": 1, "omen": "A circle of salt, broken from inside."}},
	{"id": "thorn_effigy", "world": "coven", "kind": "tree", "name": "A thorn effigy",
		"text": "Briars bound into the shape of a person. About your height. About your build.",
		"seen": "The effigy is facing a different way than before.", "effects": {"res": {"reagents": 1}, "hp": -2}},
	{"id": "herb_rack", "world": "coven", "kind": "cache", "name": "An herb rack",
		"text": "Bundles of herbs drying on a frame. Most you don't know. One is feverfew, which you do.",
		"seen": "The rack, picked over.", "effects": {"res": {"reagents": 2, "food": 1}}},
]

## Ruin stories: one place that changes between visits. Each stage is examined on a
## separate trip; after a stage the place goes quiet for a couple of days ("ready" again
## once the story has moved on without you). The last stage gives something to keep.
## Known on the world map like any notable, so a player can plan a route back to it.
const STORIES := {
	"the_car": {"world": ["eroded"], "needs": "", "kind": "wreck", "title": "The family car",
		"stages": [
			{"name": "A car buried to its roof",
				"text": "Only the roof shows above the sand. Through the sunroof: a child's seat, a cooler, a photograph taped to the dashboard. A family on a beach, squinting into a sun.",
				"options": [
					{"label": "Take the photograph", "text": "You peel it free. On the back, in pencil: 'next year, the same beach'.", "effects": {"res": {"salvage": 1}}},
					{"label": "Leave it where they put it", "text": "You leave it taped where they put it.", "effects": {"fs": 1}},
				]},
			{"name": "The car, dug open",
				"text": "Someone has dug the car out since you were here. The driver's door hangs open. Small footprints, and larger ones, lead away from it toward the edge of the land.",
				"options": [
					{"label": "Follow the footprints", "text": "They go to the very edge and stop. Something was dragged over the lip. A child's shoe, left behind, laces still tied.", "effects": {"omen": "Someone dug out the family car and walked to the edge of the land. A child's shoe, laces tied."}},
					{"label": "Search the car", "text": "The cooler's gone. The photograph's gone too, whether you took it or not.", "effects": {"res": {"salvage": 3}}},
				]},
			{"name": "A raft at the edge",
				"text": "At the edge, lashed together from car doors and seat foam: a raft. It points out into the void, toward nothing. Tied to the mast, a note: WE WENT TO FIND THE BEACH.",
				"options": [
					{"label": "Push it off", "text": "It drifts out, slowly, and then faster, and then it isn't there. Under where it sat: a sunstone, wrapped carefully in a towel.", "effects": {"item": "beach_stone", "chronicle": "ruin_car"}},
					{"label": "Keep the note", "text": "You fold the note and keep it. The raft stays. Under the bench, wrapped in a towel: a sunstone, left for whoever came next.", "effects": {"item": "beach_stone", "chronicle": "ruin_car", "fs": 1}},
				]},
		]},
	"the_chapel": {"world": ["kingdom", "hollow"], "needs": "", "kind": "door", "title": "The chapel with no bell",
		"stages": [
			{"name": "A chapel with an empty belfry",
				"text": "A little chapel, its belfry empty. The bell rope still hangs down inside, and it's swinging, though nobody has touched it and there's no wind.",
				"options": [
					{"label": "Pull the rope", "text": "Nothing rings. Far below your feet, under the land, something does.", "effects": {"fs": 1, "omen": "A chapel with no bell. When the rope was pulled, something rang beneath the land."}},
					{"label": "Steady it", "text": "It stops in your hand, and it's warm, as though someone let go of it just before you came in.", "effects": {"hp": 2}},
				]},
			{"name": "The chapel, the floor broken through",
				"text": "Since you were here, the chapel floor has broken through. The bell rope runs down through the hole, into the underside of the land, taut. Something on the other end is heavy.",
				"options": [
					{"label": "Haul on the rope", "text": "It doesn't come. Something below pulls back, gently, twice. Then lets go.", "effects": {"omen": "Something under the chapel pulled back on the bell rope, twice, gently."}},
					{"label": "Lower a lantern", "text": "The lantern lights stone underneath, rough and upside down. A bell hangs from it, mouth upward, full of ash.", "effects": {"fs": 1}},
				]},
			{"name": "The bell beneath the land",
				"text": "The rope has been cut. Through the hole in the floor you can see the bell hanging under the land, mouth up, and in it, where the ash was, something bright.",
				"options": [
					{"label": "Climb down for it", "text": "Hand over hand on the underside of the world. In the bell: a clapper of black iron, warm, humming one note.", "effects": {"item": "chapel_clapper", "chronicle": "ruin_chapel", "hp": -3}},
					{"label": "Ring it from above", "text": "You drop a stone. The bell rings once, clear, and every lamp in town flickers. When you look down again there's a clapper on the chapel floor.", "effects": {"item": "chapel_clapper", "chronicle": "ruin_chapel"}},
				]},
		]},
	"the_terminal": {"world": ["leader"], "needs": "hero:engineer", "kind": "machine", "title": "The last terminal",
		"stages": [
			{"name": "A terminal, still logged in",
				"text": "A public terminal on a dead plaza, still on, still logged in. The cursor blinks after a single line: PLAYER 2, PRESS START.",
				"options": [
					{"label": "Press start", "text": "LOADING. It doesn't finish. It's still loading when you leave.", "effects": {"omen": "A terminal on a dead plaza, waiting for a second player. It began to load when we pressed start."}},
					{"label": "Log it out", "text": "LOG OUT? Y/N. You press Y. It shows the question again. You leave it asking.", "effects": {"res": {"parts": 1}}},
				]},
			{"name": "The terminal, loaded",
				"text": "It finished loading. The screen shows a high-score table. Every one of the hundred entries has the same name, and the dates run from the day the world ended to yesterday.",
				"options": [
					{"label": "Read the name", "text": "It's a username, not a name. The Engineer would know it. It's what the Player called himself.", "effects": {"omen": "A high-score table on a dead plaza: one name, a hundred times, the last entry dated yesterday. The Player's."}},
					{"label": "Look for a newer entry", "text": "Under the table, in smaller type: YOUR RANK: PENDING.", "effects": {"xp": 4}},
				]},
			{"name": "The terminal: SAVE FILE FOUND",
				"text": "SAVE FILE FOUND. LOAD? The file's timestamp is tomorrow.",
				"options": [
					{"label": "Load it", "text": "The screen fills with a map of land you hold, accurate to the tile, and then a little more. It goes dark. A data crystal slides out of a slot you hadn't seen.", "effects": {"item": "save_crystal", "chronicle": "ruin_terminal", "omen": "A save file dated tomorrow showed our land, and a little more than we hold."}},
					{"label": "Delete it", "text": "ARE YOU SURE. You are. The screen goes dark and a data crystal slides out, wiped clean, still warm.", "effects": {"item": "save_crystal", "chronicle": "ruin_terminal"}},
				]},
		]},
}

const STORY_REST_DAYS := 2


var _finds_by_world := {}


func _ready() -> void:
	for f in FINDS:
		var w: String = f["world"]
		if not _finds_by_world.has(w):
			_finds_by_world[w] = []
		_finds_by_world[w].append(f)


## A story notable that went quiet wakes again once the story has moved on without you.
func wake_stories(cell: Dictionary, day: int) -> void:
	for n in cell.get("notables", []):
		if n["type"] == "story" and n["done"] and int(n.get("stage", 0)) < STORIES[n["id"]]["stages"].size() and day >= int(n.get("ready_day", 0)):
			n["done"] = false


func find(id: String) -> Dictionary:
	for f in FINDS:
		if f["id"] == id:
			return f
	return {}


## The notable as the road shows it: {kind, name, text?, seen?, event?}.
func look(n: Dictionary) -> Dictionary:
	if n["type"] == "story":
		var st: Dictionary = STORIES[n["id"]]
		var stage: int = mini(int(n.get("stage", 0)), st["stages"].size() - 1)
		var seen := "The story here has run its course." if int(n.get("stage", 0)) >= st["stages"].size() else "Quiet, for now. Come back in a day or two; it won't stay the same."
		return {"kind": st["kind"], "name": st["stages"][stage]["name"], "seen": seen, "story": st["title"]}
	if n["type"] == "event":
		var l: Array = EVENT_LOOK.get(n["id"], ["remains", "Something worth a look"])
		return {"kind": l[0], "name": l[1]}
	var f := find(n["id"])
	return {"kind": f.get("kind", "cache"), "name": f.get("name", "Something"), "seen": f.get("seen", "")}


## Rolls the notables a world cell holds, the first time the road crosses it.
## taken: ids already placed on other tiles (finds and once-events appear on one tile only).
func roll(cell: Dictionary, hero_id: String, rng: RandomNumberGenerator, taken: Dictionary) -> Array:
	var out := []
	# a ruin story takes root on the first fitting tile the road crosses
	for sid in STORIES:
		var sd: Dictionary = STORIES[sid]
		if taken.has(sid) or not sd["world"].has(cell["world"]) or not Story.met(sd["needs"]):
			continue
		if rng.randf() < 0.5:
			taken[sid] = true
			out.append({"type": "story", "id": sid, "stage": 0, "done": false, "ready_day": 0})
			return out
	var count := 1 + (1 if rng.randf() < 0.4 else 0)
	for i in range(count):
		if rng.randf() < 0.35:
			var e := Events.pick_expedition(cell, hero_id, rng)
			if not e.is_empty() and not (e.get("once", false) and taken.has(e["id"])):
				taken[e["id"]] = true
				out.append({"type": "event", "id": e["id"], "done": false})
				continue
		var all: Array = _finds_by_world.get(cell["world"], []) + _finds_by_world["any"]
		var pool: Array = all.filter(func(f): return not taken.has(f["id"]))
		if pool.is_empty():
			pool = all  # every find of this ground has been met once; now they can recur
		# a world's own finds come up twice as often as the generic ones
		var weighted := []
		for f in pool:
			weighted.append(f)
			if f["world"] != "any":
				weighted.append(f)
		var f: Dictionary = weighted[rng.randi_range(0, weighted.size() - 1)]
		taken[f["id"]] = true
		out.append({"type": "find", "id": f["id"], "done": false})
	return out
