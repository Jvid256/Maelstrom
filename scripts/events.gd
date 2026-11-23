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
		"text": "Fresh footprints in the ash, sunk deep, like whoever made them was very heavy. They lead right up to the edge of your land and stop. ...Someone stood here a long time, looking in?",
		"options": [
			{"label": "Follow them back", "text": "The tracks end in a trampled circle out in the fog. One print is clear: a boot with a machined tread. You also find some scrap left behind.",
				"effects": {"omen": "Heavy footprints with a machined tread, stopping at the edge of our land. Someone stood there looking in.", "res": {"salvage": 2}}},
			{"label": "Keep moving", "text": "You memorize the shape of the tread. ...You'll know it if you see it again.", "effects": {"omen": "Footprints at the edge of our land, too deep for an ordinary man. We didn't follow them."}},
		]},
	{"id": "silhouette", "where": "any", "needs": "flag:ch2_done", "once": false,
		"text": "A loose piece of land drifts past in the haze. Someone is standing on it, in armor, perfectly still. Facing you. Then the land turns, and the fog swallows it.",
		"options": [
			{"label": "Watch until it's gone", "text": "It watched you the whole time, too. ...Who was that?", "effects": {"omen": "An armored figure on a drifting piece of land, watching {name} until the fog took it.", "fs": 1}},
			{"label": "Look away", "text": "You turn your back on it. But you keep listening, just in case.", "effects": {}},
		]},
	{"id": "driftwreck", "where": "any", "needs": "", "once": false,
		"text": "A scrap of land no bigger than a room drifts across your path. One dead tree, a cold firepit, a bedroll. ...Someone camped here once, on a world that's gone now.",
		"options": [
			{"label": "Search the camp", "text": "You find a tin of food, a good knife, and a letter in a language nobody can read anymore.", "effects": {"res": {"food": 3, "salvage": 2}}},
			{"label": "Let it pass", "text": "The little camp drifts away, still neatly made. It might be years before anyone sees it again.", "effects": {"fs": 1}},
		]},
	{"id": "voice", "where": "any", "needs": "", "once": true,
		"text": "A voice in the fog calls your name. Not the name people use here... your real one, from before. It says it once, calmly, and waits.",
		"options": [
			{"label": "Answer", "text": "Nothing answers. But for a moment the fog thins, and you can see much farther than you should.", "effects": {"fs": 2, "chronicle": "omen_voice"}},
			{"label": "Say nothing", "text": "The fog closes in again. You walk faster, and you don't look back.", "effects": {"chronicle": "omen_voice"}},
		]},
	# ---- the drones. Rare, never explained in Act I. Something mechanical is watching the
	# points of interest, and has been since before the Engineer arrived.
	{"id": "drone_glint", "where": "any", "needs": "", "once": true, "rare": true,
		"text": "A point of light hangs above the fog. Too steady to be a star, too high to be a bird. It stays in place the whole time you cross the open ground... then it's gone.",
		"options": [
			{"label": "Watch it", "text": "It didn't drift with the land. ...But everything out here drifts with the land.", "effects": {"omen": "A light above the fog that held still while the land moved under it."}},
			{"label": "Keep your head down", "text": "You can feel it watching your back until a ridge finally blocks it from view.", "effects": {"fs": 1}},
		]},
	{"id": "drone_tracks", "where": "any", "needs": "flag:ch1_done", "once": true, "rare": true,
		"text": "Strange tracks in the ash. Not footprints: three small dots in a triangle, repeated at perfect intervals, in a dead-straight line.",
		"options": [
			{"label": "Follow them", "text": "The tracks end at a patch of warm ground, along with a bit of scrap. Nothing's here now... but something was, not long ago.", "effects": {"omen": "Three-point tracks, perfectly regular, ending at warm ground.", "res": {"salvage": 1}}},
			{"label": "Scuff them out", "text": "You rub the tracks away with your boot. ...It just felt like the right thing to do.", "effects": {}},
		]},
	{"id": "drone_lens", "where": "server", "needs": "", "once": true, "rare": true,
		"text": "Something in the server rack doesn't belong there: a tiny lens, perfectly clean, when everything else is covered in dust. It's pointed at the road you just walked.",
		"options": [
			{"label": "Take it", "text": "It comes loose easily, almost like it wanted to. The glass is warm.", "effects": {"omen": "A clean lens in a dead server rack, pointed back along the road. It was warm. {Name} took it.", "res": {"parts": 1}}},
			{"label": "Leave it", "text": "You step out of its view. The dust next to it is scuffed. ...Someone else did the same thing before you.", "effects": {"omen": "A clean lens in a dead server rack, pointed back along the road. We left it watching."}},
		]},
	# ---- the Eroded Earth
	{"id": "buried_car", "where": "eroded", "needs": "", "once": false,
		"text": "A car, buried in sand up to its windows. Inside, the sand comes up to the dashboard. ...Someone drove here until the road ran out, and just sat?",
		"options": [
			{"label": "Dig out the trunk", "text": "Tools, a gas can, and a photo of a beach that doesn't exist anymore.", "effects": {"res": {"salvage": 4}}},
			{"label": "Siphon the tank", "text": "There are still a few liters of fuel left. That'll burn.", "effects": {"res": {"power": 2}}},
		]},
	{"id": "radio", "where": "dunes_tower", "needs": "", "once": false,
		"text": "Inside the broken tower, an old radio hisses, scanning through empty channels. Its battery should be dead. On one channel, the silence feels... different. Like someone is holding their breath.",
		"options": [
			{"label": "Key the mic", "text": "\"Hello?\" The hiss cuts out. Three seconds of total silence... then it comes back. You pocket a few parts from the casing.", "effects": {"omen": "A radio channel where something was listening.", "res": {"parts": 2}}},
			{"label": "Take the battery", "text": "It still holds a bit of charge.", "effects": {"res": {"power": 3}}},
		]},
	{"id": "bunker_door", "where": "bunker", "needs": "", "once": false,
		"text": "A bunker door, locked from the inside. A painted sign reads: OCCUPIED. DO NOT KNOCK. The paint is decades old.",
		"options": [
			{"label": "Knock", "text": "Nothing. Then, from inside, you hear something get to its feet!", "effects": {"fight": ["sentry_bot"]}},
			{"label": "Do as it says", "text": "You leave a ration tin on the step. It feels like the polite thing to do.", "effects": {"res": {"food": -1}, "fs": 1}},
		]},
	# ---- the Hollowing
	{"id": "lantern_window", "where": "hollow", "needs": "", "once": false,
		"text": "A lantern glows in the window of an abandoned house. The Hollowing hung these to celebrate the end of death. ...It's still lit, after all this time?",
		"options": [
			{"label": "Take the lantern", "text": "It keeps burning in your hand, cold and green. Then, inside the house, something starts to cry!", "effects": {"res": {"reagents": 3}, "fight": ["wisp"]}},
			{"label": "Leave it burning", "text": "Someone hung it there out of hope. You leave it be.", "effects": {"fs": 1}},
		]},
	{"id": "graves_names", "where": "graves", "needs": "", "once": false,
		"text": "Every name on every headstone has been clawed away. Except one. Someone carved that name deeper, carefully... and recently.",
		"options": [
			{"label": "Read the name", "text": "You don't recognize it. ...So why does it feel like you will?", "effects": {"omen": "One name in a Hollowing graveyard, carved deeper by someone, recently.", "res": {"bone": 3}}},
			{"label": "Salt the ground", "text": "Just like Ossian does. The ground hisses wherever the salt lands.", "effects": {"res": {"bone": 2}}},
		]},
	{"id": "crypt_knock", "where": "crypt", "needs": "", "once": false,
		"text": "Something is knocking inside the sealed crypt. Slowly. Patiently. Like it's been knocking for a very long time.",
		"options": [
			{"label": "Knock back twice", "text": "The knocking stops. Then... two knocks. After that, nothing. Not ever again.", "effects": {"chronicle": "omen_knock", "fs": 1}},
			{"label": "Walk on", "text": "You can still hear it long after the crypt is out of sight. ...You'll be hearing it tonight, too.", "effects": {}},
		]},
	# ---- the Frozen Sun
	{"id": "frozen_crowd", "where": "frozen", "needs": "", "once": false,
		"text": "There's a crowd under the ice. Hundreds of people, standing still, all facing the same way: toward where the sun used to rise.",
		"options": [
			{"label": "Look where they're looking", "text": "There's nothing there. ...But it's hard to look away. You chip a little sunstone loose before you go.", "effects": {"omen": "A crowd frozen under the ice, all facing where the sun rose. Something about that direction.", "res": {"sunstone": 2}}},
			{"label": "Chip out a sunstone", "text": "There's a shard of sunstone set in the ice at their feet. It's still warm.", "effects": {"res": {"sunstone": 4}}},
		]},
	{"id": "beacon_pulse", "where": "beacon", "needs": "", "once": false,
		"text": "The dead beacon flashes red as you pass. A minute later, it flashes again. ...Is it counting?",
		"options": [
			{"label": "Pull its core", "text": "Ow! It's burning hot! But the counting stops.", "effects": {"res": {"sunstone": 3, "power": 2}, "hp": -3}},
			{"label": "Let it count", "text": "Whatever it's counting down to, you'll find out eventually.", "effects": {"omen": "A beacon in the Frozen Sun, counting down to something."}},
		]},
	# ---- the Leaderboard
	{"id": "quest_popup", "where": "leader", "needs": "", "once": false,
		"text": "A hologram flickers to life. NEW QUEST: CLEAR THE PLAZA. REWARD: RANK. ...It's addressed to you. By name. Spelled correctly.",
		"options": [
			{"label": "Accept", "text": "QUEST ACCEPTED. Nearby, something powers up!", "effects": {"fight": ["rogue_drone", "rogue_drone"], "res": {"parts": 4}}},
			{"label": "Decline", "text": "QUEST DECLINED. Then it shows the rankings. Your name is on them... and it's been there for a while.", "effects": {"omen": "A leaderboard with our names on it. Somebody is keeping score."}},
		]},
	{"id": "server_hum", "where": "server", "needs": "", "once": false,
		"text": "The server rack is warm. One drive is still spinning. It's the only sound for miles.",
		"options": [
			{"label": "Pull the drive", "text": "The label is handwritten in neat capitals. ...The same handwriting as the scratches on the Player's visor.", "effects": {"res": {"parts": 5}, "chronicle": "omen_drive"}},
			{"label": "Leave it spinning", "text": "You leave it running, and draw a little power from the rack instead.", "effects": {"res": {"power": 3}}},
		]},
	# ---- the Coven Wars
	{"id": "charm_tree", "where": "coven", "needs": "", "once": false,
		"text": "A burnt tree, hung with hundreds of soldiers' charms. Hexwood, bone, braided hair... Ysolde's kind of work. Some of them are still warm.",
		"options": [
			{"label": "Take a few", "text": "They twist in your hand, like they're trying to face home.", "effects": {"res": {"reagents": 4}}},
			{"label": "Hang one of your own", "text": "You tie on a button and some thread. The tree seems to accept it.", "effects": {"fs": 1, "res": {"reagents": 1}}},
		]},
	{"id": "cauldron_smoke", "where": "cauldron", "needs": "", "once": false,
		"text": "The crashed war-cauldron is still smoking. Inside, a sigil is slowly burning its way through the iron. It's almost finished.",
		"options": [
			{"label": "Scrape the sigil", "text": "It stings! Behind you, in the trench, something wakes up!", "effects": {"res": {"reagents": 5}, "fight": ["hexed_soldier"]}},
			{"label": "Let it finish", "text": "Whatever it's spelling out... you'd rather not be around when it's done.", "effects": {"omen": "A sigil burning through a war-cauldron, one line a year. Nearly finished."}},
		]},
	# ---- the Kingdom (the Oracleborn's own land drifting in)
	{"id": "kingdom_echo", "where": "kingdom", "needs": "", "once": false, "heroes": ["oracle"],
		"text": "Pale stone underfoot. For a moment, you can smell the palace gardens. Somewhere behind you, a door closes. ...Home?",
		"options": [
			{"label": "Turn around", "text": "There's only a stone hallway fading into fog. But you can still hear the door, closing.", "effects": {"fs": 2, "omen": "In the Kingdom's stone, a door closing behind the Oracleborn. Someone had just been there."}},
			{"label": "Don't", "text": "You keep your eyes forward and your hand on your sword. Along the way, you find a few old palace rations.", "effects": {"res": {"food": 2}}},
		]},
]

