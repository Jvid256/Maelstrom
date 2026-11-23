# Playtest pass — notes

Full write-up (findings, direction, prioritized next steps) lives in the Claude doc
"Maelstrom — Playtest Notes and Direction". This is the short version for the repo.

## How it was tested

- `--test`: full Act I playthrough. 50/50 checks, day 49.
- `--sim`: 42 expeditions (14 per hero), before and after.
- `--fights`: each tactical scenario 8× with a rote fighter.

## Numbers

| | Before | After |
| --- | --- | --- |
| Fights per trip | 0.6 | 0.8 |
| Decisions per trip | 0 | ~0.75 |
| Throne hall (rote wins / 8) | 2 | 7–8 |
| Ambush | 6 | 8 |
| Crash site | 0 | 8 |
| Engineer HP lost per trip (avg) | 17–19 | 11–13 |

## What changed

- `Events` autoload: 17 road events with choices, 8 night events, lures, omens.
- Build tab: lamps, palisade, shrine, capacitor ×3, swarm forge, winch, mess hall.
- Bestiary: unmoored, driftwatcher; hounds down, sentry armor 2, guard 30/6, echo atk 3, drifter 10/3.
- Damage floors at half (`max(ceil(dmg*0.5), dmg-armor)`).
- Engineer: lab coat armor 1, field kit supply 1, swarm seed regen 1, turret faster.
- Alysia: Python +3 in tactics, free quick-draw when holding.
- Lead fights steady hero to ≥75% HP.
- Tactics: crash site doorway + hold hex + smaller waves; mastiff hunts the hero.
- Fixes: double finish, stale target, fuse stalling, markers under HUD.

## Still open

- Tier-2 pairs (war familiars, gravewalkers) ~50% hero death at level 1–2.
- Days 15–30 go slack; needs a mid-act incident.
- The map still says too little on its own; tile lines are the cheapest fix.
- No human has played it yet.

## Second pass (same day): the Documenter and structures

- The Documenter left the Engineer's People list and became a HUD panel (bottom-left, teal). Same line pools, two tenses: present with the Engineer, past with anyone else. ~70 lines, never repeated in a run; a Record tab in the Chronicle keeps what it said. Its story beats fire on their own.
- Drone sightings: three rare road events, one night event, three day entries. No explanation in Act I.
- Upgrades became structures on tiles: 7 kinds, placed by clicking a settled tile; the ground beneath changes function and look; adjacency rules; lamps burn sunstone; shifts crack structures on the edge; repair with the ground's material. The capital is the Oracleborn's town; joined heroes' structures unlock there.
- `--test` grew 24 checks for structures and the Documenter; all pass (day 46). `--sim` and `--fights` unchanged.

## Third pass: voice, light, room

- Documenter pools doubled (~120 lines), five new triggers (waiting, readings, laws, omens, survivors) and an unprompted "musing" pool from chapter 3 on; a fourth tone after Act I in which it admits to the drones, to pre-written entries, and to enjoying itself.
- Structures cast light: up to 24 small pools in the tile shader beside the three home lights.
- Map 43×25 → 64×38; homes at (21,15), (38,11), (30,25); the town starts two rings wide (19 tiles). Corridors between homes keep void sparse there; one glimpse per other home always leans that way. Act I test: all checks pass, day 35.
- Shaping and revealing now redraw only the touched ring instead of the whole map.

## Tester feedback

- "Font is hard to read": Pixelify Sans was set at 7 px on a 480×270 canvas, below its pixel grid. Now 640×360 and 11 px, HUD and screens resized to fit. All text at least 11 px.
- "Intro says cyan markers but only orange exist": the hint now explains orange glimpses and says cyan appears when someone in town asks for something.

## The Way, slice 1 (Nov 8)

- Expeditions are planned on the world map (shape tiles, Set out) and walked on the Way: one 9×7 stretch per route tile, top-down, neighbor worlds bleeding in, void edges breaking off, a lantern for light.
- Notables replace random events: 1–2 per tile, rolled once and stored on the world cell; 35% are full events, the rest are finds (30 new short scenes, per world). The hero waits 2.4 s beside each; E/click examines.
- Encounters are rolled per stretch as before but stand visibly on the road ahead.
- Map toggle (M or picking a card) to shape ahead mid-trip; upcoming stretches rebuild, earlier ones and settled encounters stay.
- `--test` passes; `--sim`: 1.0 fights/trip as before; Engineer and Alysia lost a few more fights (event fights now come from notables more often). Watch it.
- Not yet: camps and multi-day trips, known notables marked on the world map and route planning through them, the early-game rewrite (slices 2–3). Early lead trips are still only 3–4 tiles long, so they're short on the Way too; slice 3 moves the first leads further out.

