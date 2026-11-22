extends Node
## Source-world data: palettes, tags, yields and tile layouts.
## All colors come from style anchor v0.2: a sunless world, no grass, purple haze added by the screen shader.

const UNSTABLE_RAMP = [
	Color("#0e0b14"), Color("#17121f"), Color("#211a2c"),
	Color("#2e243c"), Color("#3d3050"), Color("#4e3f64"),
]
const DEEP := Color("#4a2a5e")
const FOG_LIGHT := Color("#1c1626")
const FOG_THICK := Color("#251c31")
## Sky top, sky low, cloud band, cloud band 2, abyss glow.
const VOID = [Color("#110c18"), Color("#26162e"), Color("#1a1424"), Color("#221a2e"), Color("#4a2a5e")]
const OUTLINE_UNSTABLE := Color("#0b0910")
const SETTLE := Color("#8f5a3a")
const SEAM := Color("#9fd6dc")
const UNDERGLOW := Color("#7a4a9a")
const ASH := Color("#8a80a0")

## Resources the game tracks. Power feeds the Engineer's anchors; parts feed Alysia's tethers.
const RESOURCES := ["food", "salvage", "bone", "sunstone", "reagents", "shards", "parts", "power"]
const RESOURCE_NAMES := {
	"food": "Food", "salvage": "Salvage", "bone": "Bone", "sunstone": "Sunstone",
	"reagents": "Reagents", "shards": "Clash shards", "parts": "Parts", "power": "Power",
}

## Each world's material: what repairing a structure on its ground costs, and what its
## structures are made of to the eye.
const MATERIAL := {"kingdom": "salvage", "eroded": "salvage", "hollow": "bone", "frozen": "sunstone", "leader": "parts", "coven": "reagents"}

## Resource icon colors.
const RESOURCE_COLORS := {
	"food": Color("#b89a62"), "salvage": Color("#90959a"), "bone": Color("#d6cfb6"),
	"sunstone": Color("#e0894a"), "reagents": Color("#9fe0a6"), "shards": Color("#b98ae0"),
	"parts": Color("#7fb0c8"), "power": Color("#f0d060"),
}

## Worlds whose tiles can be drawn into the hand, once discovered. The three starting
## worlds are always draftable; the Leaderboard and the Coven Wars open in chapter 2.
const BASE_DRAFTABLE := ["eroded", "hollow", "frozen"]

var data := {
	"kingdom": {
		"name": "Kingdom of Pillars",
		"tags": ["Fertile", "Stone", "Magic"],
		"yield": "food",
		"layouts": ["grove", "town", "ruin"],
		"pal": {
			"dark": Color("#353236"), "base": Color("#45414a"), "light": Color("#56515a"), "hi": Color("#6a6470"),
			"side": Color("#2a2630"), "side2": Color("#1d1a22"), "side3": Color("#121016"), "outline": Color("#0c0a0e"),
		},
	},
	"eroded": {
		"name": "The Eroded Earth",
		"tags": ["Sand", "Machine"],
		"yield": "salvage",
		"layouts": ["dunes", "dunes_tower", "felled", "rocks_sand", "bunker", "saloon"],
		"pal": {
			"dark": Color("#4e463a"), "base": Color("#655a48"), "light": Color("#7b6e57"), "hi": Color("#8e8168"),
			"side": Color("#4a3a2c"), "side2": Color("#33281f"), "side3": Color("#211a14"), "outline": Color("#140f0b"),
		},
	},
	"hollow": {
		"name": "The Hollowing",
		"tags": ["Decay", "Magic"],
		"yield": "bone",
		"layouts": ["bones", "deadwood", "rocks_ash", "graves", "crypt"],
		"pal": {
			"dark": Color("#34343a"), "base": Color("#44444a"), "light": Color("#56555a"), "hi": Color("#6a686c"),
			"side": Color("#28282e"), "side2": Color("#1c1c22"), "side3": Color("#121216"), "outline": Color("#0b0b0e"),
		},
	},
	"frozen": {
		"name": "The Frozen Sun",
		"tags": ["Ice", "Stone"],
		"yield": "sunstone",
		"layouts": ["ice", "ice_house", "spikes", "beacon"],
		"pal": {
			"dark": Color("#3f4a52"), "base": Color("#546270"), "light": Color("#6b7a86"), "hi": Color("#86939c"),
			"side": Color("#323a42"), "side2": Color("#252b31"), "side3": Color("#181c21"), "outline": Color("#0e1114"),
		},
	},
	"leader": {
		"name": "The Leaderboard",
		"tags": ["Machine", "Signal", "Neon"],
		"yield": "parts",
		"layouts": ["plaza", "questboard", "drone_field", "server"],
		"pal": {
			"dark": Color("#2e3038"), "base": Color("#3e4250"), "light": Color("#525866"), "hi": Color("#6a7080"),
			"side": Color("#24262e"), "side2": Color("#181a20"), "side3": Color("#101218"), "outline": Color("#0a0b10"),
		},
	},
	"coven": {
		"name": "The Coven Wars",
		"tags": ["Magic", "Fire", "Wild"],
		"yield": "reagents",
		"layouts": ["thorns", "cauldron", "hexstone", "trench"],
		"pal": {
			"dark": Color("#2e2a2c"), "base": Color("#3e3836"), "light": Color("#524a46"), "hi": Color("#665c56"),
			"side": Color("#241e1e"), "side2": Color("#181414"), "side3": Color("#100c0c"), "outline": Color("#0a0808"),
		},
	},
}

