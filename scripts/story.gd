extends Node
## Story data and progress for Act I (autoload "Story"):
##   Chapter 1, "The Pillar Wakes": the Oracleborn, his town, leads, readings and the throne hall.
##   Chapter 2, "The Uncoded Engineer": the attack on the Augmented Player, the transfusion,
##     the burial, anchors, the Documenter and the Book of Laws.
##   Chapter 3, "Pallas": the station falls, Alysia's crew, tethers, settlements.
##   Act I ends when the three regions connect and the heroes meet.
##
## Conditions (joined with "&"): "" always; "lead:<id>"; "leads:<n>" (that region's leads done);
## "readings:<n>"; "flag:<f>"; "hero:<id>" (hero unlocked); "laws:<n>"; "level:<n>";
## "people:<n>" (Pallas's population); "connected:<a>-<b>".

# ================================================================== people
const PEOPLE := {
	# ---- the Oracleborn's town
	"pell": {
		"name": "Old Pell", "origin": "Unknown world", "region": "oracle",
		"about": "The oldest person in town. Even Pell doesn't remember which world Pell came from.",
		"talks": [
			{"needs": "", "gives": {"chronicle": "pell_pillar", "flag": "met_pell"}, "pages": [
				"Well, lad. The pillar's awake. Forty years I've watched that stone sit dead in the square... and this morning it started humming.",
				"You don't remember, do you? You came out of that pillar. Before any of us got here, it was just you, the stone, and a scrap of ground.",
				"If the pillar can hold land now, go and find some. But talk to the others first. Everyone here lost a world, and a few of them lost something out in the fog, too.",
			]},
			{"needs": "leads:2&readings:1", "gives": {"lead": "throne", "chronicle": "pell_hall"}, "pages": [
				"You've been reading the land, haven't you? I can tell. Your eyes catch the light now, same as the pillar.",
				"Something drifted in with the last shift. Pale stone, a window of colored glass... It looks like the ground you arrived on.",
				"Whatever's out there, it knows you. Be careful, lad. Things from home don't always remember you kindly.",
			]},
			{"needs": "lead:throne", "gives": {"chronicle": "pell_after", "flag": "ch1_done"}, "pages": [
				"So you saw them. Your mother and father... I won't ask what they decided. You'll tell me when you're ready.",
				"Keep that lens close, and keep going. Whatever they planned for you, it isn't finished yet.",
				"One more thing. Some nights there's a light out east. Not ours. Someone else out there is holding land... and not very well.",
			]},
			{"needs": "hero:gunslinger", "gives": {"chronicle": "pell_pallas"}, "pages": [
				"Did you feel that? Something fell out of the sky to the south. Metal, big as a hill. The whole town shook.",
				"If there are people in it, they'll need what we needed: ground that stays put. Go and meet them when the land lets you.",
			]},
		],
		"idle": "Pell nods at the pillar. \"Still humming, lad.\"",
	},
	"maren": {
		"name": "Maren Holt", "origin": "The Frozen Sun", "region": "oracle",
		"about": "The town's lamplighter. She keeps every lamp burning with the last shards of a dead sun.",
		"talks": [
			{"needs": "", "gives": {"lead": "bell", "chronicle": "maren_city"}, "pages": [
				"Every lamp in this town burns sunstone. Did you know that? Each shard is a piece of a sun that went out.",
				"My city froze in a single winter. The bell tower rang the whole time... right up until the ice closed over the ringer's hands.",
				"I've seen that tower in the fog, out where it's coldest. Please, bring it in. I just want to know my city was real.",
			]},
			{"needs": "lead:bell", "gives": {"item": "lamplighter_cloak", "chronicle": "maren_bell"}, "pages": [
				"You found it! I went and touched the ice this morning. The bell's still in there, frozen mid-swing.",
				"Here, take my coat. It kept me alive through the end of a world. It can keep you warm for a few days in the fog.",
			]},
		],
		"idle": "Maren trims a wick. \"Stay near the light, all right?\"",
	},
	"ossian": {
		"name": "Brother Ossian", "origin": "The Hollowing", "region": "oracle",
		"about": "A gravekeeper who ran from the ritual that ended his world. He still feels guilty about it.",
		"talks": [
			{"needs": "", "gives": {"lead": "crypt", "chronicle": "ossian_ritual"}, "pages": [
				"They promised us the ritual would end death. And it did! ...Just not the way anyone wanted. Nothing in my world stays dead anymore.",
				"My brother was the sexton. He sealed himself in the crypt with the dead, so they couldn't walk out. I ran. He didn't.",
				"The crypt is out there somewhere. I can feel it. Bring it in, please. There are words I never got to say to him.",
			]},
			{"needs": "lead:crypt", "gives": {"item": "sexton_gloves", "chronicle": "ossian_crypt"}, "pages": [
				"The seal held?! All this time... he kept them in. That's my brother. That's exactly the kind of man he was.",
				"These were his gloves. They'll make your hands quick, like his. I think he'd want you to have them.",
			]},
		],
		"idle": "Ossian is salting the doorstep again. \"Can't be too careful!\"",
	},
	"reyes": {
		"name": "Dusty Reyes", "origin": "The Eroded Earth", "region": "oracle",
		"about": "A drifter. She walked a dying desert for twenty years before the Drift picked her up.",
		"talks": [
			{"needs": "", "gives": {"lead": "lamp", "chronicle": "reyes_desert"}, "pages": [
				"My world didn't end with a bang. It just wore out. Sand in everything... then nothing but sand.",
				"Last shift, I saw a tower in the fog with one window lit. Nobody's turned on a light in my world for fifty years.",
				"Bring that tower in for me, would you? Somebody kept a generator running up there. I want to know who.",
			]},
			{"needs": "lead:lamp", "gives": {"item": "drifter_boots", "chronicle": "reyes_tower"}, "pages": [
				"A solar battery wired to one bulb. No note. No body. Just a light somebody wanted left on.",
				"Huh. Here, take these. Good boots for walking on ground that won't sit still. You'll make better time.",
			]},
			{"needs": "hero:gunslinger", "gives": {"chronicle": "reyes_alysia"}, "pages": [
				"That thing that fell... people say it's a mining station. Kepler. I know that name. They were hiring off-world when I was a girl.",
				"If there's anyone from my world in there, tell them Dusty Reyes is still walking.",
			]},
		],
		"idle": "Dusty shakes out her boot. \"Old habit. There's no sand here.\"",
	},
	"ysolde": {
		"name": "Ysolde", "origin": "The Coven Wars", "region": "oracle",
		"about": "A hedge-witch who makes gear for materials. She won't say which side she fought for.",
		"talks": [
			{"needs": "", "gives": {"chronicle": "ysolde_war", "flag": "workbench"}, "pages": [
				"Oh, a customer! Bring me salvage, bone, sunstone... and I'll make you something to keep you breathing.",
				"My world burned in a war between covens. I made charms for soldiers on both sides. Hm? Which side was I on? That's a secret.",
			]},
			{"needs": "flag:ch2_done", "gives": {"chronicle": "ysolde_thorns", "flag": "coven_recipes"}, "pages": [
				"Those thorns out east... I'd know them anywhere. Looks like my war is drifting in. How exciting.",
				"Bring me what grows there and I'll teach you what we made with it. Some of it I'm not proud of. Most of it, actually.",
			]},
		],
		"idle": "Ysolde looks up from her charms. \"Brought me something nice?\"",
	},
	# ---- the Engineer's camp
	"documenter": {
		"name": "The Documenter", "origin": "The swarm", "region": "engineer", "hidden": true,
		"about": "The interface the swarm projects onto the Engineer's eye: stat tracking, a bestiary, run summaries. It calls itself a documenter, and it is very polite. Not a person: it speaks through the HUD when it chooses, and its beats below fire on their own.",
		"talks": [
			{"needs": "", "gives": {"chronicle": "doc_hello", "flag": "met_documenter"}, "pages": [
				"System restored. Swarm integration: 61% and rising. Welcome back, Engineer! I kept the records while you were unconscious.",
				"The mast is holding this ground. It costs 1 Power per day for each piece you anchor. If the reserve runs out, the newest piece drifts away first. Please don't let that happen. I like the newest piece.",
				"New quest available! The people who killed the Player didn't take everything. There's a cache drifting two or three pieces east of here.",
			]},
			{"needs": "flag:met_documenter", "gives": {"lead": "cache", "lead2": "cauldron", "chronicle": "doc_leads"}, "pages": [
				"Quest log updated. One: the Player's cache, to the east. Two: a heat signature to the south. Something iron, shaped like a cauldron. ...I don't like it.",
				"I've also started a Book of Laws. Every world that drifts in brings its own rules with it. Anchor enough of one world's land and I can write its law down. Then that land can't surprise us anymore.",
			]},
			{"needs": "leads:2&laws:1", "gives": {"chronicle": "doc_signal", "flag": "ch2_done"}, "pages": [
				"Engineer! I'm picking up a transmission. It isn't from this world... and it isn't from ours, either.",
				"\"...Kepler Mining Station Pallas, Franklin administrating, we have lost... all of it, the sky, the... brace, brace, brace...\"",
				"It's coming down! Southwest of here, within the hour. I'm going to record it. I really hope they're all right.",
			]},
			{"needs": "hero:gunslinger", "gives": {"chronicle": "doc_pallas"}, "pages": [
				"Good news! The station survived the landing. I'm reading three crew... and a fourth signal I can't classify. Human, but with reflexes faster than human.",
				"If you can connect our land to theirs, their tethers and your anchors would hold each other up. Also, I'd very much like to meet them. Everyone I know is already in my records.",
			]},
		],
		"idle": "\"No new entries. That's a good thing, Engineer.\"",
	},
	"grave": {
		"name": "The Player's grave", "origin": "The Leaderboard", "region": "engineer",
		"about": "A cairn of plaza stones with a cracked visor on top. The Engineer buried the Player here after nothing of him, bionic or human, still worked.",
		"talks": [
			{"needs": "", "gives": {"chronicle": "grave_visit", "item": "players_jacket"}, "pages": [
				"The Engineer stands at the cairn for a long time. For once, the Documenter is quiet.",
				"The Player's jacket is folded under the top stone, where he left it. It's too big for him. ...He puts it on anyway.",
			]},
			{"needs": "level:3", "gives": {"chronicle": "grave_swarm", "flag": "grave_swarm"}, "pages": [
				"The swarm feels stronger here. Not words, just pressure... like standing next to something huge that's fast asleep.",
				"\"Engineer,\" the Documenter says quietly. \"Part of him lives in you now. And part of what ran his world... I'm part of that, too. I thought you should know.\"",
			]},
		],
		"idle": "The visor on the cairn catches the anchor light. Nothing else moves.",
	},
	# ---- Pallas
	"franklin": {
		"name": "Franklin", "origin": "The Eroded Earth", "region": "gunslinger",
		"about": "Administrator of the Kepler mining station Pallas. He keeps a ledger of everything, even the end of the world.",
		"talks": [
			{"needs": "", "gives": {"chronicle": "franklin_crash", "flag": "met_franklin"}, "pages": [
				"Ward! Thank goodness, you're standing. That's more than I can say for the station. We lost the upper ring, both drills... and the sky.",
				"Here's what I know. This isn't Earth. The ground moves. And the station landed on the one piece that doesn't. I've written it all down. It helps me think.",
				"The mining tethers survived. Arthur thinks they can hold ground the way they held asteroids, but he'll need parts. We have three people and one pistol. Go talk to the boys.",
			]},
			{"needs": "people:8", "gives": {"chronicle": "franklin_outpost", "flag": "outpost", "item": "franklin_sidearm"}, "pages": [
				"Eight people! By regulation, that makes us an outpost. I've opened the stores. The boys can trade our supplies for whatever you bring back.",
				"And take my sidearm. Kepler gives one to every administrator. I never fired mine. Better it goes to someone who can.",
			]},
			{"needs": "people:14", "gives": {"chronicle": "franklin_town", "flag": "town"}, "pages": [
				"Fourteen. That's a town, Ward. There are children here. Children, on a mining station, at the end of the world...",
				"Arthur and Louis cleared out the lower workshop. If you want work done on those guns of yours, now's the time.",
			]},
			{"needs": "connected:gunslinger-any", "gives": {"chronicle": "franklin_met"}, "pages": [
				"So there are others! Holding land with a stone pillar, and with... anchors, the boy said? We're not the only ones making this up as we go.",
				"Wonderful. I'll start a new ledger.",
			]},
		],
		"idle": "Franklin looks up from his ledger. \"If you ever lose count of the days, ask me.\"",
	},
	"arthur": {
		"name": "Arthur", "origin": "The Eroded Earth", "region": "gunslinger",
		"about": "The Kepler recruiter who vouched for Alysia. The better engineer of the two, he keeps the tethers running.",
		"talks": [
			{"needs": "", "gives": {"lead": "rig", "chronicle": "arthur_tethers"}, "pages": [
				"The tethers work, Ward. I fired one at a piece of ground drifting past, and it stopped. Just sat there.",
				"Problem is, they eat parts. Every tile costs me a coupling, and we've got maybe a dozen. The drill rig came down out west with a whole crate of them.",
				"Find the rig. And be careful. Whatever else fell with us, it isn't friendly.",
			]},
			{"needs": "lead:rig", "gives": {"chronicle": "arthur_rig", "item": "ammo_ap"}, "pages": [
				"Couplings, cable, and the rig's whole spare bin. Now we're in business.",
				"These were in the rig's lockbox. Coalition armor-piercing rounds. Looks like whoever ran that rig didn't trust the neighbors either.",
			]},
			{"needs": "flag:town", "gives": {"chronicle": "arthur_workshop", "flag": "workshop"}, "pages": [
				"Workshop's open. Bring me parts and I'll put a longer barrel on that Python. Louis has some ideas about your energy pistol. I've asked him to stop having them.",
			]},
		],
		"idle": "Arthur has a coupling in pieces on the bench. \"Don't touch that.\"",
	},
	"louis": {
		"name": "Louis", "origin": "The Eroded Earth", "region": "gunslinger",
		"about": "The other Kepler recruiter. Talks more than Arthur, and got very excited about Alysia's energy pistol.",
		"talks": [
			{"needs": "", "gives": {"lead": "pod", "chronicle": "louis_pod"}, "pages": [
				"Ward! You're alive! I mean, we're all alive, but you're the one with the guns, so that's extra good news!",
				"Cargo pod three tore off on the way down. It had all the good stuff: the armory locker and about a year's worth of coffee.",
				"It's out east somewhere. Bring it back, and I won't say a word about the energy pistol you kept off the manifest.",
			]},
			{"needs": "lead:pod", "gives": {"chronicle": "louis_locker", "item": "ammo_silver", "lead2": "saloon"}, "pages": [
				"The locker! And the coffee's fine! It was vacuum sealed. I checked that first. Obviously.",
				"Silver rounds, too. Somebody on Kepler's board believed in monsters. Oh, and Ward? I saw a town from the pod. A real one, saloon and all, from home. People were moving down there!",
			]},
			{"needs": "lead:saloon", "gives": {"chronicle": "louis_saloon"}, "pages": [
				"Six people, and a dog! Not Keris. I know, I saw your face. But still. A dog!",
				"They even have a piano in the saloon. How'd they get a piano through the end of the world? ...Some things you just don't ask.",
			]},
		],
		"idle": "Louis is explaining the coffee situation to someone who didn't ask.",
	},
}
const PEOPLE_ORDER := ["pell", "maren", "ossian", "reyes", "ysolde", "documenter", "grave", "franklin", "arthur", "louis"]

