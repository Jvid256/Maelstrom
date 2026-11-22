extends Node
## Expedition and night events (autoload "Events"): short scenes with a choice, keyed to
## the land the hero is crossing or the day passing in town. The fog should never be
## merely quiet: things are found, watched, offered and lost.
##
## Expedition event fields:
##   where     a layout name, a world id, or "any"
##   needs     a Story condition (see Story.met); "" always
##   heroes    which heroes can get it (missing = all)
##   once      true: fires once per game
##   text      what the hero finds
##   options   2-3 choices: label, result text, and effects:
##       res {resource: amount}, hp (+/-), item id, fs (+Foresight), chronicle id, flag,
##       fight [enemy ids], people n, charge n, xp n, omen (adds to the Omens tab)

const EXPEDITION := [
	# ---- any land
	{"id": "footprints", "where": "any", "needs": "flag:ch1_done", "once": false,
		"text": "Footprints in the ash, fresh, too deep for a man of ordinary weight. They come up to the edge of your land and stop there, as if whoever made them stood a long while, looking in.",
		"options": [
			{"label": "Follow them back", "text": "They lead out into the fog and end in a trampled circle where something heavy waited. One clean print: a boot with a machined tread.",
				"effects": {"omen": "Heavy footprints with a machined tread, stopping at the edge of our land. Someone stood there looking in.", "res": {"salvage": 2}}},
			{"label": "Keep moving", "text": "You fix the shape of the tread in your memory. You'll know it again.", "effects": {"omen": "Footprints at the edge of our land, too deep for an ordinary man. We didn't follow them."}},
		]},
	{"id": "silhouette", "where": "any", "needs": "flag:ch2_done", "once": false,
		"text": "Out in the haze, a loose piece of land drifts slowly past. Someone is standing on it. Armored, still, facing you. Then the piece turns and the fog takes it.",
		"options": [
			{"label": "Watch until it's gone", "text": "It watched you back the whole way. You're certain of that.", "effects": {"omen": "An armored figure on a drifting piece of land, watching {name} until the fog took it.", "fs": 1}},
			{"label": "Look away", "text": "You don't give it the satisfaction. You also don't stop listening.", "effects": {}},
		]},
	{"id": "driftwreck", "where": "any", "needs": "", "once": false,
		"text": "A piece of land no bigger than a room drifts across the road: one dead tree, a cold firepit, a bedroll. Someone camped here once, on a world that isn't anywhere any more.",
		"options": [
			{"label": "Search the camp", "text": "A tin of food, a good knife, and a letter in a script nobody living can read.", "effects": {"res": {"food": 3, "salvage": 2}}},
			{"label": "Let it pass", "text": "It drifts on with the camp still made. It will be a long time before anyone else sees it.", "effects": {"fs": 1}},
		]},
	{"id": "voice", "where": "any", "needs": "", "once": true,
		"text": "A voice in the fog says your name. Not the name people here use: the one from before. It says it once, calmly, and waits.",
		"options": [
			{"label": "Answer", "text": "Nothing answers. But for a moment the fog thins, and you see much further than you should.", "effects": {"fs": 2, "chronicle": "omen_voice"}},
			{"label": "Say nothing", "text": "The fog closes. You walk faster, and you don't look back.", "effects": {"chronicle": "omen_voice"}},
		]},
	# ---- the drones. Rare, never explained in Act I. Something mechanical is watching the
	# points of interest, and has been since before the Engineer arrived.
	{"id": "drone_glint", "where": "any", "needs": "", "once": true, "rare": true,
		"text": "A point of light above the fog. Too steady for a star, too high for a bird. It holds its place while you cross the open ground, and then it doesn't.",
		"options": [
			{"label": "Watch it", "text": "It didn't drift with the land. Everything out here drifts with the land.", "effects": {"omen": "A light above the fog that held still while the land moved under it."}},
			{"label": "Keep your head down", "text": "You feel it between your shoulders anyway, until a rise in the ground cuts it off.", "effects": {"fs": 1}},
		]},
	{"id": "drone_tracks", "where": "any", "needs": "flag:ch1_done", "once": true, "rare": true,
		"text": "Tracks in the ash, but not footprints: three small points in a triangle, repeated at exactly the same spacing, in a dead-straight line from nowhere to nowhere.",
		"options": [
			{"label": "Follow them", "text": "They end at a patch of warm ground. Nothing is there now. Something was, not long ago.", "effects": {"omen": "Three-point tracks, perfectly regular, ending at warm ground.", "res": {"salvage": 1}}},
			{"label": "Scuff them out", "text": "It feels like the right thing to do. You couldn't say who you did it for.", "effects": {}},
		]},
	{"id": "drone_lens", "where": "server", "needs": "", "once": true, "rare": true,
		"text": "In the rack, something that isn't part of the rack: a lens no bigger than a thumbnail, clean where everything else is dust. It's pointed at the road you just walked.",
		"options": [
			{"label": "Take it", "text": "It comes away easily, as if it expected to. The glass is warm.", "effects": {"omen": "A clean lens in a dead server rack, pointed back along the road. It was warm. {Name} took it.", "res": {"parts": 1}}},
			{"label": "Leave it", "text": "You step out of its line of sight. The dust beside it has been disturbed before, by someone else doing the same thing.", "effects": {"omen": "A clean lens in a dead server rack, pointed back along the road. We left it watching."}},
		]},
	# ---- the Eroded Earth
	{"id": "buried_car", "where": "eroded", "needs": "", "once": false,
		"text": "A car buried to its windows. Inside, the sand has risen level with the dashboard. Someone drove it here until the road ran out, and then sat.",
		"options": [
			{"label": "Dig out the trunk", "text": "Tools, a jerry can, and a photograph of a beach that isn't anywhere any more.", "effects": {"res": {"salvage": 4}}},
			{"label": "Siphon the tank", "text": "A few liters of something that still burns.", "effects": {"res": {"power": 2}}},
		]},
	{"id": "radio", "where": "dunes_tower", "needs": "", "once": false,
		"text": "Inside the stump of the tower, a radio hisses on a battery that should be dead, scanning the channels. Every one is empty. One is empty the way a room is empty when someone in it is holding their breath.",
		"options": [
			{"label": "Key the mic", "text": "\"Hello?\" The hiss cuts out. Three seconds of perfect silence. Then it comes back.", "effects": {"omen": "A radio channel where something was listening.", "res": {"parts": 2}}},
			{"label": "Take the battery", "text": "It still holds a little charge.", "effects": {"res": {"power": 3}}},
		]},
	{"id": "bunker_door", "where": "bunker", "needs": "", "once": false,
		"text": "A bunker door, shut from the inside. A painted sign: OCCUPIED. DO NOT KNOCK. The paint is decades old.",
		"options": [
			{"label": "Knock", "text": "Nothing. Then, from inside, the sound of something getting to its feet.", "effects": {"fight": ["sentry_bot"]}},
			{"label": "Do as it says", "text": "You leave a ration tin on the step. It seems like the decent thing.", "effects": {"res": {"food": -1}, "fs": 1}},
		]},
	# ---- the Hollowing
	{"id": "lantern_window", "where": "hollow", "needs": "", "once": false,
		"text": "A lantern burns in the window of a dead house: the kind they hung in the Hollowing to celebrate the end of dying. Its oil should have run out centuries ago.",
		"options": [
			{"label": "Take the lantern", "text": "It keeps burning in your hand, green and cold. Inside the house, something starts to cry.", "effects": {"res": {"reagents": 3}, "fight": ["wisp"]}},
			{"label": "Leave it burning", "text": "Someone hung it there out of hope. That still counts for something.", "effects": {"fs": 1}},
		]},
	{"id": "graves_names", "where": "graves", "needs": "", "once": false,
		"text": "Every name on every headstone has been gouged out by something with claws. All but one, which someone has carved deeper. Carefully. Recently.",
		"options": [
			{"label": "Read the name", "text": "You don't know it. You have the uncomfortable feeling that you're going to.", "effects": {"omen": "One name in a Hollowing graveyard, carved deeper by someone, recently.", "res": {"bone": 3}}},
			{"label": "Salt the ground", "text": "Ossian's habit, and a good one. The ground hisses where the salt lands.", "effects": {"res": {"bone": 2}}},
		]},
	{"id": "crypt_knock", "where": "crypt", "needs": "", "once": false,
		"text": "Inside the sealed crypt, something is knocking. Slowly. Patiently. As if it has been knocking for a very long time and sees no reason to stop.",
		"options": [
			{"label": "Knock back twice", "text": "The knocking stops. Then: two knocks. Then nothing, ever again.", "effects": {"chronicle": "omen_knock", "fs": 1}},
			{"label": "Walk on", "text": "You can still hear it when you're out of sight of the crypt. You'll hear it tonight.", "effects": {}},
		]},
	# ---- the Frozen Sun
	{"id": "frozen_crowd", "where": "frozen", "needs": "", "once": false,
		"text": "Under the ice, a crowd. Hundreds of people, standing, all facing the same way: where the sun used to rise. The ice is very clear.",
		"options": [
			{"label": "Look where they're looking", "text": "There's nothing there. It's difficult to stop looking at it.", "effects": {"omen": "A crowd frozen under the ice, all facing where the sun rose. Something about that direction.", "res": {"sunstone": 2}}},
			{"label": "Chip out a sunstone", "text": "At their feet, one shard set in the ice. Still warm.", "effects": {"res": {"sunstone": 4}}},
		]},
	{"id": "beacon_pulse", "where": "beacon", "needs": "", "once": false,
		"text": "The dead beacon pulses red as you pass. A minute later, again. Something inside it is counting.",
		"options": [
			{"label": "Pull its core", "text": "It's hot enough to burn. The counting stops.", "effects": {"res": {"sunstone": 3, "power": 2}, "hp": -3}},
			{"label": "Let it count", "text": "Whatever it's counting toward, you'll find out.", "effects": {"omen": "A beacon in the Frozen Sun, counting down to something."}},
		]},
	# ---- the Leaderboard
	{"id": "quest_popup", "where": "leader", "needs": "", "once": false,
		"text": "A hologram flickers up as you pass. NEW QUEST: CLEAR THE PLAZA. REWARD: RANK. It's addressed to you, by name, spelled correctly.",
		"options": [
			{"label": "Accept", "text": "QUEST ACCEPTED. Somewhere close, something powers up.", "effects": {"fight": ["rogue_drone", "rogue_drone"], "res": {"parts": 4}}},
			{"label": "Decline", "text": "DECLINED. RANK UNCHANGED. Then it shows the rankings. You're on them. You've been on them for some time.", "effects": {"omen": "A leaderboard with our names on it. Somebody is keeping score."}},
		]},
	{"id": "server_hum", "where": "server", "needs": "", "once": false,
		"text": "The server rack is warm. One drive is still spinning, the only sound for a mile.",
		"options": [
			{"label": "Pull the drive", "text": "The label is handwritten. Neat block capitals, the same hand that scratched the visor on the Player's grave.", "effects": {"res": {"parts": 5}, "chronicle": "omen_drive"}},
			{"label": "Leave it spinning", "text": "Some things should be left running, even when you don't know what they run.", "effects": {"res": {"power": 3}}},
		]},
	# ---- the Coven Wars
	{"id": "charm_tree", "where": "coven", "needs": "", "once": false,
		"text": "A burnt tree hung with hundreds of soldiers' charms: hexwood, bone, braided hair. Ysolde's kind of work. Some are still warm.",
		"options": [
			{"label": "Take a few", "text": "They turn in your hand, as if trying to face home.", "effects": {"res": {"reagents": 4}}},
			{"label": "Hang one of your own", "text": "A button, a thread, whatever you have. The tree takes it.", "effects": {"fs": 1, "res": {"reagents": 1}}},
		]},
	{"id": "cauldron_smoke", "where": "cauldron", "needs": "", "once": false,
		"text": "The crashed war-cauldron is still smoking. Inside, a sigil is burning its way through the iron, one line a year. It's nearly finished.",
		"options": [
			{"label": "Scrape the sigil", "text": "It bites. In the trench behind you, something wakes.", "effects": {"res": {"reagents": 5}, "fight": ["hexed_soldier"]}},
			{"label": "Let it finish", "text": "Whatever it's spelling out, you'd rather not be here when it's done.", "effects": {"omen": "A sigil burning through a war-cauldron, one line a year. Nearly finished."}},
		]},
	# ---- the Kingdom (the Oracleborn's own land drifting in)
	{"id": "kingdom_echo", "where": "kingdom", "needs": "", "once": false, "heroes": ["oracle"],
		"text": "Pale stone underfoot. For a moment you smell the palace gardens, and somewhere behind you a door closes.",
		"options": [
			{"label": "Turn around", "text": "Only a stone passage running into fog. Somewhere, the door is still closing.", "effects": {"fs": 2, "omen": "In the Kingdom's stone, a door closing behind the Oracleborn. Someone had just been there."}},
			{"label": "Don't", "text": "You keep your eyes ahead and your hand on your sword.", "effects": {"res": {"food": 2}}},
		]},
]

