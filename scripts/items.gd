extends Node
## Item data (autoload "Items"). Gear slots follow the design doc's table, plus a Weapon
## slot for the main hand. Stats an item can carry:
##   atk     damage per strike            armor   damage taken, flat reduction
##   hp      max health                   spd     attacks per second in auto-combat (+)
##   fs      max Foresight (Oracleborn)   dodge   Foresight dodges hits this much smaller
##   step    expedition step time (- is faster)   fog   encounter chance (- is fewer)
##   pack    extra fragment tiles carried home    supplies  healing draughts per expedition
##   hand    extra tiles in the starting hand     xp     bonus XP per fight (Engineer)
##   charge  energy pistol charge gained per fight (Alysia)   luck  item drop chance (+)
##   power   Power per day (Engineer)     parts   Parts per day (Alysia)
## "heroes": who can use it (missing = everyone). "weight": light/medium/heavy for body armor.

## Slot order on the hero screen: [id, name, group, heroes (empty = all)].
const SLOTS := [
	["weapon", "Weapon", "Combat", ["oracle", "engineer"]],
	["python", "Python", "Guns", ["gunslinger"]], ["glock", "Glock", "Guns", ["gunslinger"]],
	["energy", "Energy pistol", "Guns", ["gunslinger"]], ["ammo", "Ammo", "Guns", ["gunslinger"]],
	["offhand", "Off-hand", "Combat", ["oracle"]],
	["head", "Head", "Combat", []], ["body", "Body armor", "Combat", []], ["hands", "Hands", "Combat", []],
	["amulet", "Amulet", "Accessory", []], ["ring", "Ring", "Accessory", []], ["ring2", "Ring II", "Accessory", []],
	["charm", "Charm", "Accessory", []],
	["boots", "Boots", "Expedition", []], ["cloak", "Cloak", "Expedition", []], ["pack", "Pack", "Expedition", []],
	["belt", "Belt", "Expedition", []],
	["keepsake", "Keepsake", "Personal", []],
	["relic", "Relic", "Oracleborn", ["oracle"]],
	["implant", "Implant", "Engineer", ["engineer"]], ["implant2", "Implant II", "Engineer", ["engineer"]],
	["construct", "Construct", "Engineer", ["engineer"]], ["construct2", "Construct II", "Engineer", ["engineer"]],
]
## Slots that start locked; HeroState.unlocked tracks which have opened.
const LOCKED := {
	"ring2": "Opens through the story", "charm": "Opens when a world is fully read or its law is learned",
	"implant2": "Opens at level 4", "construct2": "Opens with the Constructs skill at rank 2",
}

const STAT_NAMES := {
	"atk": "Attack", "armor": "Armor", "hp": "Health", "spd": "Speed", "fs": "Foresight",
	"dodge": "Dodge", "step": "Step time", "fog": "Encounters", "pack": "Pack", "supplies": "Draughts",
	"hand": "Hand", "xp": "XP", "charge": "Charge", "luck": "Finds", "power": "Power/day", "parts": "Parts/day",
}

