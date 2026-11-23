extends Node
## Tile lines (autoload "TileLines"): the map speaks when you shape it. The first time each
## kind of land is laid down, a line about what it is. The first time two worlds touch, a
## line about what happens where they meet. Each is said once per run.

const FIRST := {
	"grove": "A dead orchard. The trees still remember which way the sun was.",
	"town": "Streets with no one in them, doors all open. Whoever left here meant to come back by dark.",
	"ruin": "Old stone, fallen inward. The Kingdom built to last. It lasted. Nothing else did.",
	"dunes": "Sand, drifting even here, as if the wind followed it across.",
	"dunes_tower": "The stump of a radio tower. It still leans toward a city that isn't there.",
	"felled": "A skytower lying on its side, floors stacked sideways like shelves. People lived in it, after it fell.",
	"rocks_sand": "Rock and sand and a road sign with the name sanded off.",
	"bunker": "A Coalition bunker, door sealed from the inside. Nobody ever opened it from the outside.",
	"saloon": "A saloon town. The piano is still in there. Something has been tuning it.",
	"bones": "A field of bones, sorted. Long ones here, small ones there. Somebody had time.",
	"deadwood": "Trees of bone, grown, not built. The Hollowing's orchards, after death ended.",
	"rocks_ash": "Ash over rock, soft as snow, never cold. Footprints in it don't fill in.",
	"graves": "A graveyard. The names face inward, toward each other, not toward the living.",
	"crypt": "A sealed crypt. The seal is newer than the stone.",
	"ice": "An ice shelf. Under it, the dark has depth.",
	"ice_house": "A frozen house, a lamp lit in the window behind the ice. Nobody to have lit it.",
	"spikes": "Ice spikes, grown in the shape of a crowd with its arms up.",
	"beacon": "A dead beacon, set to guide ships to a harbor that froze over.",
	"plaza": "A dead plaza, tiled for crowds. The floor still lights up where you step.",
	"questboard": "A quest board. Every notice is still open. Every reward is still waiting.",
	"drone_field": "A field of grounded drones, lenses up, like flowers turned toward a sun.",
	"server": "A server rack, warm. Something is still being kept, somewhere in there.",
	"thorns": "A mat of thorns, grown along the lines of a battle plan.",
	"cauldron": "A war-cauldron, cold iron. The Covens boiled their wars in these.",
	"hexstone": "A hex stone. It hums when you look away from it.",
	"trench": "A thorn trench. It still faces the enemy. The enemy is gone. The trench hasn't been told.",
}

## Two worlds meeting. Keys are the two world ids, sorted, joined with "+".
const MEETING := {
	"eroded+kingdom": "Kingdom stone against Eroded sand. The sand gets in the mortar and the mortar starts to give.",
	"hollow+kingdom": "The Kingdom buries its dead. The Hollowing never needed to. Where they touch, the graves are shallow.",
	"frozen+kingdom": "Frost creeps into the Kingdom's stone. The orchard trees bloom white, and it isn't blossom.",
	"kingdom+leader": "A neon plaza against a royal road. The tiles flicker the king's colors, then think better of it.",
	"coven+kingdom": "Coven thorns in Kingdom soil. They grow toward the pillar, as if they mean to climb it.",
	"eroded+hollow": "Sand drifts over the bone fields and nothing new grows. There's a kind of peace in it.",
	"eroded+frozen": "Hot sand, frozen ground. Where they meet, a thin fog that never lifts.",
	"eroded+leader": "A scoreboard half-sunk in dunes. Still counting a game nobody's playing.",
	"coven+eroded": "Thorns run under the sand like veins. The dunes twitch when the wind isn't blowing.",
	"frozen+hollow": "The dead and the frozen. Where they touch, everything waits, very patiently.",
	"hollow+leader": "The plaza lights flicker over the graves. Something on the leaderboard reads 'respawning'.",
	"coven+hollow": "Coven charms hang from bone trees. Somebody's trying to keep something in. Or out.",
	"frozen+leader": "Neon behind ice. The quest notices are frozen mid-scroll.",
	"coven+frozen": "A war-cauldron, frozen solid. Whatever it was brewing is still in there, waiting for a thaw.",
	"coven+leader": "Hexes cast on circuitry. The drones twitch in their sleep.",
}


func _seen() -> Array:
	if not Story.state.has("tile_lines"):
		Story.state["tile_lines"] = []
	return Story.state["tile_lines"]


## A line for land just shaped at pos, or "" if there's nothing new to say.
func line_for(pos: Vector2i, cells: Dictionary) -> String:
	var c: Dictionary = cells[pos]
	var key: String = "first:" + c["layout"]
	if FIRST.has(c["layout"]) and not _seen().has(key):
		_seen().append(key)
		return FIRST[c["layout"]]
	for n in Hex.neighbors(pos):
		if not cells.has(n) or cells[n]["state"] == "unstable":
			continue
		var w2: String = cells[n]["world"]
		if w2 == c["world"]:
			continue
		var pair := [c["world"], w2]
		pair.sort()
		var mk := "%s+%s" % pair
		if MEETING.has(mk) and not _seen().has("meet:" + mk):
			_seen().append("meet:" + mk)
			return MEETING[mk]
	return ""
