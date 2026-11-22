extends Node
## Talk of the town (autoload "TownTalk"). When someone has nothing new for the story, they
## still have something to say: a reaction to what a hero brought back from the road, or a
## rumour of a place out in the fog, which marks that tile's notables known on the map.

## Rumours: how each person tells one. {thing} what's there, {dir} which way, {walk} how far.
const RUMOURS := {
	"pell": [
		"Saw something out to the {dir} when the fog lifted this morning. {thing}, I think. {walk}. Don't ask me what it means. I never know what anything means.",
		"There's talk of {thing} to the {dir}. {walk}. Talk's cheap. Walking isn't.",
	],
	"maren": [
		"From the top of the lamp post I could see {thing}, off to the {dir}. {walk}. Go before it drifts.",
		"My lamplight catches on something out to the {dir}. {thing}, if I had to guess. {walk}.",
	],
	"ossian": [
		"The dead have been restless toward the {dir}. There's {thing} out there. {walk}. Go and find out why they mind it.",
		"I salted the {dir} doorstep twice this morning and the salt went grey both times. {thing} out that way. {walk}.",
	],
	"reyes": [
		"Tracks headed {dir}. {walk}. They stop at {thing}. Tracks don't usually stop.",
		"Sand in my boots again, and I haven't been anywhere. Wind's from the {dir}. There's {thing} out there. {walk}.",
	],
	"ysolde": [
		"My charms all turned to face the {dir} last night. There's {thing} out that way. {walk}. Bring me back anything that hums.",
		"Something to the {dir} is pulling at the hexwood. {thing}, I'd say. {walk}.",
	],
	"franklin": [
		"Survivor report: {thing}, bearing {dir}. {walk}. I've logged it. Somebody ought to read the log.",
		"Two of the new arrivals passed {thing} on their way in, to the {dir}. {walk}. They didn't stop. I would have.",
	],
	"arthur": [
		"Tether line picked up a tremor to the {dir}. {walk}. Something's out there. {thing}, by the feel of it.",
	],
	"louis": [
		"One of the new folk says there's {thing} to the {dir}. {walk}. They said it like they didn't want to go back.",
	],
}

## Reactions: notable id -> [who, what they say about it once a hero has been there].
const REACTIONS := {
	"tithe_box": ["pell", "A tithe box with your name on the list? The king listed everyone. He just never expected to need yours."],
	"banner": ["pell", "You stood the banner up. I'd have done the same. Don't tell anyone I said so."],
	"kingdom_echo": ["pell", "A door closing behind you in that stone. Whoever it was got there first. They'll keep getting there first."],
	"voice": ["pell", "Something out there used your old name? Then it knew you before the pillar did. Think about that."],
	"drone_glint": ["pell", "A light up high that doesn't drift. I saw one too, years ago. I'd convinced myself I imagined it."],
	"frozen_crowd": ["maren", "All facing where the sun rose. My grandmother stood like that every morning, until the morning it didn't come."],
	"ice_figure": ["maren", "A woman with a sunstone, under the ice. We buried lamplighters like that at home. I'd like to think she was one of ours."],
	"sun_dial": ["maren", "A shadow with no light to cast it. Don't tell me any more. I have lamps to keep."],
	"beacon_pulse": ["maren", "Counting? Then it's counting down. Our beacons never counted up."],
	"drone_tracks": ["maren", "Three-point tracks. Something walked straight across the square once, in the night, and left the same marks. I swept them up before anyone woke."],
	"open_grave": ["ossian", "Dug out from inside, and tidied? That's a considerate corpse. Most of them leave a mess."],
	"graves_names": ["ossian", "One name cut deeper. Someone wants it remembered, or wants it found. Either way, don't say it aloud."],
	"crypt_knock": ["ossian", "It knocked back? Then it had been waiting a long time for an answer, and you gave it one. Good."],
	"lantern_window": ["ossian", "Those lanterns went up the year death ended. If one's still lit, someone still believes it did."],
	"ossuary_niche": ["ossian", "A blank skull, waiting. Don't go back for it. Let someone else fill it."],
	"drone_lens": ["ossian", "A lens in a dead machine, pointed at the road. The dead watch the roads too, but they don't need glass for it."],
	"buried_car": ["reyes", "Buried to the windows. Back home we'd say they drove till the road ran out. We said it about a lot of people."],
	"radio": ["reyes", "Somebody listening on a dead channel. That's how it started, at home. Listening first. Then the knocking."],
	"billboard": ["reyes", "Four hundred and twelve days under a billboard. I made three hundred under a bridge. Don't feel sorry for them. Feel sorry for day four hundred and thirteen."],
	"the_car": ["reyes", "A family car, out in the sand. Keep going back to it. Things like that don't sit still out there, and somebody ought to see how it ends."],
	"charm_tree": ["ysolde", "Soldiers' charms. They hung them so their families could find them. Nobody came. Bring me one next time."],
	"cauldron_smoke": ["ysolde", "A sigil burning through iron? That's a war-spell, written slowly so nobody would notice. Somebody noticed. You."],
	"salt_circle": ["ysolde", "Broken from inside. Whatever was kept in it was kept in for a reason."],
	"witch_jar": ["ysolde", "You left the jar. Good. Some of us keep things in jars for a reason."],
	"the_chapel": ["ossian", "A chapel with its bell underneath. Go back. Bells get rung eventually, and it's better if it's you."],
	"respawn_pad": ["franklin", "A pad that checks for you. We had a scanner at the station airlock that did that. It never found the people we lost, either."],
	"quest_popup": ["franklin", "A quest board with your name on it. I'd log it, but I don't know which column it goes in."],
	"marker_flag": ["arthur", "A Pallas survey flag? We never surveyed down here. We never got the chance. Somebody did."],
	"dropped_drone": ["louis", "A drone that watched you walk round it? Don't bring it back here. Please."],
	"the_terminal": ["franklin", "A terminal waiting for a second player. Go back to it. I'd like to know who the first one was."],
}

