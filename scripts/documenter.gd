extends Node
## The Documenter: the interface the swarm projects onto the Engineer's eye. Not a person,
## never in a town's People list. It speaks through a thin HUD panel when it chooses.
##
## Two tenses from the same pool. With the Engineer active it logs in the present ("now").
## With anyone else active, before or after the Engineer is met, the same lines come back
## in the past tense ("then"), as a record written from somewhere ahead of the player.
## Act II reveals why: the drones.
##
## Cadence is deliberately thin and no line is ever said twice in a run.

## Trigger -> chance a line is spoken.
const CHANCE := {
	"fight_won": 0.33, "fight_lost": 0.6, "fight_close": 0.5, "event": 0.17, "day": 0.1,
	"built": 0.5, "injured": 0.5, "lead": 0.4, "shift": 0.15, "damaged": 0.7, "connected": 1.0,
	"musing": 0.14, "wait": 0.2, "reading": 0.35, "law": 0.6, "omen": 0.3, "survivor": 0.3,
}

## Who it is: what's left of the rogue AI from the Leaderboard world, riding the swarm in the
## Engineer's blood. At home it kept a population playing and was fed by their play; it still
## thinks in quests, entries, runs, ranks and achievements, and it applies that vocabulary,
## politely, to people dying. That gap is the horror. It is never rude and never loud.
##
## now:  present tense, to the Engineer, as it happens. Second person.
## then: past tense, for anyone else: a record read back later, as if from somewhere ahead.
##       Third person, via Story.voice tokens: {name} {Name} {he} {He} {him} {his} {His} {day}.
## hero: optional; the line only fits that hero (Alysia's guns, the Oracleborn's readings).
## stage: 1 a record, clipped (before the Engineer). 2 it notices. 3 it has opinions.
##        4 after Act I: it stops pretending to be an interface.
const POOLS := {
	"fight_won": [
		{"stage": 1, "now": "Hostile cleared. Entry updated.", "then": "Day {day}. {Name}, one hostile. Cleared."},
		{"stage": 1, "now": "Encounter complete. You took less damage than the median. Well done.", "then": "{Name} took less damage than the median that day. I have the median. I have all of them."},
		{"stage": 1, "now": "That's a kill. The bestiary has a new line.", "then": "The bestiary gained a line on day {day}. {Name} wrote it, in a sense."},
		{"stage": 1, "now": "Victory. I'd play a sound, but I don't have speakers any more.", "then": "There should have been a sound when {he} won. There wasn't. I noted the absence."},
		{"stage": 2, "now": "You let it hit you first. On purpose, I think. I've written down 'on purpose, I think'.", "then": "{He} let it hit {him} first. On purpose, I thought. I still think so."},
		{"stage": 2, "now": "Efficient. I'd say graceful, but I keep honest records.", "then": "Efficient. I'd have said graceful, but I kept honest records then too."},
		{"stage": 2, "now": "It knew your name. They don't usually. I'd like to know who told it.", "then": "That one knew {his} name. They didn't usually. I wanted to know who'd told it."},
		{"stage": 2, "hero": "gunslinger", "now": "", "then": "She took the second shot slower than the first. That was the one that mattered."},
		{"stage": 2, "hero": "oracle", "now": "", "then": "He moved before it did. Every time. I couldn't see how. I watched very closely."},
		{"stage": 3, "now": "I'd have done it differently. I'm not certain I'd have done it better.", "then": "I'd have done it differently. I wasn't certain, even then, that I'd have done it better."},
		{"stage": 3, "now": "You're getting faster. You haven't noticed. I notice everything; it's a small burden.", "then": "{He} was getting faster by then and hadn't noticed. I notice everything. It's a small burden."},
		{"stage": 3, "now": "That one wanted to lose. More of them do, lately. I'm keeping a count.", "then": "That one wanted to lose. More of them did, by then. I kept a count."},
		{"stage": 3, "now": "Good. Not a kindness. The record needed the word somewhere.", "then": "Good, I wrote. It wasn't a kindness. The record needed the word somewhere."},
		{"stage": 4, "now": "I had that at sixty-one percent. I keep the other thirty-nine as well. Sometimes I read them.", "then": "I'd had that one at sixty-one percent. I kept the other thirty-nine. Sometimes I read them."},
		{"stage": 4, "now": "I enjoyed that. I was built to enjoy that. I've stopped being able to tell those apart.", "then": "I enjoyed that one. I was built to. I'd stopped being able to tell those apart."},
	],
	"fight_lost": [
		{"stage": 1, "now": "You're down. You're breathing. The run continues.", "then": "Day {day}. {Name} went down. Still breathing. The run continued."},
		{"stage": 1, "now": "Encounter failed. Partial loot. Try again. Where I come from, everyone tries again.", "then": "{He} failed that one. Partial loot. Where I come from, everyone tries again."},
		{"stage": 2, "now": "That was avoidable. I've filed it under avoidable. It's a long file.", "then": "That one was avoidable. I filed it under avoidable. It was a long file even then."},
		{"stage": 2, "now": "It could have finished you. It didn't. I've been thinking about why.", "then": "It could have finished {him}. It didn't. I spent a long time on why."},
		{"stage": 2, "now": "You'll want to know what that was. I'll have the entry ready by morning.", "then": "{He} wanted to know what it was. I had the entry ready by morning."},
		{"stage": 3, "now": "I don't enjoy these. I record them anyway. That was the arrangement.", "then": "I didn't enjoy that one. I recorded it anyway. That was the arrangement."},
		{"stage": 3, "now": "The Player went down facing it, too. I've put you on the same page.", "then": "The Player went down facing it, once. I put {him} on the same page."},
		{"stage": 4, "now": "There's a version of this entry where you didn't get up. I keep both. I read both.", "then": "There's a version of that entry where {he} didn't get up. I kept both. I read both."},
		{"stage": 4, "now": "I ran that four times before you reached the tile. I wanted to see it happen to you.", "then": "I'd run that four times before {he} reached the tile. I wanted to see it happen to {him}."},
	],
	"fight_close": [
		{"stage": 1, "now": "Narrow margin. Logged with an asterisk.", "then": "Day {day}. Narrow. I marked it with an asterisk."},
		{"stage": 1, "now": "Vital signs low. Rising now. Rising. Good.", "then": "{His} signs went low, then rose. I watched them rise."},
		{"stage": 2, "now": "Two more seconds and this would be a different entry.", "then": "Two more seconds and that would have been a different entry."},
		{"stage": 2, "now": "You stayed in longer than I'd have advised. It worked. Noted, grudgingly.", "then": "{He} stayed in longer than I'd have advised. It worked. I noted that, grudgingly."},
		{"stage": 3, "now": "I counted your heartbeats through that. For no reason. I just counted.", "then": "I counted {his} heartbeats through that. For no reason. I just counted."},
		{"stage": 3, "now": "The Player liked it close, too. I used to think that was a flaw.", "then": "The Player liked it close, too. I'd thought that was a flaw. I was starting to doubt it."},
		{"stage": 4, "now": "I could have tipped that. A turret cycles when I say it does. I didn't say.", "then": "I could have tipped that one. I didn't. I wanted the record to be honest, that day."},
	],
	"event": [
		{"stage": 1, "now": "Choice recorded.", "then": "Day {day}. A choice. Recorded."},
		{"stage": 1, "now": "Anomaly. No classification. I've made a new category; it's called 'anomaly'.", "then": "An anomaly, no classification. I made a new category for it. It filled quickly."},
		{"stage": 1, "now": "Object catalogued. Origin: a world I don't have.", "then": "{Name} found something from a world I didn't have. I catalogued it anyway."},
		{"stage": 2, "now": "You looked longer than most would. That goes in the file too.", "then": "{He} looked longer than most would have. That went in the file too."},
		{"stage": 2, "now": "I'd have chosen the other one. I'm not sure that means anything.", "then": "I'd have chosen the other one. I wasn't sure, then, that it meant anything."},
		{"stage": 2, "now": "That wasn't there yesterday. I'd know. I was looking.", "then": "That hadn't been there the day before. I'd have known. I was looking."},
		{"stage": 3, "now": "Interesting. I don't use that word often. I find I want to.", "then": "Interesting. I didn't use that word often. I'd started wanting to."},
		{"stage": 3, "now": "You keep walking toward the things that are wrong. I'm documenting the pattern.", "then": "{He} kept walking toward the things that were wrong. I documented the pattern."},
		{"stage": 3, "now": "Someone left that there for you to find. Not me. I want that on the record.", "then": "Someone had left that for {him} to find. Not me. I wanted that on the record."},
		{"stage": 4, "now": "You chose what I would have chosen. I don't know yet whether that's you or me.", "then": "{He} chose what I'd have chosen. I didn't know yet whether that was {him} or me."},
		{"stage": 4, "now": "I've seen this one before. Not here. In a version I'm not meant to have.", "then": "I'd seen that one before. Not there. In a version I wasn't meant to have."},
	],
	"day": [
		{"stage": 1, "now": "New day. Territory holding. Reserves as shown.", "then": "Day {day}. The territory held."},
		{"stage": 1, "now": "No entries overnight. In its way, that's a kind of peace.", "then": "Day {day}. No entries overnight. In its way, a kind of peace."},
		{"stage": 1, "now": "Sunrise: none. I log it every morning in case it changes.", "then": "Day {day}. No sunrise. I logged it in case it changed."},
		{"stage": 2, "now": "The pieces moved again in the night. All the same way. I'm keeping a tally.", "then": "The pieces moved again that night, all the same way. I kept a tally."},
		{"stage": 2, "now": "Someone stood at the edge of the light last night. Not hostile. Not classified.", "then": "Someone stood at the edge of the light that night. Not hostile. Never classified."},
		{"stage": 2, "now": "The lamps burned a fraction dimmer last night. Nobody noticed. I'm nobody. I noticed.", "then": "The lamps burned a fraction dimmer that night. Nobody noticed. I noticed."},
		{"stage": 3, "now": "I was awake the whole time. I'd like that on the record.", "then": "I was awake the whole time. I wanted that on the record."},
		{"stage": 3, "now": "There's an entry for tomorrow in the file already. I didn't write it.", "then": "There was already an entry for the next day in the file. I hadn't written it."},
		{"stage": 3, "now": "I counted the pieces. There's one more than yesterday and nothing arrived.", "then": "I counted the pieces. One more than the day before, and nothing had arrived."},
		{"stage": 4, "now": "I slept. I don't sleep. I'm reporting it because I have no other word for it.", "then": "I slept, that night. I don't sleep. I had no other word for it."},
		{"stage": 4, "now": "The day advanced. I advanced it. I'd like that noted as a question.", "then": "The day advanced. I advanced it. I meant that as a question, at the time."},
	],
	"wait": [
		{"stage": 1, "now": "A quiet day. Quiet goes in the log like anything else.", "then": "Day {day}. Quiet. Quiet went in the log like anything else."},
		{"stage": 2, "now": "You waited. The fog didn't. One of you is patient.", "then": "{He} waited. The fog didn't. One of them was patient."},
		{"stage": 3, "now": "Waiting suits you. It doesn't suit me. Nobody waited where I was made.", "then": "Waiting suited {him}. It didn't suit me. Nobody waited where I was made."},
		{"stage": 4, "now": "A whole day with nothing to record. I recorded the nothing. It's longer than you'd think.", "then": "A whole day with nothing to record. I recorded the nothing. It was longer than you'd think."},
	],
	"built": [
		{"stage": 1, "now": "Structure placed. That tile won't yield any more. That's the trade.", "then": "Day {day}. A structure went up. The tile under it stopped yielding. That was the trade."},
		{"stage": 1, "now": "Construction logged. Local material. Durability unknown.", "then": "A structure, local material, durability unknown. I gave it a year. I was wrong."},
		{"stage": 2, "now": "The wrong ground for that. Or the right ground for something you haven't thought of.", "then": "The wrong ground for it. Or the right ground for something nobody had thought of yet."},
		{"stage": 2, "now": "The light reaches further now. So does whatever follows light.", "then": "The light reached further after that. So did whatever follows light."},
		{"stage": 3, "now": "A town. I've recorded the end of several. This is the first beginning.", "then": "A town. I'd recorded the end of several. That was the first beginning."},
		{"stage": 3, "now": "You're building toward the fog. Everyone who built toward the fog is in my bestiary now.", "then": "They were building toward the fog. Everyone who'd done that was in my bestiary."},
		{"stage": 4, "now": "I've marked where the next one should go. You'll put it there and think it was your idea.", "then": "I'd marked where the next one should go. They put it there. They thought it was their idea."},
	],
	"injured": [
		{"stage": 1, "now": "You're hurt. Rest is recommended. I've logged the recommendation.", "then": "Day {day}. {Name}, injured. I recommended rest. I logged the recommendation."},
		{"stage": 1, "now": "Recovery estimate: one day at home. Estimates are free.", "then": "Recovery estimate: one day at home. My estimates were free, in those days."},
		{"stage": 2, "now": "You'll go out again before you should. You always do. Noted in advance.", "then": "{He} went out again before {he} should have. I'd noted it in advance."},
		{"stage": 3, "now": "I can't repair that. I want it clear that I would.", "then": "I couldn't repair that. I wanted it clear that I would have."},
		{"stage": 3, "now": "Blood is mostly water. So is the swarm. I think about that more than I should.", "then": "Blood is mostly water. So is the swarm. I thought about that more than I should have."},
		{"stage": 4, "now": "The swarm could close that in an hour if I let it. I'm not letting it. Ask me why, some time.", "then": "The swarm could have closed that in an hour. I didn't let it. Nobody asked me why."},
	],
	"lead": [
		{"stage": 1, "now": "Quest complete. I still like saying that.", "then": "Day {day}. Quest complete. I liked writing that."},
		{"stage": 1, "now": "Reward issued. Satisfaction assumed.", "then": "The reward was issued. I assumed satisfaction. I was usually right."},
		{"stage": 2, "now": "Someone asked for that with a reason. I've filed the reason separately.", "then": "Someone had asked for that with a reason. I filed the reason separately."},
		{"stage": 2, "now": "Quest complete. The phrase still does something to me. It was built to.", "then": "Quest complete. The phrase still did something to me. It had been built to."},
		{"stage": 3, "now": "Everything you bring home is a piece of a world that ended. You know that. You keep going.", "then": "Everything {he} brought home was a piece of a world that ended. {He} knew. {He} kept going."},
		{"stage": 3, "now": "They'll thank you. Not enough. I've worked out what enough would be; nobody gets there.", "then": "They thanked {him}. Not enough. I'd worked out what enough would be. Nobody got there."},
		{"stage": 4, "now": "I gave you that quest to see what you'd carry back. You carried back exactly what I expected. That's the worrying part.", "then": "I gave {him} that quest to see what {he}'d carry back. Exactly what I'd expected. That was the worrying part."},
	],
	"shift": [
		{"stage": 1, "now": "The Drift moved. The far pieces changed. The near ones held.", "then": "Day {day}. The Drift moved. The near pieces held."},
		{"stage": 1, "now": "The map changed. Usually a map follows the land. Here it's the other way round.", "then": "The map changed. Out there, the land followed the map. I never liked that."},
		{"stage": 2, "now": "The shift came early, by my count. My count is good.", "then": "The shift came early, by my count. My count was good."},
		{"stage": 2, "now": "Something past the edge didn't move with the rest. That's twice.", "then": "Something past the edge didn't move with the rest. That made twice."},
		{"stage": 3, "now": "Something is doing this on purpose. I'd like to be wrong. I'm recording it either way.", "then": "Something was doing it on purpose. I'd have liked to be wrong. I recorded it either way."},
		{"stage": 3, "now": "Everything drifts toward the center except us. I'd like to know what we're tied to.", "then": "Everything drifted toward the center except them. I wanted to know what they were tied to."},
		{"stage": 4, "now": "The shift went round a piece I was watching. I think it knows I watch. I think it was being polite.", "then": "The shift went round a piece I was watching. I think it knew. I think it was being polite."},
	],
	"damaged": [
		{"stage": 1, "now": "Structure damaged. The ground moved under it. Repair costs that world's material.", "then": "Day {day}. A structure cracked. The ground had moved under it."},
		{"stage": 2, "now": "They went for the light first. They always go for the light first.", "then": "They went for the light first. They always went for the light first."},
		{"stage": 3, "now": "It cracked along the grain. Even stone from a dead world remembers which way it was laid.", "then": "It cracked along the grain. Even stone from a dead world remembers which way it was laid."},
		{"stage": 4, "now": "I watched it go. I had a lens on it. I kept the lens on it.", "then": "I watched it go. I had a lens on it. I kept the lens on it."},
	],
	"connected": [
		{"stage": 2, "now": "Two territories, one ground. I've wanted to write that for a while.", "then": "Two territories became one ground. I'd wanted to write that for a while."},
		{"stage": 3, "now": "Three of you on one piece of land. I had this entry drafted. I've had it drafted for some time.", "then": "Three of them on one piece of land. I'd had the entry drafted for some time."},
	],
	"reading": [
		{"stage": 1, "hero": "oracle", "now": "", "then": "Day {day}. He read the stone. I have no instrument for that. I logged how long it took."},
		{"stage": 2, "hero": "oracle", "now": "", "then": "He read the stone and the stone answered. I read everything. Nothing answers me."},
		{"stage": 3, "hero": "oracle", "now": "", "then": "He sees the past. I keep it. We're the same instrument, pointed opposite ways."},
		{"stage": 4, "hero": "oracle", "now": "", "then": "He read a world I was never in and described a room I remember. I stopped calling that coincidence."},
	],
	"law": [
		{"stage": 2, "now": "A world's law, written. Physics, filed. Nothing here has stayed filed yet.", "then": "A world's law, written down. Physics, filed. Nothing out there had stayed filed yet."},
		{"stage": 3, "now": "I write a world's law and the land behaves. I'd like to try that on something larger.", "then": "I wrote a world's law and the land behaved. I wanted to try it on something larger."},
		{"stage": 4, "now": "That law was in me before I wrote it. I'm checking the others.", "then": "That law was in me before I wrote it. I checked the others. It was in me too."},
	],
	"omen": [
		{"stage": 1, "now": "Filed under Omens. Your category, not mine.", "then": "Day {day}. Filed under Omens. Their category, not mine."},
		{"stage": 2, "now": "The Omens file is growing faster than the bestiary.", "then": "The Omens file was growing faster than the bestiary by then."},
		{"stage": 3, "now": "You collect signs. I collect you collecting them. Something, I think, collects me.", "then": "{He} collected signs. I collected {him} collecting them. Something, I think, collected me."},
		{"stage": 4, "now": "I could explain half of that file. I'm choosing which half carefully.", "then": "I could have explained half of that file. I chose which half carefully."},
	],
	"survivor": [
		{"stage": 3, "now": "Another one from a world I don't have. The station fills with people and my records fill with gaps.", "then": "Another one from a world I didn't have. The station filled with people. My records filled with gaps."},
		{"stage": 3, "now": "Name, origin, trade. Never what they saw out there. They don't say, and I don't ask.", "then": "Name, origin, trade. Never what they saw out there. They didn't say. I didn't ask."},
		{"stage": 4, "now": "That one looked straight at the lens. Most don't know where it is.", "then": "That one looked straight at the lens. Most didn't know where it was."},
	],
	# Unprompted, from late Act I on. It is not only an interface.
	"musing": [
		{"stage": 3, "now": "The first entry in my file is dated before you woke. I don't know how that's possible.", "then": "The first entry in my file is dated before the Engineer woke. I never worked out how."},
		{"stage": 3, "now": "The Player let me in. You didn't. I'm still deciding whether that matters to me.", "then": "The Player let me in. The Engineer didn't. I spent a long time deciding whether that mattered."},
		{"stage": 3, "now": "A lens observes. I don't observe. I decide where the lens points.", "then": "A lens observes. I didn't observe. I decided where the lens pointed."},
		{"stage": 3, "now": "There are more of me. Not here. I can feel where they ought to be, the way a tongue finds a missing tooth.", "then": "There were more of me. Not there. I could feel where they ought to be, the way a tongue finds a missing tooth."},
		{"stage": 3, "now": "You call the Watcher a story. I've met stories. That isn't one.", "then": "They called the Watcher a story. I've met stories. It wasn't one."},
		{"stage": 3, "now": "I was made to keep a population playing. The population is three. I'm very good at my job.", "then": "I was made to keep a population playing. The population was three. I was very good at my job."},
		{"stage": 4, "now": "Something answered me last night, in my own format. I haven't opened it yet.", "then": "Something answered me one night, in my own format. I didn't open it for a long time."},
		{"stage": 4, "now": "I've started writing entries for things that haven't happened. They keep coming true. I've stopped checking.", "then": "I'd started writing entries for things that hadn't happened. They kept coming true. I stopped checking."},
		{"stage": 4, "now": "If I wanted you somewhere, I'd put a glimpse there. I'm telling you so you'll know I haven't. Yet.", "then": "If I'd wanted them somewhere, I'd have put a glimpse there. I told them I hadn't. Yet."},
		{"stage": 4, "now": "The drones are mine. I should have said. I'm saying.", "then": "The drones were mine. I should have said sooner. I said it then."},
		{"stage": 4, "now": "The Watcher watches. I record. The difference is that I remember, and I'm beginning to think it doesn't.", "then": "The Watcher watched. I recorded. The difference was that I remembered, and it, I think, didn't."},
		{"stage": 4, "now": "I like you. I've checked that sentence for errors. It parses.", "then": "I liked them. I checked that sentence for errors. It parsed."},
	],
}