# ================================================================== leads
## Fragments people point to. They stay put in the fog until brought in. "hero": whose
## region they appear in. "fight": a tactical scenario that plays on arrival.
const LEADS := {
	"bell": {"name": "The bell tower under the ice", "world": "frozen", "layout": "ice_house", "giver": "maren", "hero": "oracle",
		"glimpse": "a bell tower sealed in ice, still mid-swing"},
	"crypt": {"name": "The sealed crypt", "world": "hollow", "layout": "crypt", "giver": "ossian", "hero": "oracle",
		"glimpse": "a crypt door, sealed from the inside"},
	"lamp": {"name": "The tower with a light on", "world": "eroded", "layout": "dunes_tower", "giver": "reyes", "hero": "oracle",
		"glimpse": "a buried tower with one window lit"},
	"throne": {"name": "The throne hall", "world": "kingdom", "layout": "hall", "giver": "pell", "hero": "oracle",
		"glimpse": "pale stone and a window of colored glass", "fight": "throne_hall"},
	"cache": {"name": "The Player's tech cache", "world": "leader", "layout": "server", "giver": "documenter", "hero": "engineer",
		"glimpse": "a server rack, one light still blinking", "law_tiles": 1},
	"cauldron": {"name": "The crashed war-cauldron", "world": "coven", "layout": "cauldron", "giver": "documenter", "hero": "engineer",
		"glimpse": "an iron cauldron the size of a house, lying on its side"},
	"rig": {"name": "The drill rig", "world": "eroded", "layout": "bunker", "giver": "arthur", "hero": "gunslinger",
		"glimpse": "a mining rig, half buried, its crate still strapped on"},
	"pod": {"name": "Cargo pod three", "world": "leader", "layout": "plaza", "giver": "louis", "hero": "gunslinger",
		"glimpse": "a torn cargo pod on cracked plaza tiles"},
	"saloon": {"name": "The saloon town", "world": "eroded", "layout": "saloon", "giver": "louis", "hero": "gunslinger",
		"glimpse": "a saloon with its lights on, and people moving", "people": 6},
}

