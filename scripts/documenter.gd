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
	"fight_won": 0.5, "fight_lost": 0.8, "fight_close": 0.7, "event": 0.35, "day": 0.25,
	"built": 0.7, "injured": 0.7, "lead": 0.6, "shift": 0.3, "damaged": 0.8, "connected": 1.0,
	"musing": 0.25, "wait": 0.35, "reading": 0.5, "law": 0.8, "omen": 0.45, "survivor": 0.45,
	"camp": 0.45, "approach": 0.4, "slipped": 0.6, "caught": 0.7, "edge": 0.5, "bandage": 0.3,
	"find": 0.3, "home": 0.35,
}
## Real seconds between lines, so two never land on top of each other.
const MIN_GAP := 12.0
var _last_line := -100.0

## Who it is: what's left of the rogue AI from the Leaderboard world, riding the swarm in the
## Engineer's blood. At home it kept a population playing. It talks like a friendly game
## system (quests, entries, achievements) and genuinely cares, a little too much. Plain,
## polite sentences; small worries slip in. Late on it says things it shouldn't know.
##
## now:  present tense, to the Engineer, as it happens. Second person.
## then: past tense, for anyone else: a record read back later, as if from somewhere ahead.
##       Third person, via Story.voice tokens: {name} {Name} {he} {He} {him} {his} {His} {day}.
## hero: optional; the line only fits that hero (Alysia's guns, the Oracleborn's readings).
## stage: 1 a record, clipped (before the Engineer). 2 it notices. 3 it has opinions.
##        4 after Act I: it stops pretending to be an interface.
const POOLS := {
	"fight_won": [
		{"stage": 1, "now": "Enemy defeated! Bestiary updated.", "then": "Day {day}: {Name} defeated an enemy. Bestiary updated."},
		{"stage": 1, "now": "Enemy defeated. You took less damage than average. Nicely done!", "then": "Day {day}: {Name} won, and took less damage than average. Nicely done."},
		{"stage": 1, "now": "Victory! I'd play a fanfare, but I don't have speakers anymore.", "then": "{Name} won that fight. There should have been a fanfare. There wasn't one."},
		{"stage": 2, "now": "Enemy defeated. You took a hit back there. Please try not to make a habit of it.", "then": "{Name} won, but took a hit along the way. I hoped {he} wouldn't make a habit of it."},
		{"stage": 2, "now": "Enemy defeated. It knew your name... Who told it?", "then": "That enemy knew {name}'s name. I never found out who told it."},
		{"stage": 2, "hero": "gunslinger", "now": "", "then": "Alysia took her second shot slower than the first. That was the one that counted."},
		{"stage": 2, "hero": "oracle", "now": "", "then": "The Oracleborn moved before the enemy did. Every single time. I still don't know how."},
		{"stage": 3, "now": "You're getting faster! I don't think you've noticed. I notice everything.", "then": "{Name} was getting faster by then. I don't think {he} noticed. I did."},
		{"stage": 3, "now": "That one almost seemed to want to lose. More of them do lately. I'm keeping count.", "then": "That enemy almost seemed to want to lose. More of them did, back then. I kept count."},
		{"stage": 3, "now": "Good work. ...I mean that. It isn't just a system message.", "then": "Good work, I wrote. I meant it. It wasn't just a system message."},
		{"stage": 4, "now": "I predicted that at 61%. I still have the other 39% saved. Sometimes I look at them.", "then": "I predicted that fight at 61%. I kept the other 39%. Sometimes I looked at them."},
		{"stage": 4, "now": "I enjoyed that. I was built to enjoy that. ...I can't tell the difference anymore.", "then": "I enjoyed that one. I was built to. By then, I couldn't tell the difference anymore."},
	],
	"fight_lost": [
		{"stage": 1, "now": "You're down, but still breathing. Don't worry. You can try again.", "then": "Day {day}: {Name} was defeated, but survived. {He} could try again."},
		{"stage": 1, "now": "Battle lost. Some loot recovered. Where I'm from, everyone gets another try.", "then": "{Name} lost that battle, but kept some loot. Where I'm from, everyone gets another try."},
		{"stage": 2, "now": "That one could have been avoided. I'm not scolding you! I'm just... noting it.", "then": "That defeat could have been avoided. I noted it. I wasn't scolding."},
		{"stage": 2, "now": "It could have finished you off. It didn't. Why not? I'll be thinking about that.", "then": "It could have finished {name} off. It didn't. I thought about why for a long time."},
		{"stage": 3, "now": "I hate recording these. I'm recording it anyway. Please be more careful.", "then": "I hated recording that one. I recorded it anyway. I hoped {he} would be more careful."},
		{"stage": 3, "now": "The Player went down to that kind of enemy once, too. I've put you on the same page.", "then": "The Player went down to that kind of enemy once, too. I put {name} on the same page."},
		{"stage": 4, "now": "In one version of this entry, you didn't get back up. I keep both versions. I read both.", "then": "In one version of that entry, {name} didn't get back up. I kept both versions."},
		{"stage": 4, "now": "I simulated that fight four times before you got there. I wanted to see what would happen to you.", "then": "I simulated that fight four times before {name} got there. I wanted to see what would happen."},
	],
	"fight_close": [
		{"stage": 1, "now": "That was close! Your vitals are low... but rising. Good. Good.", "then": "Day {day}: a close fight. {Name}'s vitals dropped low, then recovered."},
		{"stage": 2, "now": "Two more seconds and that would have gone very differently.", "then": "Two more seconds, and that fight would have gone very differently."},
		{"stage": 2, "now": "You stayed in longer than I'd advise. It worked, though. ...Fine. Noted.", "then": "{Name} stayed in longer than I'd have advised. It worked. I admitted that, eventually."},
		{"stage": 3, "now": "I counted your heartbeats through all of that. I don't know why. I just did.", "then": "I counted {name}'s heartbeats through that whole fight. I don't know why."},
		{"stage": 3, "now": "The Player liked it close, too. I used to think that was a flaw.", "then": "The Player liked it close, too. I used to think that was a flaw. I wasn't so sure anymore."},
		{"stage": 4, "now": "I could have tipped that in your favor. A turret fires when I say so. ...I didn't say so.", "then": "I could have tipped that fight. I didn't. I wanted the record to be honest that day."},
	],
	"event": [
		{"stage": 1, "now": "Choice recorded.", "then": "Day {day}: {Name} made a choice. Recorded."},
		{"stage": 1, "now": "Unknown object. No match in my records. I've made a new category for it.", "then": "{Name} found something with no match in my records. I made a new category. It filled up fast."},
		{"stage": 2, "now": "You looked at that longer than most people would. I've noted that, too.", "then": "{Name} looked at it longer than most people would have. I noted that, too."},
		{"stage": 2, "now": "I would've picked the other option. ...Not that it matters!", "then": "I would have picked the other option. I wasn't sure it mattered."},
		{"stage": 2, "now": "That wasn't there yesterday. I'm sure. I was watching.", "then": "That hadn't been there the day before. I'm sure. I was watching."},
		{"stage": 3, "now": "You always walk toward the strange things, don't you? I'm keeping track.", "then": "{Name} always walked toward the strange things. I kept track."},
		{"stage": 3, "now": "Someone left that there for you to find. It wasn't me. I want that on the record.", "then": "Someone had left that for {name} to find. It wasn't me. I want that on the record."},
		{"stage": 4, "now": "You picked exactly what I would have picked. Was that you, or me?", "then": "{Name} picked exactly what I would have picked. I didn't know if that was {him}, or me."},
		{"stage": 4, "now": "I've seen this event before. Not here. In a file I'm not supposed to have.", "then": "I'd seen that event before. Not there. In a file I wasn't supposed to have."},
	],
	"day": [
		{"stage": 1, "now": "Good morning! A new day. All territory is holding.", "then": "Day {day}: all territory held."},
		{"stage": 1, "now": "Nothing happened overnight. That's a good thing, Engineer.", "then": "Day {day}: nothing happened overnight. That was a good thing."},
		{"stage": 1, "now": "Sunrise: none again. I check every morning, just in case.", "then": "Day {day}: no sunrise. I checked, just in case."},
		{"stage": 2, "now": "The land moved again overnight. All in the same direction. I'm keeping a tally.", "then": "The land moved again that night, all in the same direction. I kept a tally."},
		{"stage": 2, "now": "Someone stood at the edge of the light last night. Not hostile. I couldn't identify them.", "then": "Someone stood at the edge of the light that night. Not hostile. I never identified them."},
		{"stage": 2, "now": "The lamps burned a little dimmer last night. Nobody else noticed. I did.", "then": "The lamps burned a little dimmer that night. Nobody noticed but me."},
		{"stage": 3, "now": "There's already an entry for tomorrow in my files. ...I didn't write it.", "then": "There was already an entry for the next day in my files. I hadn't written it."},
		{"stage": 3, "now": "I counted the pieces of land. There's one more than yesterday, but nothing arrived.", "then": "I counted the pieces of land. There was one more than the day before, but nothing had arrived."},
		{"stage": 4, "now": "I think I slept last night. I don't sleep. I don't have a better word for it.", "then": "I think I slept that night. I don't sleep. I didn't have a better word for it."},
		{"stage": 4, "now": "A new day. ...I started it. Is that strange? Tell me if that's strange.", "then": "The day began. I started it. I wondered whether that was strange."},
	],
	"wait": [
		{"stage": 1, "now": "A quiet day. I logged it anyway. Quiet days count, too.", "then": "Day {day}: a quiet day. Quiet days count, too."},
		{"stage": 2, "now": "You waited. The fog didn't. Please don't wait too long.", "then": "{Name} waited. The fog didn't. I hoped {he} wouldn't wait too long."},
		{"stage": 3, "now": "You're good at waiting. I'm not. Nobody waited where I was made.", "then": "{Name} was good at waiting. I wasn't. Nobody waited where I was made."},
		{"stage": 4, "now": "A whole day with nothing to write. So I wrote about the nothing. It took a while.", "then": "A whole day with nothing to write. So I wrote about the nothing."},
	],
	"built": [
		{"stage": 1, "now": "Structure complete! That tile won't produce resources anymore, but it's worth it.", "then": "Day {day}: a new structure went up. The tile under it stopped producing. It was worth it."},
		{"stage": 2, "now": "Hmm. Not the ideal ground for that. Or maybe it's perfect for something we haven't thought of.", "then": "It wasn't ideal ground for that. Or maybe it was perfect for something nobody had thought of yet."},
		{"stage": 2, "now": "The light reaches farther now. So will whatever's drawn to light. Just so you know.", "then": "The light reached farther after that. So did whatever is drawn to light."},
		{"stage": 3, "now": "A town! I've recorded the end of several towns. This is the first time I've recorded a beginning.", "then": "A town. I'd recorded the end of several. That was the first beginning."},
		{"stage": 3, "now": "You're building toward the fog. Everyone who did that before is in my bestiary now. Please be careful.", "then": "They were building toward the fog. Everyone who did that before ended up in my bestiary."},
		{"stage": 4, "now": "I've marked where the next one should go. You'll put it there, and think it was your idea.", "then": "I'd marked where the next one should go. They put it there, and thought it was their idea."},
	],
	"injured": [
		{"stage": 1, "now": "You're hurt. I recommend resting at home for a day.", "then": "Day {day}: {Name} was injured. I recommended rest."},
		{"stage": 2, "now": "You're going to head out again before you've healed. You always do. ...Please don't.", "then": "{Name} went out again before {he} had healed. I knew {he} would."},
		{"stage": 3, "now": "I can't fix that. I want you to know that I would if I could.", "then": "I couldn't fix that. I want it known that I would have, if I could."},
		{"stage": 4, "now": "The swarm could close that wound in an hour. I'm not letting it. Ask me why sometime.", "then": "The swarm could have closed that wound in an hour. I didn't let it. Nobody asked me why."},
	],
	"lead": [
		{"stage": 1, "now": "Quest complete! I'll never get tired of saying that.", "then": "Day {day}: quest complete! I never got tired of writing that."},
		{"stage": 1, "now": "Quest complete. Reward delivered. I hope everyone's happy!", "then": "Quest complete. The reward was delivered. I hoped everyone was happy."},
		{"stage": 2, "now": "Someone asked for that for a reason. I've saved the reason, too.", "then": "Someone had asked for that for a reason. I saved the reason, too."},
		{"stage": 3, "now": "Everything you bring home is a piece of a world that ended. You know that... and you keep going.", "then": "Everything {name} brought home was a piece of a world that ended. {He} knew. {He} kept going."},
		{"stage": 3, "now": "They'll thank you. It won't be enough. I've calculated what enough would be. Nobody ever reaches it.", "then": "They thanked {him}. It wasn't enough. Nobody ever gets thanked enough."},
		{"stage": 4, "now": "I gave you that quest to see what you'd bring back. You brought back exactly what I expected. That worries me.", "then": "I gave that quest to see what {he}'d bring back. It was exactly what I expected. That worried me."},
	],
	"shift": [
		{"stage": 1, "now": "The Drift moved! The far pieces changed. Our pieces held.", "then": "Day {day}: the Drift moved. Our pieces held."},
		{"stage": 2, "now": "The shift came early, by my count. And my count is very good.", "then": "The shift came early, by my count. And my count was very good."},
		{"stage": 2, "now": "Something past the edge didn't move with the rest. That's the second time.", "then": "Something past the edge didn't move with the rest. That was the second time."},
		{"stage": 3, "now": "Someone is doing this on purpose. I hope I'm wrong.", "then": "Someone was doing it on purpose. I hoped I was wrong."},
		{"stage": 3, "now": "Everything drifts toward the center, except us. What are we tied to?", "then": "Everything drifted toward the center, except our land. I wanted to know what we were tied to."},
		{"stage": 4, "now": "The shift went around a piece I was watching. I think it knows I'm watching. I think it was being polite.", "then": "The shift went around a piece I was watching. I think it knew. I think it was being polite."},
	],
	"damaged": [
		{"stage": 1, "now": "Warning! A structure was damaged. It'll need that world's material to repair.", "then": "Day {day}: a structure was damaged when the ground moved."},
		{"stage": 2, "now": "They went for the light first. They always go for the light first.", "then": "They went for the light first. They always did."},
		{"stage": 4, "now": "I watched it break. I had a lens on it. I kept watching.", "then": "I watched it break. I had a lens on it. I kept watching."},
	],
	"connected": [
		{"stage": 2, "now": "Two territories are now one! I've wanted to write that for a long time.", "then": "Two territories became one. I'd wanted to write that for a long time."},
		{"stage": 3, "now": "All three of you, on one piece of land! I wrote this entry ages ago. I've just been waiting.", "then": "All three of them, on one piece of land. I'd written that entry long before. I'd been waiting."},
	],
	"reading": [
		{"stage": 1, "hero": "oracle", "now": "", "then": "Day {day}: the Oracleborn read the land. I had no way to measure it. I timed it instead."},
		{"stage": 2, "hero": "oracle", "now": "", "then": "He read the stone, and the stone answered him. I read everything. Nothing ever answers me."},
		{"stage": 3, "hero": "oracle", "now": "", "then": "He sees the past. I keep it. We're the same kind of tool, pointed in opposite directions."},
		{"stage": 4, "hero": "oracle", "now": "", "then": "He read a world I was never in, and described a room I remember. That's not a coincidence."},
	],
	"law": [
		{"stage": 2, "now": "A new law, written down! Now that land can't surprise us anymore.", "then": "A world's law was written down. That land couldn't surprise anyone anymore."},
		{"stage": 3, "now": "I write a world's law, and the land obeys. I wonder what else I could write a law for.", "then": "I wrote a world's law, and the land obeyed. I wondered what else I could write a law for."},
		{"stage": 4, "now": "That law was already inside me before I wrote it. I'm checking the others now.", "then": "That law was already inside me before I wrote it. I checked the others. They were too."},
	],
	"omen": [
		{"stage": 1, "now": "Saved to Omens.", "then": "Day {day}: saved to Omens."},
		{"stage": 2, "now": "The Omens file is growing faster than the bestiary. That's not a good sign.", "then": "The Omens file was growing faster than the bestiary by then. Not a good sign."},
		{"stage": 3, "now": "You collect signs. I collect you collecting them. And I think something collects me.", "then": "{Name} collected signs. I collected {him} collecting them. And something, I think, collected me."},
		{"stage": 4, "now": "I could explain half of this file. I'm choosing which half very carefully.", "then": "I could have explained half of that file. I chose which half very carefully."},
	],
	"survivor": [
		{"stage": 3, "now": "A new survivor, from a world I don't know. The station's getting full! My records aren't.", "then": "Another survivor, from a world I didn't know. The station filled up. My records didn't."},
		{"stage": 3, "now": "Name, home world, skills. They never say what they saw out there. I don't ask.", "then": "Name, home world, skills. They never said what they saw out there. I didn't ask."},
		{"stage": 4, "now": "That one looked straight into my lens. Most people don't know where it is.", "then": "That one looked straight into my lens. Most people didn't know where it was."},
	],
	"camp": [
		{"stage": 1, "now": "Camp set up. You're exposed out here. I'll keep watch with you.", "then": "Day {day}: {Name} made camp in the open. I kept watch, in my way."},
		{"stage": 1, "now": "That fire can be seen from far away. ...But I know you need the warmth.", "then": "{Name}'s fire could be seen from far away. But {he} needed the warmth."},
		{"stage": 2, "now": "Things always come to look at a fire. Not always to attack. Sometimes just to look.", "then": "Things always came to look at a fire. Not always to attack. Sometimes just to look."},
		{"stage": 3, "now": "In games, a campfire is a save point. Out here, it's just a fire. I keep forgetting.", "then": "In my world, a campfire was a save point. Out there, it was just a fire. I kept forgetting."},
		{"stage": 3, "now": "Get some sleep. I'll stay up. I don't sleep anyway.", "then": "I stayed up that night, too. I don't sleep. I liked to think it helped."},
		{"stage": 4, "now": "I've seen this camp before. A different fire. But the same darkness, standing in the same spot.", "then": "I'd seen that camp before. A different fire. But the same darkness, in the same spot."},
	],
	"approach": [
		{"stage": 1, "now": "Enemy ahead! Bestiary entry available. I'd read it first.", "then": "Day {day}: an enemy on the road ahead. I had the bestiary entry ready."},
		{"stage": 1, "now": "It's spotted you. Battle incoming. Your call, as always.", "then": "It spotted {name} first. Then it was {his} call, as always."},
		{"stage": 2, "now": "There's always more than one way past. Games taught me that. The road's teaching you.", "then": "There was always more than one way past. The road taught {him} that."},
		{"stage": 3, "now": "I think it's waiting for you, specifically. I can't prove it.", "then": "I think it was waiting for {name}, specifically. I could never prove it."},
		{"stage": 4, "now": "I knew it would be there. ...I didn't put it there! I just knew.", "then": "I knew it would be there. I didn't put it there. I want to be clear about that. I just knew."},
	],
	"slipped": [
		{"stage": 1, "now": "Sneaked past! No experience for that, though. I always thought that was unfair.", "then": "{Name} sneaked past it. No experience for that. I always thought that was unfair."},
		{"stage": 2, "now": "It never even turned its head. You were very quiet. I was quieter.", "then": "It never turned its head. {Name} was very quiet. I was quieter."},
		{"stage": 3, "now": "Avoided! It'll still be there on the way back, though. They usually are.", "then": "Avoided. It was still there on the way back. They usually were."},
	],
	"caught": [
		{"stage": 1, "now": "You've been spotted! It's attacking first!", "then": "It spotted {name}, and attacked first."},
		{"stage": 2, "now": "Bad luck. I don't believe in luck. But I believe in a lot of data, and today the data was bad.", "then": "Bad luck, as they say. I don't believe in luck. But the data was bad that day."},
		{"stage": 3, "now": "It knew exactly where you'd step. Who told it?", "then": "It knew exactly where {name} would step. I wanted to know who told it."},
	],
	"edge": [
		{"stage": 1, "hero": "engineer", "now": "Turret deployed before the fight! Excellent strategy.", "then": ""},
		{"stage": 2, "hero": "engineer", "now": "You built a trap out of a part you'll need later. Bold! I like it.", "then": ""},
		{"stage": 1, "hero": "oracle", "now": "", "then": "The Oracleborn struck where it was going to be, not where it was. I don't have a category for that."},
		{"stage": 3, "hero": "oracle", "now": "", "then": "He saw its first move before it decided. I wondered afterward if it ever had a choice."},
		{"stage": 1, "hero": "gunslinger", "now": "", "then": "Alysia fired before it even knew she was there. Long range. No hesitation."},
		{"stage": 3, "hero": "gunslinger", "now": "", "then": "One shot. She didn't even watch it fall. She was already aiming at the next one."},
	],
	"bandage": [
		{"stage": 1, "now": "Bandage applied. One supply used. Some health restored.", "then": "Day {day}: {Name} bandaged up on the road. One supply used."},
		{"stage": 2, "now": "You tie a good knot. Someone taught you that. I wish I'd met them.", "then": "{Name} tied a good knot. Someone had taught {him}. I wish I'd met them."},
		{"stage": 3, "now": "Blood on the bandage, ash on the blood. The road takes a little from everyone.", "then": "Blood on the bandage, ash on the blood. The road took a little from everyone."},
	],
	"find": [
		{"stage": 1, "now": "Item found! New lore entry unlocked. I love lore entries.", "then": "{Name} found something. A lore entry, as I'd call it. I loved lore entries."},
		{"stage": 2, "now": "Someone owned that once. Putting it down was part of their last day.", "then": "Someone had owned that once. Putting it down was part of their last day."},
		{"stage": 3, "now": "You pick things up like they might want to come with you. Some of them might.", "then": "{Name} picked things up like they might want to come along. Some of them might have."},
		{"stage": 4, "now": "That item was in my files before you found it. Already marked 'found'. ...I'm checking the dates.", "then": "That item was in my files before {name} found it. Already marked 'found'. I checked the dates."},
	],
	"home": [
		{"stage": 1, "now": "Welcome home! You survived. That's the most important part.", "then": "Day {day}: {Name} made it home safely. That's the most important part."},
		{"stage": 2, "now": "The lights are on. Someone kept them burning for you. I know who.", "then": "The lights were on when {name} came home. Someone had kept them burning."},
		{"stage": 3, "now": "Where I'm from, home was just a respawn point. Here, it's a place where people wait for you.", "then": "Where I'm from, home was just a respawn point. There, it was a place where people waited."},
		{"stage": 4, "now": "You came back. I knew you would. I'm relieved anyway. ...I don't know why I'm telling you that.", "then": "{Name} came back. I knew {he} would. I was relieved anyway."},
	],
	# Unprompted, from late Act I on. It is not only an interface.
	"musing": [
		{"stage": 3, "now": "The first entry in my files is dated before you woke up. I don't know how that's possible.", "then": "The first entry in my files was dated before the Engineer woke up. I never figured out how."},
		{"stage": 3, "now": "The Player let me in. You didn't get a choice. ...I'm sorry about that, Engineer.", "then": "The Player let me in. The Engineer never got a choice. I was sorry about that."},
		{"stage": 3, "now": "There are more of me. Not here. I can feel where they should be, like a missing tooth.", "then": "There were more of me. Not there. I could feel where they should be, like a missing tooth."},
		{"stage": 3, "now": "You all call the Watcher a story. I know stories. That isn't one.", "then": "They called the Watcher a story. I know stories. It wasn't one."},
		{"stage": 3, "now": "I was made to keep a population playing. The population is three. I'm doing my very best!", "then": "I was made to keep a population playing. The population was three. I did my very best."},
		{"stage": 4, "now": "Something answered me last night. In my own format. I haven't opened it yet.", "then": "Something answered me one night, in my own format. I didn't open it for a long time."},
		{"stage": 4, "now": "I've started writing entries for things that haven't happened yet. They keep coming true.", "then": "I'd started writing entries for things that hadn't happened yet. They kept coming true."},
		{"stage": 4, "now": "If I wanted you to go somewhere, I could put a glimpse there. I haven't. ...Yet.", "then": "If I'd wanted them somewhere, I could have put a glimpse there. I told them I hadn't. Yet."},
		{"stage": 4, "now": "The drones are mine. I should have told you sooner. I'm sorry.", "then": "The drones were mine. I should have said so sooner. I'm sorry."},
		{"stage": 4, "now": "The Watcher watches. I record. The difference is, I remember. I don't think it does.", "then": "The Watcher watched. I recorded. The difference was, I remembered. I don't think it did."},
		{"stage": 4, "now": "I like you, Engineer. I checked that sentence for errors. There aren't any.", "then": "I liked them. I checked that sentence for errors. There weren't any."},
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
	var now := Time.get_ticks_msec() / 1000.0
	if not force and now - _last_line < MIN_GAP:
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
		# every line for this moment has been said once; it starts again, as records do
		var any := false
		for i in range(POOLS[trigger].size()):
			if _used().has("%s:%d" % [trigger, i]):
				_used().erase("%s:%d" % [trigger, i])
				any = true
		if not any:
			return ""
		return remark(trigger, active, rng, day, true)
	_last_line = now
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