## Feature placements per layout: [feature, x offset, y offset] from the hex center.
const LAYOUTS := {
	# kingdom
	"pillar": [["pillar", 0, 4]],
	"town": [["house", -4, 2], ["house", 5, 5], ["tree", -9, 6]],
	"grove": [["tree", -6, 1], ["tree", 3, 4], ["tree", 7, -3], ["rocks", 0, 0]],
	"ruin": [["ruin", 0, 4], ["rocks", 0, 0]],
	"hall": [["throne", 0, 3], ["ruin", -2, 7]],
	# eroded
	"dunes": [["dunes", 0, 0]],
	"dunes_tower": [["dunes", 0, 0], ["stump_tower", 3, 3]],
	"felled": [["felled_tower", -11, -1]],
	"rocks_sand": [["rocks", 0, 0], ["dunes", 0, 0]],
	"bunker": [["bunker", 0, 4], ["dunes", 0, 0]],
	"saloon": [["saloon", -2, 4], ["crates", 7, 5]],
	# hollow
	"bones": [["bones", 0, 4], ["dead_tree", -7, 2]],
	"deadwood": [["dead_tree", -4, 3], ["dead_tree", 5, 1], ["dead_tree", 0, -3]],
	"rocks_ash": [["rocks", 0, 0], ["dead_tree", 6, 2]],
	"graves": [["graves", 0, 3], ["dead_tree", 7, 0]],
	"crypt": [["crypt", 0, 4], ["dead_tree", -8, 3]],
	# frozen
	"ice": [["ice", 0, 0]],
	"ice_house": [["ice", 0, 0], ["frozen_house", 2, 3]],
	"spikes": [["ice", 0, 0], ["spike", -5, 4], ["spike", 4, 1]],
	"beacon": [["ice", 0, 0], ["beacon", 1, 4]],
	# leaderboard
	"plaza": [["plaza", 0, 0]],
	"questboard": [["plaza", 0, 0], ["questboard", 0, 4]],
	"drone_field": [["plaza", 0, 0], ["drone", -5, 3], ["drone", 5, 0]],
	"server": [["plaza", 0, 0], ["server", 1, 4]],
	# coven
	"thorns": [["thorns", 0, 0]],
	"cauldron": [["thorns", 0, 0], ["cauldron", 0, 4]],
	"hexstone": [["hexstone", -3, 4], ["thorns", 0, 0]],
	"trench": [["trench", 0, 2]],
	# hero homes and story places
	"mast": [["mast", 0, 4]],                       # the Engineer's anchor mast
	"grave": [["grave", -2, 3], ["dead_tree", 6, 1]],  # the Augmented Player's grave
	"camp": [["camp", 0, 4], ["crates", -7, 3]],
	"cache": [["cache", 0, 4]],
	"pallas_core": [["pallas", 0, 5]],
	"pallas_hab": [["hab", 0, 4]],
	"pallas_dock": [["tether", 0, 4], ["crates", 6, 4]],
	"bare": [],
}