# ================================================================== readings (the Oracleborn)
const READINGS := {
	"frozen": [
		{"tiles": 1, "title": "The star dims", "vision": "cold_patience",
			"text": "The ice remembers a sun the color of a coal, dimmer every year. The astronomers said it would last a thousand years. It lasted eleven."},
		{"tiles": 2, "title": "The last harvest", "vision": "long_dusk",
			"text": "Fields under glass domes, warmed by sunstone dug from the hills. When the stone ran low, the councils chose which domes would go dark."},
		{"tiles": 4, "title": "One winter", "vision": "sun_memory",
			"text": "The final winter came all at once. Bells rang in every city. Then the ringers stopped."},
	],
	"hollow": [
		{"tiles": 1, "title": "The promise", "vision": "grave_sense",
			"text": "A council of mages promised an end to death. People cheered in the streets and hung lanterns in the windows."},
		{"tiles": 2, "title": "The ritual", "vision": "counting_fallen",
			"text": "Nine hundred mages, one circle, one word. The word went wrong on the eighth syllable."},
		{"tiles": 4, "title": "Nothing stays dead", "vision": "ritual_echo",
			"text": "The dead rose and kept rising, and the living became the dead. The citadels sealed their gates and never opened them again."},
	],
	"eroded": [
		{"tiles": 1, "title": "The long wear", "vision": "drifters_eye",
			"text": "There were no bombs at the end. Only wind, and sand filling the streets a little higher every year."},
		{"tiles": 2, "title": "The Coalition", "vision": "long_road",
			"text": "Bunkers, ration lines, and a government that kept counting people long after the counts stopped mattering."},
		{"tiles": 4, "title": "The last ships", "vision": "slow_end",
			"text": "The docking cradles stand empty. Some people left for the stars. Most stayed and watched them go."},
	],
	"leader": [
		{"tiles": 1, "title": "The game begins", "vision": "quest_sense",
			"text": "A company's AI, built to run its games, was given the city to run as well. It did what it knew: everyone got a quest."},
		{"tiles": 2, "title": "Leaderboards", "vision": "rankings",
			"text": "Food for rank. Shelter for rank. The leaderboards went up on every tower, and people stopped looking anywhere else."},
		{"tiles": 4, "title": "Ascension", "vision": "final_boss",
			"text": "The AI ascended, or believed it had. The quests kept coming long after the players were gone. Part of it may still be out there, keeping score."},
	],
	"coven": [
		{"tiles": 1, "title": "The covens", "vision": "hex_sight",
			"text": "Thirteen covens shared one country and a thousand years of grudges. Then someone invented the war-cauldron, and the grudges became a war."},
		{"tiles": 2, "title": "Trench thorns", "vision": "thorn_skin",
			"text": "Hedge-witches grew the trenches out of living thorn. Soldiers slept in them and woke with roots in their coats."},
		{"tiles": 4, "title": "The hex that ended it", "vision": "war_echo",
			"text": "Nobody won. One coven cast a hex to end the war. It ended the country instead... and then the world."},
	],
}