var data := {
	# ================================================================= the Oracleborn's start
	"short_sword": {"name": "Short sword", "slot": "weapon", "stats": {"atk": 5}, "heroes": ["oracle"],
		"text": "Notched, oiled, older than the town."},
	"round_shield": {"name": "Round shield", "slot": "offhand", "stats": {"armor": 1}, "heroes": ["oracle"],
		"text": "Wood rimmed in iron. He always carries it."},
	"worn_leathers": {"name": "Worn leathers", "slot": "body", "weight": "medium", "stats": {"armor": 1, "hp": 4},
		"text": "Patched so often little of the first armor is left."},
	"oracle_bead": {"name": "Mother's bead", "slot": "keepsake", "stats": {"fs": 1}, "heroes": ["oracle"],
		"text": "A bead of oracle glass from his homeworld. It still feels warm."},
	"canvas_pack": {"name": "Canvas pack", "slot": "pack", "stats": {},
		"text": "Carries a fragment of up to 3 tiles home."},
	# ================================================================= the Engineer's start
	"field_wrench": {"name": "Field wrench", "slot": "weapon", "stats": {"atk": 4}, "heroes": ["engineer"],
		"text": "Half a meter of alloy. Fixes things, or ends them."},
	"lab_coat": {"name": "Scorched lab coat", "slot": "body", "weight": "light", "stats": {"armor": 1, "hp": 3, "xp": 1},
		"heroes": ["engineer"], "text": "The sleeves are burned from the tower. He hasn't replaced it."},
	"tower_badge": {"name": "Tower access badge", "slot": "keepsake", "stats": {"xp": 2}, "heroes": ["engineer"],
		"text": "It opened every door in a building that no longer exists."},
	"swarm_seed": {"name": "Swarm seed", "slot": "implant", "stats": {"hp": 4, "regen": 1}, "heroes": ["engineer"],
		"text": "The bionic swarm the Player gave him. It heals, and it watches."},
	"turret_mk1": {"name": "Turret, mark I", "slot": "construct", "stats": {}, "heroes": ["engineer"],
		"construct": {"kind": "turret", "dmg": 3, "every": 1.3},
		"text": "Starts every fight beside him and fires on its own."},
	"tool_satchel": {"name": "Tool satchel", "slot": "pack", "stats": {}, "heroes": ["engineer"],
		"text": "Carries a fragment of up to 3 tiles home, with room for spare bolts."},
	"field_kit": {"name": "Field kit", "slot": "belt", "stats": {"supplies": 1}, "heroes": ["engineer"],
		"text": "Gauze, a flask, and the swarm does the rest."},
	# ================================================================= Alysia's start
	"python": {"name": "Colt Python", "slot": "python", "stats": {}, "heroes": ["gunslinger"],
		"gun": {"dmg": 9, "spd": 0.7, "name": "Python"},
		"text": "Her father's revolver. Slow, loud, and final."},
	"glock": {"name": "Glock 17", "slot": "glock", "stats": {}, "heroes": ["gunslinger"],
		"gun": {"dmg": 4, "spd": 1.6, "name": "Glock"},
		"text": "Seventeen quick answers to most questions."},
	"energy_pistol": {"name": "Energy pistol", "slot": "energy", "stats": {}, "heroes": ["gunslinger"],
		"gun": {"dmg": 14, "spd": 0.5, "name": "Energy pistol", "charge": 3},
		"text": "Builds a charge between fights. When it's full, nothing's armor matters."},
	"duster": {"name": "Riding duster", "slot": "body", "weight": "light", "stats": {"armor": 1, "hp": 2, "step": -0.05},
		"heroes": ["gunslinger"], "text": "Oiled canvas. Sand in every seam."},
	"keris_tag": {"name": "Keris's collar tag", "slot": "keepsake", "stats": {"spd": 0.1}, "heroes": ["gunslinger"],
		"text": "Her dog's tag. She reaches for it before every draw."},
	"saddlebag": {"name": "Saddlebag", "slot": "pack", "stats": {}, "heroes": ["gunslinger"],
		"text": "Carries a fragment of up to 3 tiles home."},
	# ================================================================= Eroded Earth drops
	"drifter_boots": {"name": "Drifter's boots", "slot": "boots", "world": "eroded", "stats": {"step": -0.15},
		"text": "Desert boots resoled with tire rubber. Faster across broken ground."},
	"rebar_blade": {"name": "Rebar blade", "slot": "weapon", "world": "eroded", "stats": {"atk": 7, "spd": -0.1},
		"heroes": ["oracle", "engineer"], "text": "Ground from a skytower's spine. Heavy, but it bites."},
	"dust_goggles": {"name": "Dust goggles", "slot": "head", "world": "eroded", "stats": {"fog": -0.03},
		"text": "You see trouble coming through the haze a little sooner."},
	"scrap_vest": {"name": "Scrap plate vest", "slot": "body", "weight": "medium", "world": "eroded", "stats": {"armor": 2, "spd": -0.1},
		"text": "Car-door steel riveted onto canvas."},
	"tower_plate": {"name": "Tower plate", "slot": "body", "weight": "heavy", "world": "eroded", "stats": {"armor": 4, "spd": -0.2},
		"text": "Too heavy for the Oracleborn or Alysia. The Engineer's swarm can carry it."},
	"salvage_pack": {"name": "Salvager's pack", "slot": "pack", "world": "eroded", "stats": {"pack": 1},
		"text": "Frame and straps from a Coalition rucksack. Brings home one more tile."},
	"fuel_belt": {"name": "Fuel-can belt", "slot": "belt", "world": "eroded", "stats": {"supplies": 2},
		"text": "Two flasks that once held fuel now hold draughts."},
	"drift_compass": {"name": "Drift compass", "slot": "charm", "world": "eroded", "stats": {"step": -0.1, "fog": -0.02},
		"text": "Its needle points at whatever is about to move."},
	"coalition_helmet": {"name": "Coalition helmet", "slot": "head", "world": "eroded", "stats": {"armor": 1, "hp": 2},
		"text": "Stenciled with a unit that no longer exists."},
	"ration_belt": {"name": "Ration belt", "slot": "belt", "world": "eroded", "stats": {"supplies": 1, "hp": 3},
		"text": "Government-issue. The rations are long gone; the flasks still work."},
	"sandwalker_cloak": {"name": "Sandwalker cloak", "slot": "cloak", "world": "eroded", "stats": {"fog": -0.03, "luck": 0.05},
		"text": "You find more and meet less."},
	# ================================================================= Hollowing drops
	"bone_ring": {"name": "Ring of knuckle bone", "slot": "ring", "world": "hollow", "stats": {"atk": 1},
		"text": "Someone's last grip, polished smooth."},
	"grave_salt": {"name": "Pouch of grave salt", "slot": "amulet", "world": "hollow", "stats": {"armor": 1, "fog": -0.02},
		"text": "The restless dead keep their distance from it."},
	"sexton_gloves": {"name": "Sexton's gloves", "slot": "hands", "world": "hollow", "stats": {"spd": 0.15},
		"text": "Thin black leather, made for quick, careful work."},
	"shroud_cloak": {"name": "Shroud cloak", "slot": "cloak", "world": "hollow", "stats": {"fog": -0.04},
		"text": "Grave linen. The fog seems to look past you."},
	"ossuary_shield": {"name": "Ossuary shield", "slot": "offhand", "world": "hollow", "stats": {"armor": 2, "spd": -0.05},
		"heroes": ["oracle"], "text": "Ribs bound over a cart wheel."},
	"rot_bloom": {"name": "Pressed rot bloom", "slot": "charm", "world": "hollow", "stats": {"atk": 1, "spd": 0.05},
		"text": "Smells sweet. Makes the heart beat a little faster."},
	"mourning_band": {"name": "Mourning band", "slot": "ring", "world": "hollow", "stats": {"hp": 4},
		"text": "Black iron. Worn by those who buried someone twice."},
	"tyrant_crown": {"name": "Tyrant's circlet", "slot": "head", "world": "hollow", "stats": {"atk": 2, "armor": -1},
		"text": "One of the nine hundred wore this into the circle."},
	# ================================================================= Frozen Sun drops
	"lamplighter_cloak": {"name": "Lamplighter's coat", "slot": "cloak", "world": "frozen", "stats": {"hp": 6, "fog": -0.02},
		"text": "Quilted against a cold that killed a world."},
	"rime_helm": {"name": "Rime-crusted helm", "slot": "head", "world": "frozen", "stats": {"armor": 1, "hp": 3},
		"text": "The frost on it never melts."},
	"sunstone_amulet": {"name": "Sunstone amulet", "slot": "amulet", "world": "frozen", "stats": {"hp": 5, "dodge": 1},
		"text": "Still holds a little of a dead sun's heat."},
	"ice_pick": {"name": "Ice pick", "slot": "weapon", "world": "frozen", "stats": {"atk": 4, "spd": 0.3},
		"heroes": ["oracle", "engineer"], "text": "Light and quick. Many small wounds."},
	"fur_gauntlets": {"name": "Fur-lined gauntlets", "slot": "hands", "world": "frozen", "stats": {"armor": 1, "atk": 1},
		"text": "Heavy cuffs, warm hands, firm grip."},
	"sled_belt": {"name": "Sled-hauler's belt", "slot": "belt", "world": "frozen", "stats": {"supplies": 1, "hp": 2},
		"text": "Wide leather with loops for flasks."},
	"snow_globe": {"name": "Glass snowflake", "slot": "charm", "world": "frozen", "stats": {"dodge": 1, "luck": 0.05},
		"text": "A single flake that never melted, sealed in glass."},
	"beacon_core": {"name": "Beacon core", "slot": "amulet", "world": "frozen", "stats": {"power": 1, "hp": 2},
		"text": "A dead heat beacon's heart. Still warm enough to feed an anchor."},
	# ================================================================= Leaderboard drops
	"player_visor": {"name": "Player's visor", "slot": "head", "world": "leader", "stats": {"xp": 2, "fog": -0.02},
		"text": "Shows quest markers for quests that ended with the world."},
	"signal_ring": {"name": "Signal ring", "slot": "ring", "world": "leader", "stats": {"power": 1},
		"text": "Hums when a server is still running somewhere."},
	"respawn_token": {"name": "Respawn token", "slot": "charm", "world": "leader", "stats": {"hp": 8},
		"text": "One more try. It never says how many are left."},
	"drone_shell": {"name": "Drone shell", "slot": "body", "weight": "medium", "world": "leader", "stats": {"armor": 2, "hp": 2},
		"text": "Hull plates from a rogue drone, bolted into a vest."},
	"circuit_gloves": {"name": "Circuit gloves", "slot": "hands", "world": "leader", "stats": {"spd": 0.1, "charge": 1},
		"text": "Conductive thread. Guns and tools feel quicker in them."},
	"loot_crate_pack": {"name": "Loot crate pack", "slot": "pack", "world": "leader", "stats": {"pack": 1, "luck": 0.05},
		"text": "Gold trim, lid ajar, and somehow always room for one more thing."},
	"turret_mk2": {"name": "Turret, mark II", "slot": "construct", "world": "leader", "stats": {}, "heroes": ["engineer"],
		"construct": {"kind": "turret", "dmg": 3, "every": 1.2},
		"text": "Rebuilt from enforcer parts. Hits harder, fires faster."},
	"shield_drone": {"name": "Shield drone", "slot": "construct", "world": "leader", "stats": {}, "heroes": ["engineer"],
		"construct": {"kind": "shield", "absorb": 8},
		"text": "Hovers at his shoulder and eats the first blows of a fight."},
	"spark_coil": {"name": "Spark coil", "slot": "construct", "world": "leader", "stats": {}, "heroes": ["engineer"],
		"construct": {"kind": "coil", "stun": 2.0},
		"text": "Stuns everything on the other side of the board as the fight opens."},
	"reflex_implant": {"name": "Reflex implant", "slot": "implant", "world": "leader", "stats": {"spd": 0.2, "dodge": 1}, "heroes": ["engineer"],
		"text": "The swarm wires itself into his nerves. He notices it, sometimes."},
	"plating_implant": {"name": "Subdermal plating", "slot": "implant", "world": "leader", "stats": {"armor": 2}, "heroes": ["engineer"],
		"text": "Alloy under the skin. The swarm grew it overnight."},
	# ================================================================= Coven Wars drops
	"hexwood_charm": {"name": "Hexwood charm", "slot": "charm", "world": "coven", "stats": {"armor": 1, "fog": -0.02},
		"text": "Ysolde's work, or someone like her. Soldiers on both sides wore these."},
	"witch_boots": {"name": "Witch's riding boots", "slot": "boots", "world": "coven", "stats": {"step": -0.2, "hp": -2},
		"text": "Made for a broom. They don't like the ground much."},
	"familiar_cloak": {"name": "Familiar-feather cloak", "slot": "cloak", "world": "coven", "stats": {"fog": -0.05, "dodge": 1},
		"text": "Feathers from a war familiar. Things in the fog take it for one of their own."},
	"ember_ring": {"name": "Ember ring", "slot": "ring", "world": "coven", "stats": {"atk": 2},
		"text": "Still warm from a war that ended a world."},
	"trench_coat": {"name": "Trench coat", "slot": "body", "weight": "medium", "world": "coven", "stats": {"armor": 2, "hp": 4, "spd": -0.05},
		"text": "Coven infantry issue, with sigils stitched into the lining."},
	"sigil_gauntlets": {"name": "Sigil gauntlets", "slot": "hands", "world": "coven", "stats": {"atk": 1, "fs": 1},
		"text": "The sigils flicker a second before something happens."},
	# ================================================================= Alysia's guns and ammo
	"python_longbarrel": {"name": "Python, long barrel", "slot": "python", "world": "eroded", "stats": {}, "heroes": ["gunslinger"],
		"gun": {"dmg": 11, "spd": 0.65, "name": "Python"},
		"text": "Arthur's work: a longer barrel and a tuned action."},
	"glock_extended": {"name": "Glock, extended mag", "slot": "glock", "world": "eroded", "stats": {}, "heroes": ["gunslinger"],
		"gun": {"dmg": 4, "spd": 1.9, "name": "Glock"},
		"text": "Louis found the magazine in a Coalition crate and couldn't resist."},
	"energy_overcharged": {"name": "Energy pistol, overcharged", "slot": "energy", "world": "leader", "stats": {}, "heroes": ["gunslinger"],
		"gun": {"dmg": 18, "spd": 0.5, "name": "Energy pistol", "charge": 3},
		"text": "Rewired with Leaderboard circuits. Arthur says it's safe. Louis says mostly."},
	"ammo_silver": {"name": "Silver rounds", "slot": "ammo", "stats": {}, "heroes": ["gunslinger"],
		"ammo": {"vs": ["Undead", "Spirit"], "mult": 1.6},
		"text": "The restless dead and the things in the fog hate silver. Works in both guns."},
	"ammo_ap": {"name": "Armor-piercing rounds", "slot": "ammo", "stats": {}, "heroes": ["gunslinger"],
		"ammo": {"vs": ["Armored"], "pierce": true},
		"text": "Coalition issue. Ignores armor."},
	"ammo_incendiary": {"name": "Incendiary rounds", "slot": "ammo", "stats": {}, "heroes": ["gunslinger"],
		"ammo": {"vs": ["Beast", "Wild", "Flying"], "mult": 1.5},
		"text": "Beasts don't like fire. Nothing does, but beasts least."},
	"ammo_gold": {"name": "Gold rounds", "slot": "ammo", "stats": {}, "heroes": ["gunslinger"],
		"ammo": {"vs": ["Machine", "Signal"], "mult": 1.6},
		"text": "Gold conducts. Machines come apart around it."},
	"quickdraw_rig": {"name": "Quick-draw rig", "slot": "belt", "world": "eroded", "stats": {"spd": 0.2, "supplies": 1}, "heroes": ["gunslinger"],
		"text": "Cross-draw holsters cut for her reach."},
	"miner_harness": {"name": "Pallas mining harness", "slot": "pack", "stats": {"pack": 1, "parts": 1}, "heroes": ["gunslinger"],
		"text": "Station issue. Carries one more tile, and the tether crews send her off with spare parts."},
	# ================================================================= Kingdom of Pillars (story)
	"oracle_glass": {"name": "Lens of oracle glass", "slot": "relic", "world": "kingdom", "stats": {"fs": 1, "dodge": 1}, "heroes": ["oracle"],
		"text": "Cut from the throne hall's window. Through it, the next few seconds are a little clearer."},
	"guard_signet": {"name": "Royal guard's signet", "slot": "ring", "world": "kingdom", "stats": {"atk": 2, "armor": 1},
		"text": "The afterimage left it behind when it faded."},
	# ================================================================= ruin stories
	"beach_stone": {"name": "Sunstone in a beach towel", "slot": "ring", "stats": {"hp": 3, "fs": 1},
		"text": "Left at the edge for whoever came next. It's warm the way sand is warm."},
	"chapel_clapper": {"name": "Black iron clapper", "slot": "ring", "stats": {"armor": 1, "atk": 1},
		"text": "From the bell hung under the land. It hums one note, very low, all the time."},
	"save_crystal": {"name": "Save crystal", "slot": "ring", "stats": {"xp": 3, "dodge": 1},
		"text": "Dated tomorrow. Holding it, you sometimes know what's about to happen a second before it does."},
	# ================================================================= story gifts
	"players_jacket": {"name": "The Player's jacket", "slot": "cloak", "stats": {"hp": 4, "xp": 2}, "heroes": ["engineer"],
		"text": "Too big for him. He wears it anyway."},
	"franklin_sidearm": {"name": "Franklin's service pistol", "slot": "glock", "stats": {}, "heroes": ["gunslinger"],
		"gun": {"dmg": 5, "spd": 1.5, "name": "Glock"},
		"text": "Kepler administrators are issued one. Franklin never fired his."},
}

