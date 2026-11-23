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
		"text": "Someone stacked these stones to mark a path. ...But the path leads straight off the edge of the land?",
		"seen": "The cairn still points at the edge.", "effects": {"fs": 1}},
	{"id": "dropped_pack", "world": "any", "kind": "cache", "name": "A dropped pack",
		"text": "A canvas pack, half full. It was set down carefully, like its owner meant to come back for it. You take what's useful.",
		"seen": "The pack is still here, empty now.", "effects": {"res": {"salvage": 2}, "supplies": 1}},
	{"id": "ash_shape", "world": "any", "kind": "remains", "name": "A shape in the ash",
		"text": "The ash has settled around the outline of someone lying down. But there's nobody there.",
		"seen": "The outline in the ash hasn't filled in. ...It should have by now.", "effects": {"omen": "A shape in the ash where someone had been lying down. Nobody in it."}},
	{"id": "well", "world": "any", "kind": "well", "name": "A well with a rope",
		"text": "The rope goes down deeper than the land should go. You pull it up anyway. The bucket is full of clean, cold water. Refreshing!",
		"seen": "The well. Still cold, still clean, still too deep.", "effects": {"hp": 5}},
	{"id": "lantern_post", "world": "any", "kind": "light", "name": "A lantern on a post",
		"text": "The lantern is lit. There's no oil in it, and no wick. ...You warm your hands by it anyway.",
		"seen": "The lantern is still burning. Nobody tends it.", "effects": {"hp": 3, "fs": 1}},
	{"id": "marker_flag", "world": "any", "kind": "remains", "name": "A torn survey flag",
		"text": "An orange flag on a stake, stamped with Pallas markings. Someone from the station surveyed this ground... before the station ever fell here?",
		"seen": "The flag flaps in a wind you can't feel.", "effects": {"res": {"parts": 1}}},
	# lookouts: high places that show what's on the tiles around
	{"id": "lookout_stair", "world": "any", "kind": "stone", "name": "A broken stair to nowhere",
		"text": "A stone staircase climbs the side of a ruin and stops in midair. From the top step you can see a long way. You spot interesting places on the land nearby.",
		"seen": "The stair. You've already looked out from here.", "effects": {"reveal": 3}},
	{"id": "lookout_mast", "world": "eroded", "kind": "machine", "name": "A radio mast you could climb",
		"text": "Rusty rungs, but most of them hold. From the top, the dunes look like an ocean, and you can spot the places worth visiting.",
		"seen": "The mast. You've already climbed it.", "effects": {"reveal": 3}},
	{"id": "lookout_tower", "world": "leader", "kind": "machine", "name": "A spectator gantry",
		"text": "A camera platform, built so people at home could watch the plaza. The screens are dead, but from up here you can see everything nearby.",
		"seen": "The gantry. You've already looked out from it.", "effects": {"reveal": 3}},
	# ---- the Kingdom
	{"id": "orchard_bench", "world": "kingdom", "kind": "stone", "name": "A stone bench under dead trees",
		"text": "Two sets of initials carved inside a heart. One of them has been carefully scratched out. ...Someone took their time doing it.",
		"seen": "The bench. One set of initials, scratched out.", "effects": {"fs": 1}},
	{"id": "tithe_box", "world": "kingdom", "kind": "cache", "name": "A tithe box, unlocked",
		"text": "The king's seal is on the lid. Inside: coins nobody will ever spend, and a list of names in neat handwriting. ...Your name is on it.",
		"seen": "The tithe box. Your name is still on the list.", "effects": {"res": {"salvage": 3}, "omen": "A Kingdom tithe box with a list of names. {Name}'s was on it."}},
	{"id": "banner", "world": "kingdom", "kind": "remains", "name": "A banner in the mud",
		"text": "The royal colors, trampled into the mud. You can't just leave it there. You stand it up against a tree.",
		"seen": "The banner still leans against the tree.", "effects": {"fs": 1}},
	{"id": "kingdom_well", "world": "kingdom", "kind": "well", "name": "The village well",
		"text": "A bucket on a chain, and a painted sign: DO NOT DRINK. BY ORDER OF THE KING. ...The water smells fine. You fill a flask and pick some herbs growing nearby.",
		"seen": "The village well. You didn't drink. Probably.", "effects": {"res": {"food": 2}}},
	# ---- the Eroded Earth
	{"id": "fuel_drum", "world": "eroded", "kind": "cache", "name": "A fuel drum",
		"text": "A dented, sealed drum. Something sloshes inside. It isn't fuel anymore, but it's still worth taking.",
		"seen": "The drum lies on its side, empty.", "effects": {"res": {"salvage": 3}}},
	{"id": "billboard", "world": "eroded", "kind": "remains", "name": "A billboard face-down",
		"text": "You lift one corner. A smiling family, the words faded away. Underneath, someone lived here for a while. A bedroll, and a count of days scratched into the board. It stops at 412.",
		"seen": "The billboard. 412 days.", "effects": {"res": {"salvage": 1}, "omen": "A shelter under a fallen billboard. A tally of days that stops at 412."}},
	{"id": "dead_bike", "world": "eroded", "kind": "wreck", "name": "A motorbike in the dunes",
		"text": "Stripped down to the frame. The odometer still works... but it's counting in a unit you've never seen.",
		"seen": "The bike frame, half buried now.", "effects": {"res": {"parts": 1, "salvage": 1}}},
	{"id": "water_still", "world": "eroded", "kind": "machine", "name": "A solar still",
		"text": "Plastic sheeting and a cup. There's no sun to run it... but there's water in the cup anyway.",
		"seen": "The still. There's water in the cup again.", "effects": {"hp": 4}},
	# ---- the Hollowing
	{"id": "bone_chimes", "world": "hollow", "kind": "tree", "name": "Bone chimes in a dead tree",
		"text": "Finger bones strung on wire, ringing softly. ...There's no wind.",
		"seen": "The chimes go quiet whenever you come near.", "effects": {"res": {"bone": 2}, "fs": 1}},
	{"id": "open_grave", "world": "hollow", "kind": "stone", "name": "An open grave",
		"text": "This grave was dug from the inside. The dirt is piled neatly to one side. ...Whoever climbed out tidied up after themselves?",
		"seen": "Still open. Still tidy.", "effects": {"omen": "A grave dug out from inside, the dirt piled neatly."}},
	{"id": "mourners_cart", "world": "hollow", "kind": "wreck", "name": "A mourner's cart",
		"text": "A coffin on a two-wheeled cart. The lid is nailed shut with new nails. You don't open it. You take the supplies hanging from the cart and leave the rest.",
		"seen": "The cart. The lid is still nailed shut.", "effects": {"res": {"bone": 1, "reagents": 1}}},
	{"id": "ossuary_niche", "world": "hollow", "kind": "door", "name": "An ossuary niche",
		"text": "A wall of skulls, each with a name painted on its forehead. One skull is blank. ...It's waiting for someone.",
		"seen": "The blank skull is still blank. For now.", "effects": {"res": {"bone": 3}}},
	# ---- the Frozen Sun
	{"id": "ice_figure", "world": "frozen", "kind": "remains", "name": "A figure in the ice",
		"text": "A woman lies under the clear ice, eyes open, looking up at where the sun should be. She's holding a sunstone. You chip a few shards loose.",
		"seen": "She's still looking up.", "effects": {"res": {"sunstone": 2}}},
	{"id": "sun_dial", "world": "frozen", "kind": "stone", "name": "A sundial",
		"text": "The sundial casts a shadow. ...But there's no light to cast it.",
		"seen": "The sundial's shadow has moved since you were last here.", "effects": {"fs": 1, "omen": "A sundial in the dark, casting a shadow with no light to cast it."}},
	{"id": "heat_stone", "world": "frozen", "kind": "cache", "name": "A ring of warm stones",
		"text": "A ring of stones with no fire, still warm. Someone sat here and left in a hurry. You sit and warm up for a minute.",
		"seen": "The stones are cold now.", "effects": {"hp": 4, "res": {"sunstone": 1}}},
	{"id": "frozen_hall_door", "world": "frozen", "kind": "door", "name": "A door frozen shut",
		"text": "Through the ice, you can see inside the hall. The lamps are lit. ...But who lit them?",
		"seen": "The hall behind the ice is still lit.", "effects": {"res": {"sunstone": 1}}},
	# ---- the Leaderboard
	{"id": "loot_crate", "world": "leader", "kind": "cache", "name": "A loot crate",
		"text": "RARITY: COMMON. It opens with a triumphant fanfare. Nobody's around to hear it.",
		"seen": "The crate is open. Touch it, and the fanfare plays again.", "effects": {"res": {"parts": 2, "salvage": 1}}},
	{"id": "respawn_pad", "world": "leader", "kind": "machine", "name": "A respawn pad",
		"text": "A glowing disc set into the plaza. It flickers when you step on it, like it's checking for you. ...It doesn't find you.",
		"seen": "The pad flickers as you pass. Still checking.", "effects": {"hp": 3, "omen": "A respawn pad that checked for {name} and didn't find {him}."}},
	{"id": "scoreboard", "world": "leader", "kind": "machine", "name": "A scoreboard",
		"text": "Ten names. The top one has held first place for nine hundred days. The bottom one is new.",
		"seen": "The scoreboard. The bottom name changes every time.", "effects": {"xp": 4}},
	{"id": "dropped_drone", "world": "leader", "kind": "wreck", "name": "A crashed drone",
		"text": "A small drone with four rotors, one of them snapped. As you walk around it, its lens turns to follow you.",
		"seen": "The drone's lens still follows you.", "effects": {"res": {"parts": 2}, "omen": "A crashed drone whose lens followed {name} all the way around it."}},
	# ---- the Covens
	{"id": "witch_jar", "world": "coven", "kind": "cache", "name": "A sealed jar",
		"text": "A jar sealed with wax and a pressed sigil. Something inside moves when you tilt it! You take the reagents tied around its neck, and leave the jar alone.",
		"seen": "The jar is where you left it. ...Almost.", "effects": {"res": {"reagents": 2}}},
	{"id": "salt_circle", "world": "coven", "kind": "stone", "name": "A broken salt circle",
		"text": "A circle of salt, the kind used to trap something. It was broken... from the inside.",
		"seen": "The salt circle. Still broken.", "effects": {"fs": 1, "omen": "A circle of salt, broken from inside."}},
	{"id": "thorn_effigy", "world": "coven", "kind": "tree", "name": "A thorn effigy",
		"text": "Thorny vines bound into the shape of a person. About your height. About your build. ...Ow! It scratched you!",
		"seen": "The effigy is facing a different direction than before.", "effects": {"res": {"reagents": 1}, "hp": -2}},
	{"id": "herb_rack", "world": "coven", "kind": "cache", "name": "An herb rack",
		"text": "Bundles of herbs drying on a rack. You don't recognize most of them, but that one's feverfew. You take what you can use.",
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
				"text": "Only the roof sticks out of the sand. Through the sunroof, you see a child's car seat, a cooler, and a photo taped to the dashboard. A family on a beach, squinting into the sun.",
				"options": [
					{"label": "Take the photograph", "text": "You peel it off. On the back, in pencil: \"Next year, same beach.\"", "effects": {"res": {"salvage": 1}}},
					{"label": "Leave it where they put it", "text": "You leave it taped to the dashboard, where it belongs.", "effects": {"fs": 1}},
				]},
			{"name": "The car, dug open",
				"text": "Someone dug the car out while you were gone! The driver's door hangs open. Footprints, big and small, lead away toward the edge of the land.",
				"options": [
					{"label": "Follow the footprints", "text": "They lead right to the edge and stop. Something was dragged over. A child's shoe was left behind, laces still tied.", "effects": {"omen": "Someone dug out the family car and walked to the edge of the land. A child's shoe, laces tied."}},
					{"label": "Search the car", "text": "The cooler's gone. So is the photo. You salvage what's left.", "effects": {"res": {"salvage": 3}}},
				]},
			{"name": "A raft at the edge",
				"text": "At the edge of the land, there's a raft made from car doors and seat cushions. It points out into the void. A note is tied to its mast: WE WENT TO FIND THE BEACH.",
				"options": [
					{"label": "Push it off", "text": "It drifts out slowly, then faster, then it's gone. Where it sat, you find a sunstone carefully wrapped in a towel.", "effects": {"item": "beach_stone", "chronicle": "ruin_car"}},
					{"label": "Keep the note", "text": "You fold up the note and keep it. Under the raft's bench, wrapped in a towel, is a sunstone. ...They left it for whoever came next.", "effects": {"item": "beach_stone", "chronicle": "ruin_car", "fs": 1}},
				]},
		]},
	"the_chapel": {"world": ["kingdom", "hollow"], "needs": "", "kind": "door", "title": "The chapel with no bell",
		"stages": [
			{"name": "A chapel with an empty belfry",
				"text": "A small chapel with an empty bell tower. The bell rope still hangs inside, swinging back and forth. ...But there's no wind.",
				"options": [
					{"label": "Pull the rope", "text": "Nothing rings. But far below your feet, under the land, something does!", "effects": {"fs": 1, "omen": "A chapel with no bell. When the rope was pulled, something rang beneath the land."}},
					{"label": "Steady it", "text": "The rope stops in your hand. It's warm, like someone just let go of it.", "effects": {"hp": 2}},
				]},
			{"name": "The chapel, the floor broken through",
				"text": "The chapel floor has caved in since your last visit. The bell rope runs down through the hole, pulled tight. Something heavy is on the other end.",
				"options": [
					{"label": "Haul on the rope", "text": "It won't budge. Then something below tugs back, gently. Twice. And lets go.", "effects": {"omen": "Something under the chapel pulled back on the bell rope, twice, gently."}},
					{"label": "Lower a lantern", "text": "The light shows rough stone, upside down, under the land. A bell hangs there, mouth up, full of ash.", "effects": {"fs": 1}},
				]},
			{"name": "The bell beneath the land",
				"text": "Someone cut the rope. Through the hole, you can see the bell hanging under the land, mouth up. Where the ash was, something is shining.",
				"options": [
					{"label": "Climb down for it", "text": "You climb hand over hand along the bottom of the world. Inside the bell is a black iron clapper, warm and humming.", "effects": {"item": "chapel_clapper", "chronicle": "ruin_chapel", "hp": -3}},
					{"label": "Ring it from above", "text": "You drop a stone. The bell rings once, loud and clear. Back in town, every lamp flickers. When you look down again, the clapper is lying on the chapel floor.", "effects": {"item": "chapel_clapper", "chronicle": "ruin_chapel"}},
				]},
		]},
	"the_terminal": {"world": ["leader"], "needs": "hero:engineer", "kind": "machine", "title": "The last terminal",
		"stages": [
			{"name": "A terminal, still logged in",
				"text": "A public terminal on a dead plaza, still on and logged in. The screen reads: PLAYER 2, PRESS START.",
				"options": [
					{"label": "Press start", "text": "LOADING... It doesn't finish. It's still loading when you leave.", "effects": {"omen": "A terminal on a dead plaza, waiting for a second player. It began to load when we pressed start."}},
					{"label": "Log it out", "text": "LOG OUT? Y/N. You press Y. It just asks again. You pry a part off the casing and leave it asking.", "effects": {"res": {"parts": 1}}},
				]},
			{"name": "The terminal, loaded",
				"text": "It finished loading. The screen shows a high-score table with a hundred entries. Every one has the same name. The dates run from the day the world ended... to yesterday.",
				"options": [
					{"label": "Read the name", "text": "It's a username. The Engineer knows it. ...It's what the Player called himself!", "effects": {"omen": "A high-score table on a dead plaza: one name, a hundred times, the last entry dated yesterday. The Player's."}},
					{"label": "Look for a newer entry", "text": "Under the table, in small print: YOUR RANK: PENDING.", "effects": {"xp": 4}},
				]},
			{"name": "The terminal: SAVE FILE FOUND",
				"text": "SAVE FILE FOUND. LOAD? ...The file is dated tomorrow.",
				"options": [
					{"label": "Load it", "text": "The screen shows a map of your land, perfect down to the tile... plus a little more. Then it goes dark, and a data crystal slides out of a hidden slot.", "effects": {"item": "save_crystal", "chronicle": "ruin_terminal", "omen": "A save file dated tomorrow showed our land, and a little more than we hold."}},
					{"label": "Delete it", "text": "ARE YOU SURE? You are. The screen goes dark, and a blank data crystal slides out, still warm.", "effects": {"item": "save_crystal", "chronicle": "ruin_terminal"}},
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
		var seen := "Nothing more happens here." if int(n.get("stage", 0)) >= st["stages"].size() else "Nothing new yet. Come back in a day or two. Something will have changed."
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