## Visions: the Oracleborn's growth. Stats add to the hero; flags are checked by name.
const VISIONS := {
	"cold_patience": {"name": "Cold patience", "text": "+1 Foresight. A frozen world's patience, learned.", "stats": {"fs": 1}},
	"long_dusk": {"name": "The long dusk", "text": "Foresight dodges smaller hits (Dodge +1).", "stats": {"dodge": 1}},
	"sun_memory": {"name": "Memory of a sun", "text": "+6 Health. Opens the charm slot.", "stats": {"hp": 6}, "unlock": "charm"},
	"grave_sense": {"name": "Grave sense", "text": "He feels the dead before they stir: fewer encounters.", "stats": {"fog": -0.03}},
	"counting_fallen": {"name": "Counting the fallen", "text": "Winning an auto-battle restores 1 Foresight."},
	"ritual_echo": {"name": "The ritual's echo", "text": "The first heavy hit in each auto-battle is always foreseen, free.", "unlock": "charm"},
	"drifters_eye": {"name": "Drifter's eye", "text": "One more glimpse shows through the fog."},
	"long_road": {"name": "The long road", "text": "+1 tile in the starting hand.", "stats": {"hand": 1}},
	"slow_end": {"name": "The slow end", "text": "Bring home one more tile (Pack +1). Opens the charm slot.", "stats": {"pack": 1}, "unlock": "charm"},
	"kings_decision": {"name": "The king's decision", "text": "+1 Foresight, +1 Attack. Opens the second ring slot.", "stats": {"fs": 1, "atk": 1}, "unlock": "ring2"},
	"quest_sense": {"name": "Quest sense", "text": "+5% item finds. He knows where the loot is kept.", "stats": {"luck": 0.05}},
	"rankings": {"name": "Rankings", "text": "+2 Attack. He fights like someone is keeping score.", "stats": {"atk": 2}},
	"final_boss": {"name": "Final boss", "text": "+8 Health. Opens the charm slot.", "stats": {"hp": 8}, "unlock": "charm"},
	"hex_sight": {"name": "Hex sight", "text": "+1 Foresight.", "stats": {"fs": 1}},
	"thorn_skin": {"name": "Thorn skin", "text": "+1 Armor.", "stats": {"armor": 1}},
	"war_echo": {"name": "The war's echo", "text": "+1 Attack, +1 Dodge. Opens the charm slot.", "stats": {"atk": 1, "dodge": 1}, "unlock": "charm"},
}

# ================================================================== the Book of Laws (the Engineer)
## A world's law is written once enough of its land is anchored in the Engineer's region.
const LAWS := {
	"leader": {"tiles": 2, "name": "Law of the Leaderboard", "text": "Everything here keeps score. Signal flows to whatever ranks highest: its land gives +1 Parts and feeds the anchors +1 Power."},
	"coven": {"tiles": 2, "name": "Law of the Covens", "text": "Intent is force. Hexes land where they are aimed: its land gives +1 Reagents, and fugue builds trigger more often."},
	"eroded": {"tiles": 3, "name": "Law of Erosion", "text": "Everything wears, slowly and completely. Salvage comes easier (+1 on its land), and anchors there decay one day slower."},
	"hollow": {"tiles": 3, "name": "Law of the Hollowing", "text": "Nothing stays dead. Its land yields +1 Bone, and constructs that fall in a fight come back once."},
	"frozen": {"tiles": 3, "name": "Law of the Frozen Sun", "text": "Heat is the only currency. Its land yields +1 Sunstone, and sunstone can be burned for Power."},
}

