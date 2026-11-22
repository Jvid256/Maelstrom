extends Node
## Ambience (autoload). Three layers:
##   bed       the place, always on, looping: town, road, camp
##   hero bed  a faint texture for whoever is in play, always on, looping
##   theme     music, taking turns: each piece plays once, then a breath of silence,
##             then the next. In town the hero's theme alternates with the town's; on the
##             road the road's alternates with the hero's; at camp, the camp's.
## Everything is written around D, so whatever overlaps sits together. Crossfades when the
## place or hero changes; ducks under fights. N mutes.
## Beds: tools/make_ambience.py. Themes: tools/compose_themes.py.

const FADE := 2.0
const DUCK_DB := -9.0
const GAP := Vector2(9.0, 22.0)   # seconds of quiet between themes
const LEVEL := {
	"bed_town": -13.0, "bed_road": -11.0, "bed_camp": -7.0,
	"bed_hero_oracle": -20.0, "bed_hero_engineer": -24.0, "bed_hero_gunslinger": -15.0,
	"theme_town": -9.0, "theme_road": -9.0, "theme_camp": -9.0,
	"theme_oracle": -9.0, "theme_engineer": -11.0, "theme_gunslinger": -9.0,
}
const HERO_ON_ROAD_DB := -4.0

var muted := false
var _place := ""
var _hero := ""
var _ducked := false
var _bed: Array[AudioStreamPlayer] = []
var _hbed: Array[AudioStreamPlayer] = []
var _theme: Array[AudioStreamPlayer] = []
var _bed_i := 0
var _hbed_i := 0
var _theme_i := 0
var _streams := {}
var _turn := 0                 # which theme is next in this place's rotation
var _now_playing := ""
var _wait := 2.0               # seconds until the next theme may start


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arr in [_bed, _hbed, _theme]:
		for i in range(2):
			var p := AudioStreamPlayer.new()
			p.volume_db = -80
			add_child(p)
			arr.append(p)
	for p in _theme:
		p.finished.connect(_on_theme_finished)


func _stream(name: String, loop: bool) -> AudioStream:
	if not _streams.has(name):
		var path := "res://audio/%s.ogg" % name
		var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
		if s is AudioStreamOggVorbis:
			s.loop = loop
		_streams[name] = s
	return _streams[name]


## Where the hero is and who it is. Cheap to call every frame; only changes do anything.
func set_state(place: String, hero: String, ducked: bool = false) -> void:
	if place != _place:
		_place = place
		_bed_i = _swap(_bed, _bed_i, "bed_" + place, _level("bed_" + place), true)
		_fade(_hbed[_hbed_i], _hero_bed_level())
		_turn = 0
		_end_theme(2.5)
	if hero != _hero:
		var was_hero_theme := _now_playing.begins_with("theme_") and _now_playing == "theme_" + _hero
		_hero = hero
		_hbed_i = _swap(_hbed, _hbed_i, "bed_hero_" + hero, _hero_bed_level(), true)
		if was_hero_theme:
			_end_theme(1.5)
			_turn = maxi(0, _rotation().find("theme_" + hero))  # the new hero's theme comes next
	if ducked != _ducked:
		_ducked = ducked
		_retarget()


func _process(delta: float) -> void:
	if _place == "" or _now_playing != "":
		return
	_wait -= delta
	if _wait <= 0.0:
		_play_next_theme()


func _rotation() -> Array:
	match _place:
		"town":
			return ["theme_" + _hero, "theme_town"]
		"road":
			return ["theme_road", "theme_" + _hero]
		"camp":
			return ["theme_camp"]
	return []


func _play_next_theme() -> void:
	var rot := _rotation()
	if rot.is_empty():
		return
	var name: String = rot[_turn % rot.size()]
	_turn += 1
	var s := _stream(name, false)
	if s == null:
		_wait = 5.0
		return
	_theme_i = 1 - _theme_i
	var p: AudioStreamPlayer = _theme[_theme_i]
	p.stream = s
	p.volume_db = _theme_level(name)
	p.play()
	_now_playing = name


func _on_theme_finished() -> void:
	_now_playing = ""
	_wait = randf_range(GAP.x, GAP.y)


## Fades out the theme that's playing; the next one follows after a short pause.
func _end_theme(pause: float) -> void:
	if _now_playing != "":
		var p: AudioStreamPlayer = _theme[_theme_i]
		var tw := create_tween()
		tw.tween_property(p, "volume_db", -80.0, 1.5)
		tw.tween_callback(p.stop)
	_now_playing = ""
	_wait = pause


func _level(name: String) -> float:
	if muted:
		return -80.0
	return float(LEVEL.get(name, -12.0)) + (DUCK_DB if _ducked else 0.0)


func _hero_bed_level() -> float:
	return _level("bed_hero_" + _hero) + (HERO_ON_ROAD_DB if _place != "town" else 0.0)


func _theme_level(name: String) -> float:
	return _level(name) + (HERO_ON_ROAD_DB if _place != "town" and name == "theme_" + _hero else 0.0)


func _retarget() -> void:
	if _place != "":
		_fade(_bed[_bed_i], _level("bed_" + _place))
	if _hero != "":
		_fade(_hbed[_hbed_i], _hero_bed_level())
	if _now_playing != "":
		_fade(_theme[_theme_i], _theme_level(_now_playing))


func _swap(pair: Array[AudioStreamPlayer], cur: int, name: String, db: float, loop: bool) -> int:
	var s := _stream(name, loop)
	var nxt := 1 - cur
	_fade(pair[cur], -80.0, true)
	if s == null:
		return cur
	var p: AudioStreamPlayer = pair[nxt]
	p.stream = s
	p.volume_db = -60.0
	p.play(randf() * maxf(0.0, s.get_length() - 1.0))
	_fade(p, db)
	return nxt


func _fade(p: AudioStreamPlayer, db: float, stop_after: bool = false) -> void:
	var tw := create_tween()
	tw.tween_property(p, "volume_db", db, FADE).set_trans(Tween.TRANS_SINE)
	if stop_after:
		tw.tween_callback(p.stop)


func toggle_mute() -> bool:
	muted = not muted
	_retarget()
	return muted