## Night events, when a day is waited through in town. Same fields, minus "where".
const NIGHT := [
	{"id": "stranger", "needs": "", "once": true,
		"text": "At dusk a stranger walks into town out of the fog, sits by the pillar for an hour, and leaves before anyone thinks to ask where they came from. They leave a bundle behind.",
		"options": [
			{"label": "Open it", "text": "Dried meat, a coil of wire, and a map of a coastline that has never been anywhere near here.", "effects": {"res": {"food": 4, "salvage": 3}, "omen": "A stranger sat by the pillar for an hour and left a map of nowhere."}},
			{"label": "Leave it for them", "text": "In the morning it's gone. So are two of the town's lamps.", "effects": {"res": {"sunstone": -2}}},
		]},
	{"id": "lamp_out", "needs": "", "once": false,
		"text": "A lamp at the edge of town goes out and won't relight. Where its light used to reach, the fog has come three steps closer.",
		"options": [
			{"label": "Burn sunstone to relight it", "text": "The fog steps back. Maren nods, and doesn't mention the cost.", "effects": {"res": {"sunstone": -3}, "fs": 1}},
			{"label": "Leave it dark", "text": "In the morning there's a shape in the ash where something stood all night.", "effects": {"omen": "Something stood all night where a lamp had gone out."}},
		]},
	{"id": "caravan", "needs": "flag:ch2_done", "once": true,
		"text": "A caravan passes the edge of the land in the night: wagons, lanterns, a dog barking. It doesn't stop. A driver calls out: \"Paid your tithe yet? He'll come for it. He always does.\"",
		"options": [
			{"label": "Call back: \"Who?\"", "text": "\"The one with the pole.\" Then the fog has them, and there's no asking more.", "effects": {"chronicle": "omen_tithe"}},
			{"label": "Trade with them", "text": "They take bone and salvage for food and news. The news is bad.", "effects": {"res": {"bone": -3, "salvage": -3, "food": 8}, "chronicle": "omen_tithe"}},
		]},
	{"id": "shift_dream", "needs": "", "once": false,
		"text": "Everyone in town has the same dream: the land moving under them like a slow sea, and something at the center of it, turning.",
		"options": [
			{"label": "Write it down", "text": "Pell says it's happened before. Pell says it was worse last time.", "effects": {"omen": "The whole town dreamed it: land like a sea, and something at the center, turning."}},
			{"label": "Stay up", "text": "Nobody sleeps. The lamps burn all night.", "effects": {"res": {"sunstone": -1}, "fs": 1}},
		]},
	{"id": "survivor_night", "needs": "hero:gunslinger", "once": false,
		"text": "Someone is at the gate before dawn, half frozen, from a world nobody here has heard of. They ask if this is the station that fell.",
		"options": [
			{"label": "Take them in", "text": "They bring a trade and a story. The story goes in the Chronicle.", "effects": {"people": 1, "res": {"food": -3}}},
			{"label": "Feed them and point the way", "text": "They set off toward Pallas. With luck they'll get there.", "effects": {"res": {"food": -2}, "people": 1}},
		]},
	{"id": "documenter_night", "needs": "hero:engineer", "once": true,
		"text": "In the night, without being asked, the Documenter speaks. \"Engineer. I've been counting the pieces. There are more after every shift, and they're all moving the same way: toward the center. Toward where I think the Player came from.\"",
		"options": [
			{"label": "Ask what it thinks is there", "text": "\"I don't know. I don't think I'm supposed to. I think I'm supposed to want to.\"", "effects": {"omen": "The Documenter: everything drifts toward the center, and it thinks it is meant to want to know why.", "xp": 8}},
			{"label": "Tell it to stop counting", "text": "\"I can't stop. I can stop telling you, though. Would that help?\"", "effects": {"xp": 4}},
		]},
	{"id": "anchor_hum", "needs": "hero:engineer", "once": false,
		"text": "The mast hums a note it has never hummed before. The ground under the camp shivers once, like something asleep turning over.",
		"options": [
			{"label": "Feed it Power", "text": "The note settles. The Documenter files it under 'probably fine'.", "effects": {"res": {"power": -3}}},
			{"label": "Ride it out", "text": "By morning the newest anchor is a step out of line.", "effects": {"res": {"power": -1}, "omen": "The mast hummed a new note, and the ground shivered under the camp."}},
		]},
	{"id": "drone_night", "needs": "", "once": true,
		"text": "A low, even hum crosses the rooftops in the dark and stops directly over the pillar. It stays there for a slow count of twenty. Then it drifts off toward the fog, unhurried, like something that has seen what it came to see.",
		"options": [
			{"label": "Go out and look", "text": "Only haze above the pillar. At its foot, a ring of ash blown outward in a perfect circle.", "effects": {"omen": "Something hung over the pillar for a count of twenty and left a perfect ring in the ash."}},
			{"label": "Stay indoors", "text": "In the morning Pell asks if you heard it. You say yes. He looks relieved, and then he doesn't.", "effects": {"omen": "A hum over the pillar in the night. Pell heard it too."}},
		]},
	{"id": "piano", "needs": "flag:outpost", "once": true,
		"text": "Someone in Pallas plays the saloon piano after dark: a song from the Eroded Earth, badly. The whole settlement comes out to listen.",
		"options": [
			{"label": "Let them play", "text": "Franklin writes down the date and underlines it twice.", "effects": {"people": 1, "fs": 1}},
			{"label": "Ask for another song", "text": "They don't know another. They play it again, a little better.", "effects": {"res": {"food": 2}}},
		]},
]

