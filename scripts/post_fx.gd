class_name PostFx
extends Node
## Screen passes from style anchor v0.2.
## Layer 1 (under the HUD): the purple haze. (Light is per tile, in tile.gdshader.)
## Layer 3 (over the HUD): grade, vignette, edge fringe and film grain.

var light_material: ShaderMaterial
var finish_material: ShaderMaterial
## Each hero sees the world a little differently: the Oracleborn in violet, the Engineer in
## a cold cyan cast, Alysia in dust and rust. Barely there; felt more than seen.
const GRADES := {
	"oracle": Vector3(0.98, 0.93, 1.06),
	"engineer": Vector3(0.93, 0.97, 1.07),
	"gunslinger": Vector3(1.04, 0.95, 0.96),
}
var _graded := ""
var _grade := Vector3(0.98, 0.93, 1.06)


func set_hero(hero_id: String) -> void:
	if hero_id == _graded or finish_material == null:
		return
	_graded = hero_id
	var tw := create_tween()
	var to: Vector3 = GRADES.get(hero_id, GRADES["oracle"])
	tw.tween_method(func(v: Vector3) -> void:
		_grade = v
		finish_material.set_shader_parameter("grade", v), _grade, to, 1.6)


func _ready() -> void:
	var light_layer := CanvasLayer.new()
	light_layer.layer = 1
	add_child(light_layer)
	light_material = ShaderMaterial.new()
	light_material.shader = preload("res://shaders/light.gdshader")
	light_layer.add_child(_full_rect(light_material))

	var finish_layer := CanvasLayer.new()
	finish_layer.layer = 3
	add_child(finish_layer)
	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	finish_layer.add_child(copy)
	var finish := ShaderMaterial.new()
	finish.shader = preload("res://shaders/finish.gdshader")
	finish_material = finish
	finish_layer.add_child(_full_rect(finish))


func _full_rect(mat: ShaderMaterial) -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.material = mat
	return r
