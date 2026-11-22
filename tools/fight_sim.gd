extends Node
## Runs each tactical scenario several times with the scripted fighter and prints win rates.
## Run with:  godot --path . -- --fights

const RUNS := 8


func _ready() -> void:
	await get_tree().process_frame
	var main := get_parent()
	main.set_process(false)
	main.hud.screens.close()
	while main.hud.screens._dialog.visible:
		main.hud.screens.advance()
	Engine.time_scale = 8.0
	main.hud.tactics.finished.disconnect(main._on_tactics_finished)  # keep main.gd from reacting to the fights
	for sc in ["throne_hall", "ambush", "crash_site"]:
		var wins := 0
		var turns := 0
		var hp_left := 0
		for i in range(RUNS):
			var hero_id: String = Tactics.SCENARIOS[sc]["hero"]
			var hs := HeroState.new(hero_id)
			var t: Tactics = main.hud.tactics
			var done := [false, false, 0]
			var cb := func(won: bool, hp: int, _r: Dictionary) -> void:
				done[0] = true
				done[1] = won
				done[2] = hp
			t.finished.connect(cb, CONNECT_ONE_SHOT)
			t.start(sc, hs, hs.stats()["hp"], 1)
			var n := await FightAI.play(t, self)
			for k in range(600):
				if done[0]:
					break
				await get_tree().process_frame
			if not done[0]:
				t.finished.disconnect(cb)
			wins += 1 if done[1] else 0
			turns += n
			hp_left += done[2]
		print("%-12s won %d/%d  avg turns %.1f  avg hp left %.1f" % [sc, wins, RUNS, float(turns) / RUNS, float(hp_left) / RUNS])
	get_tree().quit()