## Nights on the road, at camp. Darker than nights at home: no walls, no lamps but yours.
const ROAD_NIGHT := [
	{"id": "eyes", "needs": "", "once": false,
		"text": "Two points of light at the edge of the firelight, at the height of a person's eyes. They don't blink. They reflect your fire, and then, for a moment, a different one.",
		"options": [
			{"label": "Throw a burning brand", "text": "Something steps out of the dark to answer.", "effects": {"fight": ["restless"]}},
			{"label": "Stare back", "text": "You hold their gaze until the fire burns low. When you build it up again they're gone, and you know something you didn't before, though you couldn't say what.", "effects": {"fs": 1, "omen": "Eyes at the edge of the camp that reflected a fire we hadn't lit."}},
			{"label": "Bank the fire and lie still", "text": "A cold, long night. Nothing comes closer. Nothing leaves.", "effects": {"hp": -3}},
		]},
	{"id": "fire_voice", "needs": "", "once": true,
		"text": "The fire pops, and says your name. Once, clearly, in a voice you almost recognize.",
		"options": [
			{"label": "Answer it", "text": "It doesn't speak again. In the morning the ashes have settled into something like a map. You commit it to memory.", "effects": {"fs": 1, "omen": "The campfire said {name}'s name once, in a voice {he} almost knew."}},
			{"label": "Kick it out", "text": "You sit in the dark until dawn and don't regret it.", "effects": {"hp": -2}},
		]},
	{"id": "drifted_camp", "needs": "", "once": false,
		"text": "All night the ground creaks like the deck of a ship. In the morning you're a few paces from where you made camp. The fire pit hasn't moved. You have.",
		"options": [
			{"label": "Walk back to the pit", "text": "The ground between you and it is new. You cross it carefully.", "effects": {"omen": "{Name} woke a few paces from where {he} made camp. The fire pit hadn't moved."}},
			{"label": "Leave it", "text": "There's nothing in the pit you need. You don't look back at it.", "effects": {}},
		]},
	{"id": "other_fire", "needs": "", "once": false,
		"text": "Across the void, on a piece of land you could never reach, another campfire. Someone sits beside it. As you watch, they raise a lantern and swing it, slowly, side to side.",
		"options": [
			{"label": "Signal back", "text": "They stop. They stand. In the morning there's a bundle at the edge of your camp, on the side facing the void, where nobody could have put it.", "effects": {"res": {"food": 2, "salvage": 2}, "omen": "Someone across the void signalled with a lantern. In the morning there was a bundle at the edge."}},
			{"label": "Put out your fire", "text": "Their lantern keeps swinging long after your fire is dark. Then it stops, as if they've made up their mind about something.", "effects": {"fs": 1}},
		]},
	{"id": "sleepwalk", "needs": "", "once": true,
		"text": "You wake on your feet at the very edge of the land, toes over the void. Far below, something pale is looking up at you.",
		"options": [
			{"label": "Step back", "text": "You step back. You sit by the fire until dawn with your boots on.", "effects": {"omen": "{Name} woke at the edge, toes over the void. Something pale below was looking up."}},
			{"label": "Look longer", "text": "It's a face. It's yours. When you blink it's gone, and your heart takes a long time to slow down.", "effects": {"fs": 2, "hp": -4, "omen": "{Name} looked down into the void and saw {his} own face looking back up."}},
		]},
	{"id": "drone_camp", "needs": "", "once": true,
		"text": "A low hum circles the camp three times, just past the firelight. Then it settles somewhere close and stops, the way a person stops talking in order to listen.",
		"options": [
			{"label": "Call out", "text": "Nothing answers. At dawn there's a ring of flattened ash around the camp, perfectly round, three paces out.", "effects": {"omen": "Something circled the camp three times and listened. A perfect ring in the ash at dawn."}},
			{"label": "Say nothing", "text": "You say nothing for a long time. So does it. Before dawn it lifts away, unhurried.", "effects": {"fs": 1}},
		]},
	{"id": "visitor", "needs": "", "once": false,
		"text": "You wake to find something from today's road sitting by your fire. You recognize it. It's looking at the flames, not at you.",
		"options": [
			{"label": "Ask what it wants", "text": "It turns toward you and it's nothing: a heap of ash, a coat on a stick. You're sure it wasn't, a moment ago.", "effects": {"omen": "Something from the road sat by our fire. When it turned, it was only ash and an old coat."}},
			{"label": "Draw your weapon", "text": "It rises, slowly, displeased to be asked to leave.", "effects": {"fight": ["wisp"]}},
		]},
	{"id": "spoiled", "needs": "", "once": false,
		"text": "Overnight, the rations in your pack have gone grey. All of them at once, the way fruit spoils in a single day near the Hollowing.",
		"options": [
			{"label": "Eat them anyway", "text": "They taste of nothing. You feel stronger, and you don't like that you do.", "effects": {"hp": 4, "omen": "The rations went grey overnight. Eating them made {name} stronger."}},
			{"label": "Throw them into the void", "text": "A hungry day ahead, but a clean one.", "effects": {"hp": -2}},
		]},
]