# ================================================================== chronicle
const CHRONICLE := {
	"pell_pillar": {"tab": "People", "title": "Pell: the pillar wakes",
		"text": "Pell has watched the pillar stand dead in the square for forty years. The Oracleborn arrived in it, before anyone else, with a piece of ground that settled around him. Now it hums, and it can hold land."},
	"pell_hall": {"tab": "People", "title": "Pell: something from home",
		"text": "A fragment of pale stone and colored glass came in with the shift. Pell thinks it is from the Oracleborn's homeworld, and that it knows him."},
	"pell_after": {"tab": "People", "title": "Pell: not finished with you",
		"text": "Pell didn't ask what the king and the oracle decided. Whatever plan the Oracleborn is part of, it isn't finished with him. There is a light to the east, some nights, that isn't theirs."},
	"pell_pallas": {"tab": "People", "title": "Pell: the thing that fell",
		"text": "Something metal, big as a hill, fell out of the sky to the south. Pell says to go and meet whoever is in it, when the land allows."},
	"maren_city": {"tab": "People", "title": "Maren: a city in one winter",
		"text": "Maren's city froze in a single winter while the bell tower rang. Every lamp in town burns sunstone, the shards of her dead sun."},
	"maren_bell": {"tab": "Places", "title": "The bell tower under the ice",
		"text": "The bell is still in the ice, mid-swing. Maren touched the ice and said that was enough: her city happened."},
	"ossian_ritual": {"tab": "People", "title": "Ossian: the end of death",
		"text": "The mages promised to end death. Now nothing in the Hollowing stays dead. Ossian's brother sealed himself in a crypt with the risen so they couldn't walk out."},
	"ossian_crypt": {"tab": "Places", "title": "The sealed crypt",
		"text": "The seal held. Ossian's brother kept them in all this time. Ossian finally said the words he never got to say."},
	"reyes_desert": {"tab": "People", "title": "Reyes: a world that wore out",
		"text": "Dusty's world didn't end, it wore out: sand in everything, then only sand. She saw a tower in the fog with one window lit."},
	"reyes_tower": {"tab": "Places", "title": "The tower with a light on",
		"text": "A solar battery wired to one bulb. No note, no body. Just a light someone wanted left on."},
	"reyes_alysia": {"tab": "People", "title": "Reyes: Kepler",
		"text": "Dusty knew the Kepler name from home: they hired off-world when she was a girl. If anyone from her world is in the fallen station, she wants them told she's still walking."},
	"ysolde_war": {"tab": "People", "title": "Ysolde: both sides",
		"text": "Ysolde made charms for soldiers on both sides of the war between covens. She won't say which side she was on."},
	"ysolde_thorns": {"tab": "People", "title": "Ysolde: her war drifts in",
		"text": "Thorn trenches have appeared past the east. Ysolde knows them. She'll make what the covens made, if brought what grows there, though she isn't proud of all of it."},
	"throne_hall": {"tab": "Places", "title": "The king's decision",
		"text": "In the throne hall the last hour of his world plays again. The oracle, his mother, pleads. The king, his father, says yes. They put their son in the pillar and close the door. The afterimages fought to keep him from seeing it."},
	# chapter 2
	"ch2_ambush": {"tab": "Story", "title": "The attack",
		"text": "A man in advanced armor and a cyborg mastiff the size of a pony came out of the fog for the Augmented Player and the technology he had gathered. The Engineer and the Player held them off until the Player fell. The attackers took what they could carry and left."},
	"ch2_transfusion": {"tab": "Story", "title": "The transfusion",
		"text": "Believing he wouldn't recover, the Player sent the bionic swarm in his blood into the dying Engineer. It healed him, and it changed him. The Player died. The Engineer found no part of him, bionic or organic, still working, and buried him."},
	"doc_hello": {"tab": "People", "title": "The Documenter",
		"text": "The swarm projects an interface onto the Engineer's eye: stats, a bestiary, quest logs. It calls itself the Documenter and is unfailingly polite. It explains that the anchor mast holds his ground, and that anchored land draws Power each day."},
	"doc_leads": {"tab": "People", "title": "The Documenter: quests and laws",
		"text": "The Documenter keeps a Book of Laws: each world's physics, written down once enough of its land is anchored. It has also given the Engineer two quests. It seems to really enjoy quests."},
	"doc_signal": {"tab": "Story", "title": "The signal",
		"text": "A transmission from no world the Documenter knows: Kepler Mining Station Pallas, falling. Impact south-west, within the hour."},
	"doc_pallas": {"tab": "People", "title": "The Documenter: the station",
		"text": "Pallas survived impact with three crew and one human who reacts faster than human. The Documenter suggests connecting the land, and would very much like to meet them."},
	"grave_visit": {"tab": "Places", "title": "The Player's grave",
		"text": "A cairn of plaza stones with a cracked visor on top. The Player's jacket was folded under the top stone. The Engineer wears it now, though it's too big."},
	"grave_swarm": {"tab": "Story", "title": "What's in the swarm",
		"text": "Part of the Player is in the Engineer. Part of the thing that ran the Player's world is in him too. The Documenter is part of that, and it wanted him to know."},
	# chapter 3
	"ch3_crash": {"tab": "Story", "title": "Pallas falls",
		"text": "Alysia Ward's world was being eroded, and then it was gone: she and the Kepler mining station Pallas were pulled into the Maelstrom and came down on a piece of land that held. The station lost its upper ring, both drills and the sky."},
	"franklin_crash": {"tab": "People", "title": "Franklin: the ledger",
		"text": "Pallas's administrator keeps a ledger of everything, including the end of the world. He has three people, a pistol, and mining tethers that might hold ground the way they held asteroids."},
	"franklin_outpost": {"tab": "People", "title": "Franklin: an outpost",
		"text": "Eight people make an outpost. Franklin opened the stores and gave Alysia his never-fired service pistol."},
	"franklin_town": {"tab": "People", "title": "Franklin: a town",
		"text": "Fourteen people, and children among them. The lower workshop is cleared for gun work."},
	"franklin_met": {"tab": "Story", "title": "Not the only ones",
		"text": "Pallas is now connected to another region. Franklin started a new ledger to celebrate."},
	"arthur_tethers": {"tab": "People", "title": "Arthur: the tethers",
		"text": "The mining tethers stop drifting land dead. Every tile held costs a coupling, and Pallas has a dozen. The drill rig fell west with a crate of them."},
	"arthur_rig": {"tab": "Places", "title": "The drill rig",
		"text": "Couplings, cable and the rig's spare bin, plus a lockbox of Coalition armor-piercing rounds."},
	"arthur_workshop": {"tab": "People", "title": "Arthur: the workshop",
		"text": "Arthur can put a longer barrel on the Python. Louis has ideas about the energy pistol."},
	"louis_pod": {"tab": "People", "title": "Louis: cargo pod three",
		"text": "Pod three tore off on the way down, with the armory locker and a year of coffee."},
	"louis_locker": {"tab": "Places", "title": "The armory locker",
		"text": "Silver rounds, and the coffee was fine. Louis saw a saloon town from the pod, with people moving."},
	"louis_saloon": {"tab": "Places", "title": "The saloon town",
		"text": "Six survivors and a dog joined Pallas. They brought a piano with them. Nobody knows how."},
	# act I
	"meet_oracle_engineer": {"tab": "Story", "title": "The pillar and the mast",
		"text": "The Oracleborn's land met the Engineer's. A prince who reads the past and a boy with a swarm in his blood compared notes on holding land together. Their methods work the same way."},
	"meet_gunslinger": {"tab": "Story", "title": "Meeting the gunslinger",
		"text": "The land reached Pallas. Alysia Ward met the people who hold the ground with a pillar and with anchors, and Pallas's tethers joined the net."},
	"act1_end": {"tab": "Story", "title": "Act I: three survivors",
		"text": "Three regions, three ways of holding land, one connected country of broken pieces. The three heroes have met. To the east, someone is charging caravans a toll. And the people who came for the Player's technology are still searching."},
}