## What can drop in each world's fog after an auto-battle or from a fragment.
const DROPS := {
	"eroded": ["drifter_boots", "rebar_blade", "dust_goggles", "scrap_vest", "tower_plate", "salvage_pack", "fuel_belt",
		"drift_compass", "coalition_helmet", "ration_belt", "sandwalker_cloak", "ammo_ap", "quickdraw_rig"],
	"hollow": ["bone_ring", "grave_salt", "sexton_gloves", "shroud_cloak", "ossuary_shield", "rot_bloom", "mourning_band",
		"tyrant_crown", "ammo_silver"],
	"frozen": ["rime_helm", "sunstone_amulet", "ice_pick", "fur_gauntlets", "sled_belt", "snow_globe", "beacon_core"],
	"leader": ["player_visor", "signal_ring", "respawn_token", "drone_shell", "circuit_gloves", "loot_crate_pack",
		"turret_mk2", "shield_drone", "spark_coil", "reflex_implant", "plating_implant", "ammo_gold"],
	"coven": ["hexwood_charm", "witch_boots", "familiar_cloak", "ember_ring", "trench_coat", "sigil_gauntlets", "ammo_incendiary"],
}

## Ysolde's workbench (the Oracleborn's town): item -> cost in resources.
const RECIPES := {
	"fuel_belt": {"salvage": 6, "food": 4},
	"sexton_gloves": {"bone": 5, "reagents": 2},
	"rime_helm": {"sunstone": 4, "salvage": 4},
	"grave_salt": {"bone": 6, "reagents": 3},
	"salvage_pack": {"salvage": 10, "bone": 4},
	"sunstone_amulet": {"sunstone": 8, "shards": 1},
	"hexwood_charm": {"reagents": 6, "bone": 3},
	"trench_coat": {"reagents": 5, "salvage": 6},
}