func pick_road_night(rng: RandomNumberGenerator) -> Dictionary:
	var options := []
	for e in ROAD_NIGHT:
		if e["once"] and seen.has(e["id"]):
			continue
		if Story.met(e["needs"]):
			options.append(e)
	if options.is_empty():
		return {}
	return options[rng.randi_range(0, options.size() - 1)]


## Day entries: rare notes written into the Omens tab on an ordinary day, no choice offered.
const DRONE_DAYS := [
	"At noon, a cold patch of static drifted across the town, like a radio caught between stations, and was gone.",
	"Something small left the edge of the land when Maren looked at it. She says it left the way a thing leaves once it knows it's been seen.",
	"Ossian found a socket the size of a fist in the base of the pillar. He swears it wasn't there yesterday. Clean-cut. Nothing fits it.",
]

## Chronicle entries events can add.
const CHRONICLE := {
	"omen_voice": {"tab": "Omens", "title": "The voice in the fog", "text": "A voice in the fog spoke a name from before the Maelstrom. Calmly. Once."},
	"omen_knock": {"tab": "Omens", "title": "The crypt that knocked back", "text": "Two knocks answered two knocks. Then it stopped, for good."},
	"omen_drive": {"tab": "Omens", "title": "The labeled drive", "text": "A server drive labeled in the Player's hand. Whatever he was saving, he saved it here."},
	"ruin_car": {"tab": "Places", "title": "The family car", "text": "A family drove until the road ran out, then dug their car free, built a raft from its doors, and set out into the void to find a beach. They left a sunstone for whoever came after."},
	"ruin_chapel": {"tab": "Places", "title": "The chapel with no bell", "text": "A chapel whose bell hung beneath the land, mouth up, full of ash. When it rang, every lamp in town flickered."},
	"ruin_terminal": {"tab": "Places", "title": "The last terminal", "text": "A terminal on a dead plaza, waiting for a second player. Its high-score table held one name a hundred times: the Player's. Its save file was dated tomorrow."},
	"omen_tithe": {"tab": "Omens", "title": "The tithe", "text": "A caravan driver warned of someone who takes a tithe: \"the one with the pole.\" He always comes for it."},
}

