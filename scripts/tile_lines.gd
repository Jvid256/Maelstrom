extends Node
## Tile lines (autoload "TileLines"): the map speaks when you shape it. The first time each
## kind of land is laid down, a line about what it is. The first time two worlds touch, a
## line about what happens where they meet. Each is said once per run.

const FIRST := {
	"grove": "A dead orchard. The trees still lean toward where the sun used to be.",
	"town": "Empty streets, every door left open. ...Whoever lived here meant to be back before dark.",
	"ruin": "Old Kingdom stone, fallen in on itself. The Kingdom built things to last. They did. Nothing else did.",
	"dunes": "Sand dunes. They keep shifting, even here. ...Did the wind come along, too?",
	"dunes_tower": "The stump of a radio tower, still leaning toward a city that's gone.",
	"felled": "A skyscraper lying on its side. People lived in it, even after it fell.",
	"rocks_sand": "Rocks, sand, and a road sign with its name worn away.",
	"bunker": "A Coalition bunker, sealed from the inside. Nobody ever opened it from out here.",
	"saloon": "A saloon town. There's a piano inside. ...Someone's been tuning it?",
	"bones": "A field of bones, neatly sorted. Big ones here, small ones there. Someone had a lot of time.",
	"deadwood": "Trees made of bone. They grew this way after death ended in the Hollowing.",
	"rocks_ash": "Ash over rock, soft as snow but never cold. Footprints in it don't fill back in.",
	"graves": "A graveyard. The headstones all face inward, toward each other.",
	"crypt": "A sealed crypt. ...The seal is newer than the stone.",
	"ice": "A shelf of ice. Under it, the darkness goes deep.",
	"ice_house": "A house frozen in ice. There's a lamp lit in the window. ...But who lit it?",
	"spikes": "Spikes of ice, shaped like a crowd of people with their arms raised.",
	"beacon": "A dead beacon. It once guided ships to a harbor that froze over.",
	"plaza": "An empty plaza, built for crowds. The floor still lights up where you step.",
	"questboard": "A quest board. Every quest is still open. Every reward is still waiting.",
	"drone_field": "A field of crashed drones, lenses pointed up like flowers facing the sun.",
	"server": "A server rack, still warm. Something inside is still running.",
	"thorns": "A carpet of thorns, grown along the lines of an old battle plan.",
	"cauldron": "A war-cauldron, cold iron. The Covens brewed their wars in these.",
	"hexstone": "A hex stone. It hums whenever you look away from it.",
	"trench": "A thorn trench, still facing the enemy. The enemy's long gone. Nobody told the trench.",
}

## Two worlds meeting. Keys are the two world ids, sorted, joined with "+".
const MEETING := {
	"eroded+kingdom": "Kingdom stone meets Eroded sand. The sand gets into the mortar, and the stone starts to crumble.",
	"hollow+kingdom": "The Kingdom buried its dead. The Hollowing never had to. Where they meet, the graves are shallow.",
	"frozen+kingdom": "Frost creeps into the Kingdom's stone. The orchard trees turn white. ...That isn't blossom.",
	"kingdom+leader": "A neon plaza meets a royal road. The floor tiles flicker in the king's colors for a moment.",
	"coven+kingdom": "Coven thorns take root in Kingdom soil. They grow toward the pillar, like they want to climb it.",
	"eroded+hollow": "Sand drifts over the bone fields. Nothing new grows. It's oddly peaceful.",
	"eroded+frozen": "Hot sand meets frozen ground. A thin fog rises where they touch, and never clears.",
	"eroded+leader": "A scoreboard half-buried in the dunes, still counting a game nobody's playing.",
	"coven+eroded": "Thorns spread under the sand like veins. The dunes twitch, even without wind.",
	"frozen+hollow": "The dead meet the frozen. Where they touch, everything just... waits.",
	"hollow+leader": "Plaza lights flicker over the graves. A nearby scoreboard reads: RESPAWNING.",
	"coven+hollow": "Coven charms hang from trees of bone. Someone's trying to keep something in. ...Or out.",
	"frozen+leader": "Neon glows behind the ice. The quest notices are frozen mid-scroll.",
	"coven+frozen": "A war-cauldron, frozen solid. Whatever it was brewing is still inside, waiting for a thaw.",
	"coven+leader": "Hexes cast on circuits. The drones twitch in their sleep.",
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