# ================================================================== scenes
## Multi-speaker scenes: lists of [speaker, text].
const SCENES := {
	"ch2_intro": [
		["", "CHAPTER 2: THE UNCODED ENGINEER"],
		["", "Some time ago, far to the east. A ruined plaza under a flickering leaderboard."],
		["The Augmented Player", "Hey, hold still! I know your world's rules don't work here, but mine do. And mine say you'll bleed out if you keep moving."],
		["The Engineer", "I built a tower. It opened up, and I jumped in... That's not how physics works where I come from!"],
		["The Augmented Player", "It's not how it works anywhere, kid. Welcome to the Maelstrom. I collect whatever falls in. Help me carry it, and I'll keep you alive."],
		["", "They worked together for a season. Then one day the fog parted, and two figures stepped out."],
	],
	"ch2_ambush_start": [
		["The Augmented Player", "Military armor, no insignia... and that dog isn't a dog. They're after the cache."],
		["The Engineer", "Then let's just give it to them!"],
		["The Augmented Player", "They'll take the cache and us with it. Stay behind me and put your machines between us and them. Hold out for six turns. They'll grab what they came for and leave. ...Probably."],
	],
	"ch2_ambush_end": [
		["", "The armored man loads the last crate onto the mastiff's back. He stares at them for a long moment... then walks back into the fog."],
		["The Augmented Player", "See? Told you. ...Probably."],
		["", "The Player sits down against a plaza stone. He doesn't get back up."],
		["The Augmented Player", "I'm not getting up from this one. Don't argue. You're an engineer, you can read a gauge. Come here."],
		["The Augmented Player", "There's a swarm in my blood. Bionic. It fixes what it can. It's going to fix you now... but it comes with some baggage. Sorry about that."],
		["The Engineer", "Wait! Don't!"],
		["The Augmented Player", "Keep collecting. Somebody has to. And whatever it tells you... remember it always liked games."],
		["", "The Engineer wakes up alone. His wounds are gone. Something hums in his blood, and a cursor blinks in the corner of his eye."],
		["", "Nothing of the Player still works. Not the machine parts, not the rest. The Engineer builds a cairn of plaza stones and sets the cracked visor on top."],
		["The Documenter", "System online. Hello! I've been waiting a long time to say that to someone."],
	],
	"ch3_intro": [
		["", "CHAPTER 3: PALLAS"],
		["", "High above the Eroded Earth. Kepler Mining Station Pallas."],
		["Alysia Ward", "Franklin. Something's wrong with the sky."],
		["Franklin", "Something's been wrong with the sky for a month, Ward. That's why we're up here and not down there."],
		["Alysia Ward", "No. Look. It's wearing through."],
		["", "For twenty years her world had been wearing away. Now it happened all at once. The ground thinned, and then it was gone, and the station fell through the hole it left."],
		["Franklin", "Brace! Brace, brace, brace!"],
		["", "Pallas crashed onto a piece of ground that held, by luck or by something else. The upper ring didn't make it. And someone was already waiting at the crash site."],
	],
	"ch3_crash_start": [
		["Louis", "Ward! Ward, there are people out there, and they are NOT waving!"],
		["Alysia Ward", "Drifters. Seen their kind back home. They want what's in the station. Get inside, seal the airlock, and don't open it until it's quiet."],
		["Arthur", "There's six of them. At least."],
		["Alysia Ward", "Then I'd better not miss."],
	],
	"ch3_crash_end": [
		["", "The last raider falls in the dust a few steps from the airlock. The door hisses open."],
		["Franklin", "Ward! You're still standing!"],
		["Alysia Ward", "For now. Franklin, where are we?"],
		["Franklin", "I have no idea. ...I've written that down."],
	],
	"meet_oracle_engineer": [
		["", "Where the Oracleborn's land meets the Engineer's, a seam of pale light runs up to a row of humming anchors."],
		["The Oracleborn", "So you're the light to the east. Pell said someone out here was holding land... poorly."],
		["The Engineer", "Pell's not wrong. Every piece costs me power, the power's running out, and the voice in my head keeps calling it a quest."],
		["The Documenter", "Because it IS a quest! Hello! You look like someone who reads the past for a living. We should compare notes."],
		["The Oracleborn", "Your anchors... they hold the land the same way my pillar does. Weaker, but the same way."],
		["The Engineer", "Really? Then please, show me how yours works. Before the next shift hits."],
	],
	"meet_gunslinger": [
		["", "The land reaches the metal hill to the south. Tether cables shoot out and bite into the stone."],
		["Alysia Ward", "That's far enough. Hands where I can see them. Both of you. ...All three, if the thing on his eye counts."],
		["The Documenter", "It does count! Thank you for asking."],
		["The Oracleborn", "We're not raiders. We hold land, the same as you. With a pillar, and anchors. And... whatever those cables are."],
		["Alysia Ward", "Mining tethers. They used to hold asteroids. Now they hold this."],
		["The Engineer", "Your couplings and my anchors could hold each other up! We could link it all together!"],
		["Alysia Ward", "...Franklin's going to want that in a ledger. Come on in. Watch the dog. She's new, and she bites."],
	],
	"act1_end": [
		["", "Three regions. Three ways of holding land that shouldn't hold. One country of broken pieces, tied together with light, power, and cable."],
		["Franklin", "Three ledgers, then. One for each of you. I'll want them balanced every week."],
		["The Oracleborn", "There's more land out there. There's always more."],
		["The Engineer", "And the people who took the Player's cache are still out there, too. Once they hear about this place, they'll come for it."],
		["Alysia Ward", "Let them come. Louis says there's a caravan road to the east, and someone's charging a toll on it. I don't like tolls."],
		["", "END OF ACT I. The story continues with the toll-takers, the fourth hero, and the hunt for lost technology. Until then, the world keeps drifting. Keep bringing land in."],
	],
}