## The Way, slice 2 (Nov 9)

- Camps every 3 stretches: a day passes (home production, upkeep, settling, shifts; route and destination protected), choice of rest / watch / sleep, then a 45% chance of a road-night event (8 new, separate from nights at home; some lead to fights). Watching lowers the odds.
- Known notables: walking a tile marks it known; the world map shows a glint (something unexamined) or a dim dot (all examined); hover lists what's there.
- Route planning: in the plan phase, click tiles to route through them in order, up to +4 tiles over the direct way; tiles shaped beside the old route come back to hand if the new one no longer passes them.
- Dialog boxes now grow upward with more choices instead of running off screen.
- `--test` passes (day 52, 18 camps). `--sim`: 50 fights, 43 won (Engineer 15/16), 137 choices over 42 trips (3.3 per trip, up from 0.75), ~2.1 days per trip.
- Watch: days now pass ~2× per trip, so day-based systems (anchor upkeep, shifts every 3 days, 2-day settling) run faster relative to trips. Nothing broke in the tests, but anchor Power may feel tighter.

## Text pass (Nov 9)

- Tester note: event text and Documenter lines stiff, and their sense sometimes off.
- Root cause of most of the "off" lines: fixed pronouns and hero assumptions (a past-tense line saying "she" while the Oracleborn played, "the second shot" for a hero with no gun, a find narrating the Oracleborn's reaction to whoever found it). Text now carries tokens ({name} {he} {him} {his} {day}) filled by `Story.voice` for the hero in play; dialogs and Omens go through it. Hero-only lines are tagged and only drawn for that hero.
- Documenter rewritten from scratch in its own voice: a game-world AI built to keep a population playing, using quests, entries, runs, ranks and medians, politely, about people getting hurt. Present tense to the Engineer, past tense as a record for anyone else, four stages. Its transmissions, Law entries and scene lines rewritten to match.
- All 37 events rewritten for one convention: the scene in second person present, results short and concrete, Omens as past-tense journal entries naming the right hero. 30 finds polished.

## Early game, exploration, town, ambience (Nov 10)

- First leads now sit 5–8 tiles past the town's edge (was 3–5): the bell tower is a two-day trip with a camp. First-time hints on the road: the first notable waits 8 s with an explanation; the first enemy seen ahead pauses the walk; the first camp explains that a day passes at home too.
- Exploration: three ruin stories (car, chapel, terminal), three stages each, one per visit, two days apart, ending in a ring-slot keepsake. Three lookout finds reveal notables within 3 tiles.
- Town: rumours (each person has their own way of telling one; 55% when they have no news, once a day each) mark a fog tile's notables known. 29 reactions: examining certain things gives the right person something to say.
- Ambience: six generated loops (town, road, camp; one per hero), crossfaded by place and hero, ducked in fights, N to mute. Per-hero colour grade on the finish pass.
- `--test`: 85 checks pass (day 53).

## Music (Nov 10)

- Six composed themes replace "tones only": town waltz, road march, camp lullaby, and one per hero. All in D; they take turns over the beds with 9–22 s gaps. Switching hero in town switches straight to their theme.
- Balance fix found while testing: leads 6–8 tiles out put level-one heroes into tier-2 enemies (depth was stretch/2). Now depth = stretch/3, capped at 1 until chapter 1 is done. Test: no failed lead attempts (was up to 4). Sim: 49/53 fights won.

## Active trips (Nov 10)

- Every encounter is met with a choice about three steps out: head on, slip past (50% base, +25% scouted, +5%/Foresight for the Oracleborn, max 90%; failure costs 12% health), a hero edge (enemies open 30–35% hurt; Alysia's shot drops anything with 12 health or less), or turn back. Scripted testers always meet it head on.
- Bandage on the road: B, a supply for +6 health.
- Camp: two actions from rest / dress / forage / make supply / scout / hero action, then watch or sleep, then the night (forage +20% night chance, watch and reading the embers each halve it).

## Voices, warnings, homecoming (Nov 23)

- Camp: three actions with a working mess hall in reach.
- Documenter: chances raised ~1.5–2×, eight new moments (camp, approach, slipped, caught, hero edge, bandage, find, home), pools refill once exhausted, 12 s minimum between lines.
- Hero conversations: six (two per pair), gated on joined land, a prior scene, progress (laws, settlement size) and a 2–3 day gap since that pair last talked.
- Tile lines: 26 first-placement lines, 15 world-meeting lines, once each per run.
- Homecoming flare at the hero's home on return (strength by outcome).
- Danger: threat rating 0–3 from time-to-kill vs damage taken against current health; signs over dangerous (!) and deadly (!!) enemies, in the approach choice and in scouting.
- `--test`: all checks pass (day 58).