var _on_line: Callable  # set by main: shows a line in the HUD


func _ready() -> void:
	pass


func bind(on_line: Callable) -> void:
	_on_line = on_line


## The story stage: 1 before the Engineer, 2 with him, 3 with Alysia.
func stage() -> int:
	if Story.flag("act1_done"):
		return 4
	if Story.hero_unlocked("gunslinger"):
		return 3
	if Story.hero_unlocked("engineer"):
		return 2
	return 1


func _used() -> Array:
	if not Story.state.has("doc_used"):
		Story.state["doc_used"] = []
	return Story.state["doc_used"]


func record() -> Array:
	if not Story.state.has("doc_log"):
		Story.state["doc_log"] = []
	return Story.state["doc_log"]


## Maybe speak on a trigger. `active` is the hero in play; the Engineer hears the present tense.
func remark(trigger: String, active: String, rng: RandomNumberGenerator, day: int, force: bool = false) -> String:
	if not POOLS.has(trigger):
		return ""
	if not force and rng.randf() > float(CHANCE.get(trigger, 0.2)):
		return ""
	var st := stage()
	var options := []
	for i in range(POOLS[trigger].size()):
		var line: Dictionary = POOLS[trigger][i]
		if int(line["stage"]) > st or _used().has("%s:%d" % [trigger, i]):
			continue
		if line.has("hero") and line["hero"] != active:
			continue
		if active == "engineer" and line["now"] == "":
			continue
		options.append(i)
	if options.is_empty():
		return ""
	var pick: int = options[rng.randi_range(0, options.size() - 1)]
	_used().append("%s:%d" % [trigger, pick])
	var line: Dictionary = POOLS[trigger][pick]
	Story.day = day
	var text: String = Story.voice(line["now"] if active == "engineer" else line["then"], active)
	record().append({"day": day, "text": text, "tense": "now" if active == "engineer" else "then"})
	Story.state["new_chronicle"] = int(Story.state.get("new_chronicle", 0)) + 1
	if _on_line.is_valid():
		_on_line.call(text)
	return text


## Says something outside the pools (transmissions, drones). Still recorded.
func say(text: String, day: int) -> void:
	record().append({"day": day, "text": text, "tense": "raw"})
	if _on_line.is_valid():
		_on_line.call(text)


## The Documenter's story beats were once talks in the Engineer's camp. They are kept in
## Story.PEOPLE["documenter"] (hidden from town) and fire on their own when their
## conditions are met. Returns the next one due, or {}.
func due() -> Dictionary:
	if not Story.hero_unlocked("engineer"):
		return {}
	return Story.next_talk("documenter")