## The Engineer's workbench: blueprints studied from fugue builds.
const BLUEPRINTS := {
	"turret_mk2": {"parts": 8, "salvage": 6},
	"shield_drone": {"parts": 10, "sunstone": 3},
	"spark_coil": {"parts": 12, "shards": 1},
	"plating_implant": {"parts": 10, "bone": 4},
}

## Settlement upgrades, built on the town screen's Build tab. Cost scales with level.
## Structures: built on a stable tile of the territory. The tile stops yielding; the ground
## world beneath decides what the structure does (`ground`) and what it looks like.
##   hero     whose structure it is: buildable where that hero's land reaches
##   limit    how many may stand at once
##   needs    adjacency: "edge" (touches fog or void), "house", "signal" (mast or Leaderboard land)
##   fx       effects on any ground; `ground` adds per-world effects on top
##   repair   resource per unit of the ground world's material to fix damage (see Worlds.MATERIAL)
## Effect keys: glimpse, heal, fs, power, parts, food, reagents, construct_dmg, construct_fire,
## turret_fast, winch, mess, reading, lamp_slow.
const STRUCTURES := {
	"lamps": {"hero": "oracle", "name": "Sunstone lamps", "limit": 2, "needs": "edge",
		"cost": {"sunstone": 6, "salvage": 4},
		"text": "Lamps at the edge of the land push the fog back: one more glimpse shows through. They burn a Sunstone every other day; dark lamps show nothing.",
		"fx": {"glimpse": 1},
		"ground": {"frozen": {"lamp_slow": 1}, "hollow": {"fs": 1}},
		"ground_text": {"frozen": "Frozen Sun ground: the cold keeps the stone burning twice as long.", "hollow": "Hollowing ground: the dead keep their distance from light. +1 Foresight."}},
	"infirmary": {"hero": "oracle", "name": "Palisade and infirmary", "limit": 1, "needs": "house",
		"cost": {"salvage": 10, "bone": 6, "food": 6},
		"text": "Injuries heal on their own after a day at home. Wants a house beside it.",
		"fx": {"heal": 1},
		"ground": {"kingdom": {"food": 1}, "coven": {"reagents": 1}},
		"ground_text": {"kingdom": "Kingdom ground: an herb garden takes. +1 Food a day.", "coven": "Coven ground: the charm-makers' plants take. +1 Reagents a day."}},
	"shrine": {"hero": "oracle", "name": "Oracle's shrine", "limit": 1, "needs": "",
		"cost": {"reagents": 8, "shards": 1},
		"text": "A shrine of oracle glass. What it does depends on the ground it stands on. Beside a grave, it is asking for something.",
		"fx": {},
		"ground": {"kingdom": {"fs": 1}, "hollow": {"reading": 2}, "coven": {"reagents": 1}, "frozen": {"fs": 1}, "eroded": {"glimpse": 1}, "leader": {"fs": 1}},
		"ground_text": {"kingdom": "Kingdom ground: +1 Foresight.", "hollow": "Hollowing ground: the past is closer here. Readings need 2 fewer tiles.",
			"coven": "Coven ground: the glass sweats reagents. +1 a day.", "frozen": "Frozen Sun ground: the glass holds the last light. +1 Foresight.",
			"eroded": "Eroded Earth ground: the glass shows roads. +1 glimpse.", "leader": "Leaderboard ground: the glass flickers with the Documenter's interface. +1 Foresight."}},
	"capacitor": {"hero": "engineer", "name": "Capacitor bank", "limit": 3, "needs": "signal",
		"cost": {"parts": 6, "salvage": 5},
		"text": "+1 Power a day. Must touch the mast or Leaderboard land.",
		"fx": {"power": 1},
		"ground": {"leader": {"power": 1}},
		"ground_text": {"leader": "Leaderboard ground: the plaza was wired for this. +2 Power instead."}},
	"forge": {"hero": "engineer", "name": "Swarm forge", "limit": 1, "needs": "",
		"cost": {"parts": 10, "bone": 4, "reagents": 3},
		"text": "The swarm learns to grow alloy: constructs deal +1 damage. The ground decides the alloy.",
		"fx": {"construct_dmg": 1},
		"ground": {"eroded": {"parts": 1}, "coven": {"construct_fire": 1}, "leader": {"turret_fast": 1}},
		"ground_text": {"eroded": "Eroded Earth ground: scrap to spare. +1 Parts a day.", "coven": "Coven ground: the alloy runs hot. Constructs burn the Undead and Spirits.",
			"leader": "Leaderboard ground: turrets cycle a third faster."}},
	"winch": {"hero": "gunslinger", "name": "Tether winch", "limit": 1, "needs": "",
		"cost": {"parts": 10, "salvage": 8},
		"text": "A better winch: the first tile of every fragment costs no Part.",
		"fx": {"winch": 1},
		"ground": {"eroded": {"parts": 1}},
		"ground_text": {"eroded": "Eroded Earth ground: the old mining rigs give up their couplings. +1 Parts a day."}},
	"mess_hall": {"hero": "gunslinger", "name": "Mess hall", "limit": 1, "needs": "house",
		"cost": {"food": 15, "salvage": 5},
		"text": "Hot meals: survivors are twice as likely to join, rest costs half, and heroes in reach of it get a third action at camp. Wants a house beside it.",
		"fx": {"mess": 1},
		"ground": {"kingdom": {"food": 2}, "frozen": {"food": 1}},
		"ground_text": {"kingdom": "Kingdom ground: the orchard roots come back. +2 Food a day.", "frozen": "Frozen Sun ground: the cold keeps. +1 Food a day."}},
}

