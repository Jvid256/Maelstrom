extends Node
## Talk of the town (autoload "TownTalk"). When someone has nothing new for the story, they
## still have something to say: a reaction to what a hero brought back from the road, or a
## rumour of a place out in the fog, which marks that tile's notables known on the map.

## Rumours: how each person tells one. {thing} what's there, {dir} which way, {walk} how far.
const RUMOURS := {
	"pell": [
		"When the fog lifted this morning, I saw something out to the {dir}. {thing}, I think. {walk}. Might be worth a look, lad.",
		"Folks are talking about {thing} to the {dir}. {walk}. Talk's easy. Walking's the hard part.",
	],
	"maren": [
		"From the top of the lamp post, I could see {thing} off to the {dir}. {walk}. Better go before it drifts away!",
		"My lamplight keeps catching on something to the {dir}. {thing}, I think. {walk}.",
	],
	"ossian": [
		"The dead have been restless toward the {dir}! There's {thing} out there. {walk}. Please, go find out what's bothering them.",
		"I salted the {dir} doorstep twice this morning, and the salt turned gray both times! There's {thing} out that way. {walk}.",
	],
	"reyes": [
		"Found tracks heading {dir}. {walk}. They stop at {thing}. ...Tracks don't usually just stop.",
		"Sand in my boots again, and I haven't gone anywhere. Wind's blowing from the {dir}. There's {thing} out there. {walk}.",
	],
	"ysolde": [
		"All my charms turned to face the {dir} last night. There's {thing} out that way. {walk}. If you find anything that hums, bring it to me!",
		"Something to the {dir} is tugging at my hexwood. {thing}, I'd guess. {walk}.",
	],
	"franklin": [
		"A survivor reported {thing}, to the {dir}. {walk}. I've logged it. Someone should really check it out.",
		"Two of our new arrivals passed {thing} on the way in, to the {dir}. {walk}. They didn't stop. I would have.",
	],
	"arthur": [
		"The tether line picked up a tremor to the {dir}. {walk}. There's something out there. {thing}, from the feel of it.",
	],
	"louis": [
		"One of the new folks says there's {thing} to the {dir}! {walk}. They sounded like they didn't want to go back, though.",
	],
}

## Reactions: notable id -> [who, what they say about it once a hero has been there].
const REACTIONS := {
	"tithe_box": ["pell", "Your name was on a tithe list? The king listed everyone, lad. I just don't think he ever expected to need yours."],
	"banner": ["pell", "You stood the banner back up? ...Good. I'd have done the same."],
	"kingdom_echo": ["pell", "A door closing behind you, in your own kingdom's stone? Someone got there first. Be careful, lad."],
	"voice": ["pell", "Something out there called you by your old name? Then it knew you before the pillar did. ...That worries me."],
	"drone_glint": ["pell", "A light in the sky that doesn't drift? I saw one too, years ago. I'd convinced myself I imagined it."],
	"frozen_crowd": ["maren", "All of them facing where the sun used to rise... My grandmother stood like that every morning. Until the morning it didn't come."],
	"ice_figure": ["maren", "A woman holding a sunstone, under the ice? We buried our lamplighters like that. Maybe she was one of us."],
	"sun_dial": ["maren", "A shadow with no light to cast it? Oh, I don't like that at all. Let's not talk about it."],
	"beacon_pulse": ["maren", "It was counting? Then it's counting down. Our beacons never counted up."],
	"drone_tracks": ["maren", "Three-point tracks? Something walked through the town square one night and left marks just like that. I swept them up before anyone saw."],
	"open_grave": ["ossian", "Dug out from the inside?! ...I'm salting every doorstep in town tonight."],
	"graves_names": ["ossian", "One name carved deeper than the rest? Someone wants it remembered. Whatever you do, don't say it out loud!"],
	"crypt_knock": ["ossian", "It knocked back?! Then it was waiting a long time for an answer. ...I'm glad you gave it one."],
	"lantern_window": ["ossian", "Those lanterns went up the year death ended. If one's still lit... someone out there still believes in it."],
	"ossuary_niche": ["ossian", "A blank skull, waiting for a name? Don't go back there. Please. Let it wait for someone else."],
	"drone_lens": ["ossian", "A glass eye in a dead machine, watching the road? That's unnatural! Even the dead don't need glass to watch."],
	"buried_car": ["reyes", "Buried up to the windows, huh? Back home, we'd say they drove till the road ran out. We said that about a lot of people."],
	"radio": ["reyes", "Someone listening on a dead channel... That's how it started back home. First the listening. Then the knocking."],
	"billboard": ["reyes", "412 days under a billboard. I made it 300 under a bridge. Don't feel sorry for them. Feel sorry for day 413."],
	"the_car": ["reyes", "A family car in the sand? Keep going back to it. Things like that change out there. Someone ought to see how it ends."],
	"charm_tree": ["ysolde", "Soldiers' charms! They hung them so their families could find them. Nobody ever came. Bring me one next time, would you?"],
	"cauldron_smoke": ["ysolde", "A sigil burning through iron? That's a war-spell, written slowly so nobody would notice. Well! Somebody noticed."],
	"salt_circle": ["ysolde", "Broken from the inside? Whatever was in there, it was locked up for a good reason."],
	"witch_jar": ["ysolde", "You left the jar alone? Smart. Some of us seal things in jars for a reason."],
	"the_chapel": ["ossian", "A chapel with its bell underneath the land?! Go back. That bell will ring eventually, and it's better if it's you who rings it."],
	"respawn_pad": ["franklin", "A pad that scans for you? We had one at the station airlock. It never found the people we lost, either."],
	"quest_popup": ["franklin", "A quest board with your name on it? I'd log it, but I have no idea which column it goes in."],
	"marker_flag": ["arthur", "A Pallas survey flag? We never surveyed down here. We never had the chance. ...So who did?"],
	"dropped_drone": ["louis", "A drone that watched you walk around it?! Don't bring it back here. Please. I'm begging you."],
	"the_terminal": ["franklin", "A terminal waiting for a second player? Go back to it. I'd like to know who the first one was."],
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
	var walk := "Not too far" if tiles <= 4 else ("About a day's walk" if tiles <= 7 else "Two days' walk, maybe more")
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
