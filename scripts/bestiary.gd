extends Node
## Enemies (autoload "Bestiary"). Stats: hp, atk (per hit), spd (attacks per second in
## auto-combat), armor (flat damage reduction). Tags drive Alysia's ammo and some gear.
## Specials:
##   swift      1 in 3 hits against it miss
##   brittle    takes double damage from Bash in tactics; +50% from blunt tools
##   relentless never flees, +1 atk each time it is hit
##   shock      its hits also drain 1 Foresight / 1 charge
##   volley     attacks in bursts of 2 small hits
##   siphon     heals itself for half the damage it deals
## "tier" sets how deep in the fog it appears (0 near land, 2 far out) and the loot amount.

var data := {
	# ---- The Eroded Earth: raiders, drifters, machines
	"drifter": {"name": "Drifter", "world": "eroded", "tags": ["Human"], "hp": 10, "atk": 3, "spd": 1.0, "armor": 0,
		"tier": 0, "loot": "salvage", "special": "", "sprite": "enemy_drifter_raider",
		"text": "Someone who kept walking after the roads ran out."},
	"raider": {"name": "Drifter raider", "world": "eroded", "tags": ["Human"], "hp": 16, "atk": 5, "spd": 1.0, "armor": 0,
		"tier": 1, "loot": "salvage", "special": "", "sprite": "enemy_drifter_raider",
		"text": "Travels in packs, takes what the sand hasn't."},
	"reaver": {"name": "Dune reaver", "world": "eroded", "tags": ["Human", "Armored"], "hp": 24, "atk": 6, "spd": 0.8, "armor": 2,
		"tier": 2, "loot": "salvage", "special": "relentless", "sprite": "enemy_drifter_raider",
		"text": "Wears a car door for a breastplate and means it."},
	"sentry_bot": {"name": "Coalition sentry", "world": "eroded", "tags": ["Machine", "Armored"], "hp": 20, "atk": 5, "spd": 0.7, "armor": 2,
		"tier": 1, "loot": "parts", "special": "", "sprite": "enemy_sentry",
		"text": "Still guarding a bunker nobody will ever open again."},
	"sand_hound": {"name": "Sand hound", "world": "eroded", "tags": ["Beast"], "hp": 10, "atk": 3, "spd": 1.3, "armor": 0,
		"tier": 0, "loot": "food", "special": "swift", "sprite": "enemy_hound",
		"text": "Lean, fast, and used to eating things that fight back."},
	# ---- The Hollowing: the restless dead
	"restless": {"name": "Restless dead", "world": "hollow", "tags": ["Undead"], "hp": 18, "atk": 3, "spd": 0.8, "armor": 0,
		"tier": 0, "loot": "bone", "special": "brittle", "sprite": "enemy_restless_dead",
		"text": "It doesn't want anything. It just doesn't stop."},
	"gravewalker": {"name": "Gravewalker", "world": "hollow", "tags": ["Undead", "Armored"], "hp": 26, "atk": 5, "spd": 0.6, "armor": 2,
		"tier": 1, "loot": "bone", "special": "brittle", "sprite": "enemy_restless_dead",
		"text": "A knight who was buried in his armor, and came back in it."},
	"wisp": {"name": "Grave wisp", "world": "hollow", "tags": ["Spirit"], "hp": 9, "atk": 4, "spd": 1.3, "armor": 0,
		"tier": 0, "loot": "reagents", "special": "swift", "sprite": "enemy_wisp",
		"text": "A sickly green light that remembers being a person."},
	"bone_tyrant": {"name": "Bone tyrant", "world": "hollow", "tags": ["Undead"], "hp": 36, "atk": 7, "spd": 0.6, "armor": 1,
		"tier": 2, "loot": "bone", "special": "siphon", "sprite": "enemy_restless_dead",
		"text": "Nine hundred mages, one circle. This was one of the mages."},
	# ---- The Frozen Sun
	"frost_wraith": {"name": "Frost wraith", "world": "frozen", "tags": ["Spirit"], "hp": 12, "atk": 6, "spd": 0.7, "armor": 0,
		"tier": 0, "loot": "sunstone", "special": "shock", "sprite": "enemy_frost_wraith",
		"text": "The cold itself, wearing a torn coat."},
	"starving_wolf": {"name": "Starving wolf", "world": "frozen", "tags": ["Beast"], "hp": 14, "atk": 5, "spd": 1.2, "armor": 0,
		"tier": 1, "loot": "food", "special": "swift", "sprite": "enemy_hound",
		"text": "It hasn't eaten since the sun went out."},
	"ice_sentinel": {"name": "Ice sentinel", "world": "frozen", "tags": ["Spirit", "Armored"], "hp": 30, "atk": 6, "spd": 0.5, "armor": 3,
		"tier": 2, "loot": "sunstone", "special": "", "sprite": "enemy_frost_wraith",
		"text": "A statue of ice with something awake inside."},
	# ---- The Leaderboard
	"rogue_drone": {"name": "Rogue drone", "world": "leader", "tags": ["Machine"], "hp": 10, "atk": 3, "spd": 1.6, "armor": 0,
		"tier": 0, "loot": "parts", "special": "volley", "sprite": "enemy_drone",
		"text": "Still enforcing a quest nobody accepted."},
	"enforcer": {"name": "Quest enforcer", "world": "leader", "tags": ["Machine", "Armored"], "hp": 28, "atk": 6, "spd": 0.8, "armor": 2,
		"tier": 1, "loot": "parts", "special": "shock", "sprite": "enemy_sentry",
		"text": "YOU HAVE LEFT THE PLAY ZONE. RETURN TO THE PLAY ZONE."},
	"champion_echo": {"name": "Champion's echo", "world": "leader", "tags": ["Signal", "Spirit"], "hp": 34, "atk": 7, "spd": 1.0, "armor": 1,
		"tier": 2, "loot": "parts", "special": "swift", "sprite": "enemy_wisp",
		"text": "A top-ranked player, saved as a hologram, still playing."},
	# ---- The Coven Wars
	"hex_hound": {"name": "Hex hound", "world": "coven", "tags": ["Beast", "Magic"], "hp": 12, "atk": 4, "spd": 1.1, "armor": 0,
		"tier": 0, "loot": "reagents", "special": "swift", "sprite": "enemy_hound",
		"text": "Bred for the trenches, with sigils burned into its hide."},
	"hexed_soldier": {"name": "Hexed soldier", "world": "coven", "tags": ["Human", "Undead"], "hp": 20, "atk": 5, "spd": 0.9, "armor": 1,
		"tier": 1, "loot": "reagents", "special": "relentless", "sprite": "enemy_drifter_raider",
		"text": "Cursed to hold the line after the war ended."},
	"war_familiar": {"name": "War familiar", "world": "coven", "tags": ["Beast", "Magic", "Flying"], "hp": 30, "atk": 8, "spd": 0.8, "armor": 1,
		"tier": 2, "loot": "reagents", "special": "siphon", "sprite": "enemy_wisp",
		"text": "A coven's winged beast, still looking for its witch."},
	# ---- The Maelstrom's own: things that belong to no world. Found deep in the fog.
	"unmoored": {"name": "The Unmoored", "world": "maelstrom", "tags": ["Spirit", "Armored"], "hp": 40, "atk": 6, "spd": 0.6, "armor": 2,
		"tier": 2, "loot": "shards", "special": "relentless", "sprite": "enemy_unmoored",
		"text": "A knot of broken land with something inside it that wants to be whole again."},
	"driftwatcher": {"name": "Driftwatcher", "world": "maelstrom", "tags": ["Spirit"], "hp": 22, "atk": 5, "spd": 0.9, "armor": 0,
		"tier": 1, "loot": "shards", "special": "swift", "sprite": "enemy_wisp",
		"text": "It has no face. It has been watching the territory since before you noticed."},
	# ---- The Kingdom of Pillars: afterimages (story fights)
	"afterimage_echo": {"name": "Afterimage of a courtier", "world": "kingdom", "tags": ["Spirit"], "hp": 9, "atk": 3, "spd": 1.0, "armor": 0,
		"tier": 1, "loot": "food", "special": "", "sprite": "enemy_afterimage_echo",
		"text": "The last hour of a world, replaying."},
	"afterimage_guard": {"name": "Afterimage of the Royal Guard", "world": "kingdom", "tags": ["Spirit", "Armored"], "hp": 30, "atk": 6, "spd": 0.8, "armor": 1,
		"tier": 2, "loot": "food", "special": "", "sprite": "enemy_afterimage_guard",
		"text": "He guarded the chamber door. He still does."},
	# ---- The antagonists (story fights; not met in the fog)
	"armored_man": {"name": "The man in armor", "world": "", "tags": ["Human", "Armored", "Machine"], "hp": 70, "atk": 9, "spd": 0.8, "armor": 4,
		"tier": 3, "loot": "parts", "special": "relentless", "sprite": "enemy_armored_man",
		"text": "Advanced armor, no insignia. He came for the Player's technology."},
	"cyber_mastiff": {"name": "Cyborg mastiff", "world": "", "tags": ["Beast", "Machine", "Armored"], "hp": 50, "atk": 7, "spd": 1.4, "armor": 2,
		"tier": 3, "loot": "parts", "special": "swift", "sprite": "enemy_mastiff",
		"text": "Pony-sized, half steel. It isn't Keris. It isn't anyone's."},
}


func enemy(id: String) -> Dictionary:
	return data[id]


## Enemies that can appear in a world's fog at a given depth (tier <= depth).
func pool(world_id: String, depth: int) -> Array:
	var out := []
	for id in data:
		var e: Dictionary = data[id]
		if e["world"] == world_id and e["tier"] <= depth and e["tier"] < 3:
			out.append(id)
	if out.is_empty():
		out = ["drifter"]
	return out


## Worlds that have fog enemies.
func has_world(world_id: String) -> bool:
	for id in data:
		if data[id]["world"] == world_id and data[id]["tier"] < 3:
			return true
	return false