## Layouts a structure can never replace: homes and story places.
const UNBUILDABLE := ["pillar", "mast", "pallas_core", "pallas_hab", "pallas_dock", "grave", "camp", "cache", "hall"]

## Pallas: what Arthur and Louis sell or build, once the settlement is big enough.
const PALLAS_SHOP := {
	"ammo_silver": {"salvage": 5, "bone": 3},
	"ammo_ap": {"salvage": 6, "parts": 2},
	"ammo_incendiary": {"salvage": 5, "reagents": 2},
	"python_longbarrel": {"parts": 6, "salvage": 10},
	"glock_extended": {"parts": 4, "salvage": 8},
	"quickdraw_rig": {"salvage": 8, "parts": 2},
	"miner_harness": {"parts": 8, "salvage": 6},
}


func item(id: String) -> Dictionary:
	return data[id]


func slot_name(slot: String) -> String:
	for sl in SLOTS:
		if sl[0] == slot:
			return sl[1]
	return slot


## Slots this hero has.
func slots_for(hero_id: String) -> Array:
	var out := []
	for sl in SLOTS:
		if sl[3].is_empty() or sl[3].has(hero_id):
			out.append(sl)
	return out


func usable_by(id: String, hero_id: String) -> bool:
	var it: Dictionary = data[id]
	return not it.has("heroes") or it["heroes"].has(hero_id)