const RUMOUR_CHANCE := 0.55


func _news() -> Array:
	if not Story.state.has("town_news"):
		Story.state["town_news"] = []
	return Story.state["town_news"]


func _given() -> Array:
	if not Story.state.has("town_given"):
		Story.state["town_given"] = []
	return Story.state["town_given"]


## A hero examined something on the road: someone in town may have a word about it.
func note_examined(id: String) -> void:
	if not REACTIONS.has(id) or _given().has(id):
		return
	_given().append(id)
	_news().append([REACTIONS[id][0], REACTIONS[id][1]])


## Does this person have a reaction waiting?
func has_word(person: String) -> bool:
	if not Story.PEOPLE.has(person) or not Story.hero_unlocked(Story.PEOPLE[person]["region"]):
		return false
	for n in _news():
		if n[0] == person:
			return true
	return false


## Takes the person's waiting reaction, if they have one.
func take_word(person: String) -> String:
	for i in range(_news().size()):
		if _news()[i][0] == person:
			var text: String = _news()[i][1]
			_news().remove_at(i)
			return text
	return ""


## Fills a rumour in the person's voice.
func rumour_text(person: String, thing: String, dir: String, tiles: int, rng: RandomNumberGenerator) -> String:
	var lines: Array = RUMOURS.get(person, RUMOURS["pell"])
	var line: String = lines[rng.randi_range(0, lines.size() - 1)]
	var walk := "Not far" if tiles <= 4 else ("About a day out" if tiles <= 7 else "Two days out, maybe more")
	var t := thing.substr(0, 1).to_lower() + thing.substr(1)
	line = line.replace("{dir}", dir).replace("{walk}", walk)
	# {thing} may open a sentence or sit inside one
	for lead in ["\"", ". ", "? ", "! "]:
		line = line.replace(lead + "{thing}", lead + thing)
	if line.begins_with("{thing}"):
		line = thing + line.substr(7)
	return line.replace("{thing}", t)


static func compass(from: Vector2, to: Vector2) -> String:
	var v := to - from
	var a := fposmod(rad_to_deg(atan2(v.y, v.x)) + 90.0, 360.0)  # 0 = north
	var names := ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]
	return names[int(roundf(a / 45.0)) % 8]
