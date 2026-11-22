class_name FightAI
extends RefCounted
## A simple scripted fighter for every tactical scenario, shared by the test tools:
## close in on the biggest threat and use the hero's kit.


static func play(t: Tactics, node: Node) -> int:
	var turns := 0
	while t.visible and turns < 40:
		turns += 1
		while t._busy and t.visible:
			await node.get_tree().process_frame
		if not t.visible:
			break
		var target: Dictionary = {}
		var bd := 99
		for e in t.enemies():
			var d := Hex.distance(t.hero["pos"], e["pos"])
			var score := d - (3 if e.get("boss", false) and t.scenario == "throne_hall" else 0)
			if score < bd:
				bd = score
				target = e
		match t.hero_state.id:
			"oracle":
				if not target.is_empty():
					approach(t, target["pos"], 1)
					for e in t.enemies():
						if e.get("visible", false) and e["intent"].has("hexes") and t.foresight >= 1:
							t.action = "cancel"
							t._use_on("cancel", e)
					if Hex.distance(t.hero["pos"], target["pos"]) == 1 and not t.acted:
						t._use_on("strike" if turns % 3 else "bash", target)
			"engineer":
				# stay back, deploy turrets, patch when hurt, hit what comes close
				if t.turrets_placed < 2 and not t.acted:
					for q in Hex.neighbors(t.hero["pos"]):
						if t.walkable(q):
							t.action = "deploy"
							t._click(q)
							break
				if not t.acted and t.hero["hp"] < t.hero["max"] * 0.5:
					t._on_button("patch")
				if not t.acted and not target.is_empty() and Hex.distance(t.hero["pos"], target["pos"]) == 1:
					t._use_on("strike", target)
			"gunslinger":
				if not target.is_empty():
					var d := Hex.distance(t.hero["pos"], target["pos"])
					if t.sc["goal"] == "defend":
						var obj: Vector2i = t.sc.get("hold", t.sc["objective"])
						if t.hero["pos"] != obj and not t.acted and t.reachable(t.hero["pos"], t.steps_left).has(obj):
							t._click(obj)
					elif d > 3:
						approach(t, target["pos"], 3)
					d = Hex.distance(t.hero["pos"], target["pos"])
					if not t.acted:
						if t.charge >= 3 and d <= 4:
							t._use_on("energy", target)
						elif d <= 2 and target["armor"] == 0:
							t._use_on("glock", target)
						elif d <= 3:
							t._use_on("python", target)
						elif t.hero["hp"] < t.hero["max"] * 0.4 and t.supplies > 0:
							t._on_button("draught")
		if not t.acted and t.hero["hp"] < t.hero["max"] / 3 and t.supplies > 0:
			t._on_button("draught")
		if not t.visible:
			break
		t._end_turn()
		while t._busy and t.visible:
			await node.get_tree().process_frame
	return turns


static func approach(t: Tactics, goal: Vector2i, stop_at: int) -> void:
	if t.acted or Hex.distance(t.hero["pos"], goal) <= stop_at:
		return
	var reach := t.reachable(t.hero["pos"], t.steps_left)
	var best: Vector2i = t.hero["pos"]
	var bd := Hex.distance(best, goal)
	for p in reach:
		var d := Hex.distance(p, goal)
		if d < bd and d >= stop_at:
			bd = d
			best = p
	if best != t.hero["pos"]:
		t._click(best)