## One line describing an item's stats, e.g. "+2 Attack, +1 Armor".
func stat_text(id: String) -> String:
	var parts := []
	var it: Dictionary = data[id]
	var st: Dictionary = it["stats"]
	for k in st:
		var v = st[k]
		match k:
			"step":
				parts.append("%+.2fs %s" % [v, STAT_NAMES[k]])
			"fog", "luck":
				parts.append("%+d%% %s" % [roundi(v * 100), STAT_NAMES[k]])
			"spd":
				parts.append("%+.2f %s" % [v, STAT_NAMES[k]])
			_:
				parts.append("%+d %s" % [v, STAT_NAMES[k]])
	if it.has("gun"):
		var g: Dictionary = it["gun"]
		parts.append("%d damage, %.2f shots/s" % [g["dmg"], g["spd"]])
		if g.has("charge"):
			parts.append("needs %d charge" % g["charge"])
	if it.has("ammo"):
		var a: Dictionary = it["ammo"]
		parts.append(("ignores armor vs " if a.has("pierce") else "x%.1f vs " % a.get("mult", 1.0)) + ", ".join(a["vs"]))
	if it.has("construct"):
		var c: Dictionary = it["construct"]
		match c["kind"]:
			"turret":
				parts.append("turret: %d damage every %.1fs" % [c["dmg"], c["every"]])
			"shield":
				parts.append("absorbs the first %d damage" % c["absorb"])
			"coil":
				parts.append("stuns enemies for %.1fs" % c["stun"])
	var w: String = it.get("weight", "")
	if w != "":
		parts.append(w.capitalize())
	return ", ".join(parts) if parts else "No bonus"