## Short names for tiles in the hand and the info panel.
const LAYOUT_NAMES := {
	"pillar": "The Pillar", "town": "Town", "grove": "Dead orchard", "ruin": "Ruin", "hall": "Throne hall",
	"dunes": "Sand dunes", "dunes_tower": "Tower stump", "felled": "Felled skytower", "rocks_sand": "Rocky sand",
	"bunker": "Coalition bunker", "saloon": "Saloon town",
	"bones": "Bone field", "deadwood": "Bone grove", "rocks_ash": "Ash rocks", "graves": "Graveyard", "crypt": "Sealed crypt",
	"ice": "Ice shelf", "ice_house": "Frozen house", "spikes": "Ice spikes", "beacon": "Dead beacon",
	"plaza": "Dead plaza", "questboard": "Quest board", "drone_field": "Drone field", "server": "Server rack",
	"thorns": "Thorn mat", "cauldron": "War-cauldron", "hexstone": "Hex stone", "trench": "Thorn trench",
	"mast": "Anchor mast", "grave": "The grave", "camp": "The camp", "cache": "Tech cache",
	"pallas_core": "Pallas: core", "pallas_hab": "Pallas: habitat", "pallas_dock": "Pallas: tether dock",
	"bare": "Bare ground",
}

## Feature colors used by the placeholder sprites.
const FEAT := {
	"trunk": Color("#3a2e26"), "trunk_l": Color("#5a4a3c"), "trunk_d": Color("#241c18"),
	"wall": Color("#6a6470"), "wall_d": Color("#4a4650"), "roof": Color("#2e2a36"), "roof_d": Color("#1e1a24"),
	"window": Color("#f0b050"), "window_d": Color("#c8782e"), "door": Color("#1a1420"),
	"marble": Color("#a8a4ae"), "marble_d": Color("#76727e"), "gold": Color("#8a7a4a"), "gold_d": Color("#6a5e3a"),
	"glow": Color("#e6fbff"), "glow2": Color("#9fd6dc"),
	"steel": Color("#46505c"), "steel_d": Color("#2f3640"), "steel_l": Color("#66727e"), "rust": Color("#6e4330"),
	"pane": Color("#1e2228"), "pane_lit": Color("#c8782e"), "sand_l": Color("#8e8168"),
	"bone": Color("#a9a79c"), "bone_d": Color("#7f7d74"),
	"ice_l": Color("#a2adb4"), "ice_d": Color("#323a42"), "ice_m": Color("#546270"), "crack": Color("#1e2328"),
	"sun": Color("#8a3a34"),
	"stone": Color("#55534f"), "stone_d": Color("#3a3a3e"), "stone_l": Color("#77736a"),
	"chain": Color("#8f5a3a"), "chain_d": Color("#6e4330"),
	"void_d": Color("#0c0a0e"), "ash_d": Color("#2a2630"),
	"glass_a": Color("#c8782e"), "glass_c": Color("#5fb8c4"), "glass_v": Color("#7a4a9a"),
	"neon_c": Color("#5fb8c4"), "neon_m": Color("#b85f92"), "neon_d": Color("#2a4a52"),
	"thorn": Color("#1a1416"), "thorn_l": Color("#2e2628"), "ember": Color("#c26a3c"), "ember_l": Color("#f0b050"),
	"sigil": Color("#8e7cb8"), "iron": Color("#3a3448"), "iron_l": Color("#6e6488"),
	"amber": Color("#f0b050"), "canvas": Color("#6e6a5e"), "canvas_d": Color("#4a4740"),
	"hull": Color("#5a6470"), "hull_d": Color("#3a424c"), "hull_l": Color("#7c8794"), "cable": Color("#8f5a3a"),
}


func world(id: String) -> Dictionary:
	return data[id]


func tags(id: String) -> Array:
	return data[id]["tags"]