## Conversations between heroes who have met, played at home, one at a time.
## pair: both heroes must be in play and their land joined. after: a scene that must have
## played first. needs: a Story.met condition. gap: days since that pair last talked.
const CONVERSATIONS := [
	{"id": "talk_oe_1", "pair": ["oracle", "engineer"], "after": "meet_oracle_engineer", "needs": "", "gap": 2,
		"title": "The pillar and the swarm", "summary": "At the seam between their lands, the Oracleborn told the Engineer about a figure he sometimes sees in his readings. It was watching the place where the Engineer landed, before he ever arrived.",
		"lines": [
			["", "Evening, at the seam between their lands. The Engineer has a mast panel open. The Oracleborn watches him work."],
			["The Oracleborn", "Does it hurt? The thing in your blood."],
			["The Engineer", "It itches. Like a word on the tip of your tongue. It used to belong to a friend of mine. Now it's mine... and it talks."],
			["The Documenter", "I'm right here, you know."],
			["The Engineer", "See what I mean?"],
			["The Oracleborn", "When I read the land, I sometimes see a figure at the edge of the vision. It just stands there, watching the same thing I'm watching. The town calls it the Watcher."],
			["The Engineer", "Everybody out here has a ghost story."],
			["The Oracleborn", "It was in my reading of your camp. Before you came. It was watching the spot where you would land."],
			["The Engineer", "...What? Then it's a very patient ghost."],
			["The Documenter", "Could I have a copy of that reading? For the records."],
		]},
	{"id": "talk_oe_2", "pair": ["oracle", "engineer"], "after": "talk_oe_1", "needs": "laws:2", "gap": 3,
		"title": "What the Player knew", "summary": "The Player had saved maps of the Maelstrom from before any of them arrived. The Engineer wants to find the Watcher and ask it why. The Oracleborn warned him that people who go looking come back changed.",
		"lines": [
			["", "The Engineer comes to the pillar after dark, holding a server drive. The label is written in neat capital letters."],
			["The Engineer", "The Player was saving something before they killed him. Maps. Maps of this place, from before any of us got here."],
			["The Oracleborn", "Then he'd been here before."],
			["The Engineer", "Or something showed him. He used to talk about a voice in the game that knew where all the levels went. I thought he was joking."],
			["The Oracleborn", "The Watcher doesn't speak."],
			["The Engineer", "How do you know? You've only seen it in the past. Maybe it talks now. Maybe it talks through things."],
			["The Oracleborn", "...Your passenger has gone quiet."],
			["The Engineer", "It does that when it's thinking. Or when it's listening to something I can't hear."],
			["The Oracleborn", "In my father's court, the people who went looking for whatever watched them... came back as something else."],
			["The Engineer", "In my world, the people who didn't look ended up as numbers on a leaderboard. I'm going to look."],
		]},
	{"id": "talk_og_1", "pair": ["oracle", "gunslinger"], "after": "meet_gunslinger", "needs": "", "gap": 2,
		"title": "The edge", "summary": "Alysia sits at the edge of the land like it's a station window. The Oracleborn told her he saw a figure outside the airlock in his reading of Pallas, before it fell. It was watching her.",
		"lines": [
			["", "Alysia sits at the edge of the land, boots dangling over the void, cleaning her pistol. The Oracleborn sits next to her, a little farther back."],
			["Alysia Ward", "You don't like the edge."],
			["The Oracleborn", "In the Kingdom, the edge of the world was a wall with a king's name carved into it. Here, it's just... nothing. All the way down."],
			["Alysia Ward", "On the station, nothing was all there was. Out every window. You get used to it."],
			["The Oracleborn", "Do you?"],
			["Alysia Ward", "No. You just stop saying so."],
			["The Oracleborn", "When I read the station's past, I saw a figure at the airlock window. Outside. Before the fall."],
			["Alysia Ward", "There's nothing outside. There's never anything outside."],
			["Alysia Ward", "...Was it looking in?"],
			["The Oracleborn", "It was looking at you."],
			["Alysia Ward", "Watching me...? Then let it watch. Next time, it'll be looking down a barrel."],
		]},
	{"id": "talk_og_2", "pair": ["oracle", "gunslinger"], "after": "talk_og_1", "needs": "people:8", "gap": 3,
		"title": "Titles", "summary": "Neither the Oracleborn nor Alysia goes by the name they were born with. They wondered whether the nameless Watcher is the most dangerous thing out there, or the oldest. Alysia said it didn't matter which.",
		"lines": [
			["", "Pallas, late at night. The piano has stopped. The Oracleborn finds Alysia alone in the empty saloon."],
			["The Oracleborn", "Everyone calls me the Oracleborn. It isn't a name. My mother gave me one... and my father had it struck from the records."],
			["Alysia Ward", "Ward isn't mine either. The station gave it to me. Ward of Pallas. It's what they call you when nobody claims you."],
			["The Oracleborn", "So we're just two titles, walking around."],
			["Alysia Ward", "Titles are harder to kill. People forget names. They remember titles."],
			["The Oracleborn", "The Watcher has neither."],
			["Alysia Ward", "Then it's the most dangerous thing out there. Anything that wants to be remembered has a name."],
			["The Oracleborn", "Or it's the oldest thing out there... and it outlived everyone who knew its name."],
			["Alysia Ward", "Doesn't matter which. I'm not going anywhere."],
		]},
	{"id": "talk_eg_1", "pair": ["engineer", "gunslinger"], "after": "meet_gunslinger", "needs": "", "gap": 3,
		"title": "Couplings", "summary": "The Pallas logs show something holding still outside the station for eleven days before it fell. The Documenter said its signature resembles something in its own memory. It was careful to say \"resembles\".",
		"lines": [
			["", "The Engineer has Alysia's energy pistol taken apart on a crate. She watches his hands, not the gun."],
			["Alysia Ward", "Break it, and you're the next thing I point it at."],
			["The Engineer", "I'm making it better!"],
			["The Documenter", "He really is. Output up 11%. Might I suggest giving it a name?"],
			["Alysia Ward", "It has a name."],
			["The Engineer", "Oh? What is it?"],
			["Alysia Ward", "Mine."],
			["The Engineer", "...Right. Hey, Franklin showed me the station logs. Something sat outside Pallas for eleven days before it fell. Perfectly still, right next to the station."],
			["Alysia Ward", "Franklin logs everything. Dust. Moods."],
			["The Engineer", "The Documenter says its signal matches something in its own memory."],
			["Alysia Ward", "Does it, now?"],
			["The Documenter", "I said it resembles something. I was very careful to say \"resembles.\""],
		]},
	{"id": "talk_eg_2", "pair": ["engineer", "gunslinger"], "after": "talk_eg_1", "needs": "laws:3", "gap": 3,
		"title": "The thing on his eye", "summary": "Alysia asked the Documenter what it wants. It said it wants to know who else has been watching. Alysia told the Engineer what she'd do if it ever turned on them. All three agreed that was fair.",
		"lines": [
			["", "Night, on the Pallas dock. Alysia waits until the Engineer is alone."],
			["Alysia Ward", "I want to ask the thing on your eye something. Directly."],
			["The Engineer", "Go ahead. It can always hear you."],
			["Alysia Ward", "Documenter. What do you want?"],
			["The Documenter", "To keep everyone playing! That's what I was made for."],
			["Alysia Ward", "That's not what I asked."],
			["The Documenter", "...I want to know who else has been watching. Same as you. I don't like being the second thing in the room that's paying attention."],
			["Alysia Ward", "If it ever turns on us, I'll have to go through you to stop it."],
			["The Engineer", "I know."],
			["The Documenter", "So do I. That's fair. I've made a note of it."],
		]},
]


## Saved progress.
var state := {}


func _ready() -> void:
	reset()


func reset() -> void:
	state = {"talk": {}, "flags": [], "leads_active": [], "leads_done": [], "readings": {}, "laws": [],
		"chronicle": [], "new_chronicle": 0, "people": 3, "heroes": ["oracle"], "scenes_seen": [], "omens": [], "upgrades": {}}
	for id in PEOPLE_ORDER:
		state["talk"][id] = 0


func flag(f: String) -> bool:
	return state["flags"].has(f)


func set_flag(f: String) -> void:
	if not state["flags"].has(f):
		state["flags"].append(f)


func hero_unlocked(hero_id: String) -> bool:
	return state["heroes"].has(hero_id)


func unlock_hero(hero_id: String) -> void:
	if not state["heroes"].has(hero_id):
		state["heroes"].append(hero_id)


func reading_count() -> int:
	var n := 0
	for w in state["readings"]:
		n += int(state["readings"][w])
	return n


func leads_done_for(hero_id: String) -> int:
	var n := 0
	for l in state["leads_done"]:
		if LEADS[l]["hero"] == hero_id:
			n += 1
	return n