## Night events, when a day is waited through in town. Same fields, minus "where".
const NIGHT := [
	{"id": "stranger", "needs": "", "once": true,
		"text": "At dusk, a stranger walks out of the fog and sits by the pillar for an hour. They leave before anyone thinks to ask who they are... but they leave a bundle behind.",
		"options": [
			{"label": "Open it", "text": "Dried meat, a coil of wire, and a map of a coastline nobody here has ever seen.", "effects": {"res": {"food": 4, "salvage": 3}, "omen": "A stranger sat by the pillar for an hour and left a map of nowhere."}},
			{"label": "Leave it for them", "text": "By morning, the bundle is gone. ...So are two of the town's lamps.", "effects": {"res": {"sunstone": -2}}},
		]},
	{"id": "lamp_out", "needs": "", "once": false,
		"text": "A lamp at the edge of town goes out and won't relight. The fog creeps a few steps closer.",
		"options": [
			{"label": "Burn sunstone to relight it", "text": "The fog pulls back. Maren gives you a grateful nod.", "effects": {"res": {"sunstone": -3}, "fs": 1}},
			{"label": "Leave it dark", "text": "In the morning, there's a print in the ash where something stood all night.", "effects": {"omen": "Something stood all night where a lamp had gone out."}},
		]},
	{"id": "caravan", "needs": "flag:ch2_done", "once": true,
		"text": "A caravan passes the edge of the land at night. Wagons, lanterns, a barking dog. It doesn't stop. One of the drivers shouts: \"Paid your toll yet? He'll come for it. He always does!\"",
		"options": [
			{"label": "Call back: \"Who?\"", "text": "\"The one with the pole!\" Then the fog swallows them up.", "effects": {"chronicle": "omen_tithe"}},
			{"label": "Trade with them", "text": "They trade food and news for bone and salvage. The news isn't good.", "effects": {"res": {"bone": -3, "salvage": -3, "food": 8}, "chronicle": "omen_tithe"}},
		]},
	{"id": "shift_dream", "needs": "", "once": false,
		"text": "Everyone in town has the same dream. The land rolls beneath them like a slow sea... and at the center, something is turning.",
		"options": [
			{"label": "Write it down", "text": "Pell says this has happened before. He says it was worse last time.", "effects": {"omen": "The whole town dreamed it: land like a sea, and something at the center, turning."}},
			{"label": "Stay up", "text": "Nobody sleeps. The lamps burn all night long.", "effects": {"res": {"sunstone": -1}, "fs": 1}},
		]},
	{"id": "survivor_night", "needs": "hero:gunslinger", "once": false,
		"text": "Before dawn, someone stumbles up to the gate, half frozen. They're from a world nobody's heard of. \"Is this... the station that fell?\"",
		"options": [
			{"label": "Take them in", "text": "They have useful skills, and a story worth hearing. Another mouth to feed, but another pair of hands.", "effects": {"people": 1, "res": {"food": -3}}},
			{"label": "Feed them and point the way", "text": "They head off toward Pallas. Hopefully they make it.", "effects": {"res": {"food": -2}, "people": 1}},
		]},
	{"id": "documenter_night", "needs": "hero:engineer", "once": true,
		"text": "In the middle of the night, the Documenter speaks up on its own. \"Engineer? I've been counting the pieces. There are more after every shift, and they're all drifting the same way. Toward the center. Toward where I think the Player came from.\"",
		"options": [
			{"label": "Ask what it thinks is there", "text": "\"I don't know. I don't think I'm supposed to know. ...But I think I'm supposed to want to.\"", "effects": {"omen": "The Documenter: everything drifts toward the center, and it thinks it is meant to want to know why.", "xp": 8}},
			{"label": "Tell it to stop counting", "text": "\"I can't stop counting. But I can stop telling you about it. Would that help?\"", "effects": {"xp": 4}},
		]},
	{"id": "anchor_hum", "needs": "hero:engineer", "once": false,
		"text": "The mast hums a note it's never made before. The ground beneath the camp shivers, like something asleep rolling over.",
		"options": [
			{"label": "Feed it Power", "text": "The hum settles down. \"Probably fine!\" says the Documenter.", "effects": {"res": {"power": -3}}},
			{"label": "Ride it out", "text": "By morning, the newest anchor has shifted slightly out of line.", "effects": {"res": {"power": -1}, "omen": "The mast hummed a new note, and the ground shivered under the camp."}},
		]},
	{"id": "drone_night", "needs": "", "once": true,
		"text": "A low hum crosses the rooftops in the dark and stops right above the pillar. It hangs there for a slow count of twenty... then drifts off into the fog, like it saw what it came to see.",
		"options": [
			{"label": "Go out and look", "text": "Nothing above the pillar but haze. At its base, the ash has been blown into a perfect ring.", "effects": {"omen": "Something hung over the pillar for a count of twenty and left a perfect ring in the ash."}},
			{"label": "Stay indoors", "text": "In the morning, Pell asks if you heard it, too. You nod. He looks relieved... then worried.", "effects": {"omen": "A hum over the pillar in the night. Pell heard it too."}},
		]},
	{"id": "piano", "needs": "flag:outpost", "once": true,
		"text": "Someone in Pallas plays the saloon piano after dark. An old song from the Eroded Earth, played badly. The whole settlement comes out to listen.",
		"options": [
			{"label": "Let them play", "text": "Franklin writes down the date and underlines it twice.", "effects": {"people": 1, "fs": 1}},
			{"label": "Ask for another song", "text": "They don't know any others. So they play it again, a little better this time.", "effects": {"res": {"food": 2}}},
		]},
]