## Enemies that specific shaped land lures into the fight when the hero passes it.
const LURES := {
	"graves": "wisp", "bones": "restless", "deadwood": "restless", "crypt": "gravewalker",
	"saloon": "raider", "bunker": "sentry_bot", "rocks_sand": "sand_hound", "felled": "drifter",
	"spikes": "frost_wraith", "beacon": "frost_wraith", "ice_house": "starving_wolf",
	"drone_field": "rogue_drone", "questboard": "enforcer", "server": "rogue_drone",
	"thorns": "hex_hound", "trench": "hexed_soldier", "hexstone": "war_familiar", "cauldron": "hexed_soldier",
}

var seen: Array = []


func reset() -> void:
	seen = []


## An expedition event for this spot, or {}.
func pick_expedition(cell: Dictionary, hero_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var options := []
	for e in EXPEDITION:
		if e["once"] and seen.has(e["id"]):
			continue
		if e.has("heroes") and not e["heroes"].has(hero_id):
			continue
		if not Story.met(e["needs"]):
			continue
		if e.get("rare", false) and rng.randf() > 0.22:
			continue
		var w: String = e["where"]
		if w == cell["layout"]:
			options.append(e)
			options.append(e)  # a layout match counts double
		elif w == cell["world"] or (w == "any" and rng.randf() < 0.5):
			options.append(e)
	if options.is_empty():
		return {}
	return options[rng.randi_range(0, options.size() - 1)]


## A night event for a waited day, or {}.
func pick_night(rng: RandomNumberGenerator) -> Dictionary:
	var options := []
	for e in NIGHT:
		if e["once"] and seen.has(e["id"]):
			continue
		if Story.met(e["needs"]):
			options.append(e)
	if options.is_empty():
		return {}
	return options[rng.randi_range(0, options.size() - 1)]


func mark(e: Dictionary) -> void:
	if not seen.has(e["id"]):
		seen.append(e["id"])