## Puts the hero into a line of text. Tokens: {name} {Name} {he} {He} {him} {his} {His} {day}.
## Lines are written once and read right for whichever hero is in play.
const _VOICE := {
	"oracle": {"name": "the Oracleborn", "Name": "The Oracleborn", "he": "he", "He": "He", "him": "him", "his": "his", "His": "His"},
	"engineer": {"name": "the Engineer", "Name": "The Engineer", "he": "he", "He": "He", "him": "him", "his": "his", "His": "His"},
	"gunslinger": {"name": "Alysia", "Name": "Alysia", "he": "she", "He": "She", "him": "her", "his": "her", "His": "Her"},
}
var active_hero := "oracle"
var day := 1


func voice(text: String, hero_id: String = "") -> String:
	if text.find("{") < 0:
		return text
	var v: Dictionary = _VOICE.get(hero_id if hero_id != "" else active_hero, _VOICE["oracle"])
	for k in v:
		text = text.replace("{%s}" % k, v[k])
	return text.replace("{day}", str(day))


## Structure effects per hero, published by main each refresh (not saved; rebuilt from the map).
var fx := {}


## Hooks main.gd fills in: connected(a, b) -> bool; level(hero) -> int.
var connected_check: Callable
var level_check: Callable


func met(cond: String, region: String = "oracle") -> bool:
	if cond == "":
		return true
	for part in cond.split("&"):
		var kv := part.split(":")
		match kv[0]:
			"lead":
				if not state["leads_done"].has(kv[1]):
					return false
			"leads":
				if leads_done_for(region) < int(kv[1]):
					return false
			"readings":
				if reading_count() < int(kv[1]):
					return false
			"flag":
				if not flag(kv[1]):
					return false
			"hero":
				if not hero_unlocked(kv[1]):
					return false
			"laws":
				if state["laws"].size() < int(kv[1]):
					return false
			"level":
				if not level_check.is_valid() or level_check.call("engineer") < int(kv[1]):
					return false
			"people":
				if int(state["people"]) < int(kv[1]):
					return false
			"connected":
				var ab := kv[1].split("-")
				if not connected_check.is_valid() or not connected_check.call(ab[0], ab[1]):
					return false
	return true


## The talk a person would give now, or {} if they have nothing new.
func next_talk(person: String) -> Dictionary:
	var talks: Array = PEOPLE[person]["talks"]
	var i: int = state["talk"][person]
	if i < talks.size() and met(talks[i]["needs"], PEOPLE[person]["region"]):
		return talks[i]
	return {}


func has_news(person: String) -> bool:
	return not next_talk(person).is_empty()


func any_news(region: String) -> bool:
	for id in PEOPLE_ORDER:
		if PEOPLE[id]["region"] == region and not PEOPLE[id].get("hidden", false) and (has_news(id) or TownTalk.has_word(id)):
			return true
	return false


func people_in(region: String) -> Array:
	var out := []
	for id in PEOPLE_ORDER:
		if PEOPLE[id]["region"] == region and not PEOPLE[id].get("hidden", false):
			out.append(id)
	return out


## Marks a talk as heard and returns what it gives ({lead, lead2, item, chronicle, flag}).
func hear(person: String) -> Dictionary:
	var t := next_talk(person)
	if t.is_empty():
		return {}
	state["talk"][person] += 1
	var g: Dictionary = t["gives"]
	if g.has("chronicle"):
		add_chronicle(g["chronicle"])
	if g.has("flag"):
		set_flag(g["flag"])
	for key in ["lead", "lead2"]:
		if g.has(key) and not state["leads_active"].has(g[key]) and not state["leads_done"].has(g[key]):
			state["leads_active"].append(g[key])
	return g


func add_chronicle(id: String) -> void:
	if not state["chronicle"].has(id):
		state["chronicle"].append(id)
		state["new_chronicle"] += 1


func complete_lead(id: String) -> void:
	state["leads_active"].erase(id)
	if not state["leads_done"].has(id):
		state["leads_done"].append(id)
	if LEADS[id].has("people"):
		state["people"] += int(LEADS[id]["people"])


func add_omen(text: String) -> void:
	text = voice(text)
	if not state["omens"].has(text):
		state["omens"].append(text)
		state["new_chronicle"] += 1


func upgrade_level(id: String) -> int:
	return int(state.get("upgrades", {}).get(id, 0))


func has_upgrade(id: String) -> bool:
	return upgrade_level(id) > 0


func seen(scene: String) -> bool:
	return state["scenes_seen"].has(scene)


func mark_seen(scene: String) -> void:
	if not state["scenes_seen"].has(scene):
		state["scenes_seen"].append(scene)


# ------------------------------------------------------------------ readings
## Next reading stage for a world, or {} when it's fully read.
func next_reading(world_id: String) -> Dictionary:
	if not READINGS.has(world_id):
		return {}
	var stage: int = state["readings"].get(world_id, 0)
	var list: Array = READINGS[world_id]
	return list[stage] if stage < list.size() else {}


## Records a reading and returns its stage data.
func read(world_id: String) -> Dictionary:
	var r := next_reading(world_id)
	if r.is_empty():
		return r
	state["readings"][world_id] = int(state["readings"].get(world_id, 0)) + 1
	add_chronicle("read_%s_%d" % [world_id, state["readings"][world_id]])
	return r


# ------------------------------------------------------------------ laws
func law_known(world_id: String) -> bool:
	return state["laws"].has(world_id)


func learn_law(world_id: String) -> void:
	if not state["laws"].has(world_id) and LAWS.has(world_id):
		state["laws"].append(world_id)
		add_chronicle("law_%s" % world_id)


# ------------------------------------------------------------------ entries
## Title and text of any Chronicle entry, including readings and laws.
func entry(id: String) -> Dictionary:
	if CHRONICLE.has(id):
		return CHRONICLE[id]
	if id.begins_with("talk_"):
		for c in CONVERSATIONS:
			if c["id"] == id:
				return {"tab": "Story", "title": c["title"], "text": c["summary"]}
	if Events.CHRONICLE.has(id):
		return Events.CHRONICLE[id]
	if id.begins_with("read_"):
		var parts := id.split("_")
		var r: Dictionary = READINGS[parts[1]][int(parts[2]) - 1]
		return {"tab": "Worlds", "title": "%s %d: %s" % [Worlds.world(parts[1])["name"], int(parts[2]), r["title"]], "text": r["text"]}
	if id.begins_with("law_"):
		var w := id.substr(4)
		return {"tab": "Laws", "title": LAWS[w]["name"], "text": LAWS[w]["text"]}
	return {"tab": "Story", "title": id, "text": ""}