## Nights on the road, at camp. Darker than nights at home: no walls, no lamps but yours.
const ROAD_NIGHT := [
	{"id": "eyes", "needs": "", "once": false,
		"text": "Two points of light at the edge of the firelight, right at eye level. They don't blink. They reflect your campfire... and for a moment, a different fire.",
		"options": [
			{"label": "Throw a burning brand", "text": "Something steps out of the dark!", "effects": {"fight": ["restless"]}},
			{"label": "Stare back", "text": "You hold their gaze until the fire burns low. When you stoke it again, they're gone. ...You feel like you've learned something, but you can't say what.", "effects": {"fs": 1, "omen": "Eyes at the edge of the camp that reflected a fire we hadn't lit."}},
			{"label": "Bank the fire and lie still", "text": "A long, cold night. Nothing comes closer. But nothing leaves, either.", "effects": {"hp": -3}},
		]},
	{"id": "fire_voice", "needs": "", "once": true,
		"text": "The fire crackles, and says your name. Clearly. In a voice you almost recognize.",
		"options": [
			{"label": "Answer it", "text": "It doesn't speak again. But by morning, the ashes have settled into something like a map. You memorize it.", "effects": {"fs": 1, "omen": "The campfire said {name}'s name once, in a voice {he} almost knew."}},
			{"label": "Kick it out", "text": "You sit in the cold dark until dawn. It was the right call.", "effects": {"hp": -2}},
		]},
	{"id": "drifted_camp", "needs": "", "once": false,
		"text": "All night, the ground creaks like the deck of a ship. In the morning, you're several steps from where you fell asleep. The fire pit hasn't moved. ...You have?",
		"options": [
			{"label": "Walk back to the pit", "text": "The ground between you and the pit is new. You cross it carefully.", "effects": {"omen": "{Name} woke a few paces from where {he} made camp. The fire pit hadn't moved."}},
			{"label": "Leave it", "text": "There's nothing in the pit you need. You pack up and go.", "effects": {}},
		]},
	{"id": "other_fire", "needs": "", "once": false,
		"text": "Across the void, on a piece of land you could never reach, there's another campfire. Someone is sitting by it. As you watch, they lift a lantern and swing it slowly, side to side.",
		"options": [
			{"label": "Signal back", "text": "They stop and stand up. In the morning, there's a bundle at the edge of your camp, on the side facing the void. ...How did it get there?", "effects": {"res": {"food": 2, "salvage": 2}, "omen": "Someone across the void signalled with a lantern. In the morning there was a bundle at the edge."}},
			{"label": "Put out your fire", "text": "Their lantern keeps swinging long after your fire is out. Then it stops, as if they've decided something.", "effects": {"fs": 1}},
		]},
	{"id": "sleepwalk", "needs": "", "once": true,
		"text": "You wake up standing at the very edge of the land, toes hanging over the void. Far below, something pale is looking up at you.",
		"options": [
			{"label": "Step back", "text": "You back away from the edge. You sit by the fire until dawn, boots on.", "effects": {"omen": "{Name} woke at the edge, toes over the void. Something pale below was looking up."}},
			{"label": "Look longer", "text": "It's a face. ...Your face! You blink, and it's gone. Your heart pounds for a long time.", "effects": {"fs": 2, "hp": -4, "omen": "{Name} looked down into the void and saw {his} own face looking back up."}},
		]},
	{"id": "drone_camp", "needs": "", "once": true,
		"text": "A low hum circles the camp three times, just outside the firelight. Then it settles somewhere nearby and goes quiet. ...Like it's listening.",
		"options": [
			{"label": "Call out", "text": "No answer. At dawn, there's a perfect ring of flattened ash around the camp, three steps out.", "effects": {"omen": "Something circled the camp three times and listened. A perfect ring in the ash at dawn."}},
			{"label": "Say nothing", "text": "You stay silent for a long time. So does it. Before dawn, it lifts away.", "effects": {"fs": 1}},
		]},
	{"id": "visitor", "needs": "", "once": false,
		"text": "You wake up to find something from today's road sitting by your fire. You recognize it. It's staring at the flames, not at you.",
		"options": [
			{"label": "Ask what it wants", "text": "It turns toward you... and it's just a pile of ash and an old coat on a stick. ...It wasn't, a second ago.", "effects": {"omen": "Something from the road sat by our fire. When it turned, it was only ash and an old coat."}},
			{"label": "Draw your weapon", "text": "It rises slowly. It doesn't like being told to leave!", "effects": {"fight": ["wisp"]}},
		]},
	{"id": "spoiled", "needs": "", "once": false,
		"text": "Overnight, all the rations in your pack have turned gray. All at once, like fruit near the Hollowing.",
		"options": [
			{"label": "Eat them anyway", "text": "They taste like nothing. You feel stronger... and you don't like that you do.", "effects": {"hp": 4, "omen": "The rations went grey overnight. Eating them made {name} stronger."}},
			{"label": "Throw them into the void", "text": "It'll be a hungry day. But a safe one.", "effects": {"hp": -2}},
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
	"Around noon, a patch of cold static drifted through town, like a radio stuck between stations. Then it was gone.",
	"Maren saw something small at the edge of the land. The moment she looked at it, it left. She says it knew it had been seen.",
	"Ossian found a fist-sized socket in the base of the pillar. He swears it wasn't there yesterday. It's perfectly cut, and nothing fits in it.",
]

## Chronicle entries events can add.
const CHRONICLE := {
	"omen_voice": {"tab": "Omens", "title": "The voice in the fog", "text": "A voice in the fog called a name from before the Maelstrom. Just once, very calmly."},
	"omen_knock": {"tab": "Omens", "title": "The crypt that knocked back", "text": "Two knocks answered two knocks. Then the knocking stopped for good."},
	"omen_drive": {"tab": "Omens", "title": "The labeled drive", "text": "A server drive labeled in the Player's hand. Whatever he was saving, he saved it here."},
	"ruin_car": {"tab": "Places", "title": "The family car", "text": "A family drove until the road ran out, then dug their car free, built a raft from its doors, and set out into the void to find a beach. They left a sunstone for whoever came after."},
	"ruin_chapel": {"tab": "Places", "title": "The chapel with no bell", "text": "A chapel whose bell hung beneath the land, mouth up, full of ash. When it rang, every lamp in town flickered."},
	"ruin_terminal": {"tab": "Places", "title": "The last terminal", "text": "A terminal on a dead plaza, waiting for a second player. Its high-score table held one name a hundred times: the Player's. Its save file was dated tomorrow."},
	"omen_tithe": {"tab": "Omens", "title": "The toll", "text": "A caravan driver warned about someone who charges a toll: \"the one with the pole.\" He always comes to collect."},
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
