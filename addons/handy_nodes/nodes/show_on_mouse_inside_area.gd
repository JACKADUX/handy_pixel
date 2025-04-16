class_name ShowOnMouseInsideArea extends Node

@export var enable := true:
	set(v):
		enable = v
		update()
@export var target_node : Control
@export var visiable_node : Control
@export_range(0,1,0.01) var from_alpha :float = 1
@export_range(0,1,0.01) var to_alpha :float = 0

var _inside := false
var _is_show_time = false

func _ready():
	if not target_node:
		target_node = get_parent()
	if not visiable_node:
		visiable_node = get_parent()
	update.call_deferred()
	
func update():
	set_process_input(enable)
	set_process(enable)
	if not visiable_node:
		return 
	if not enable:
		visiable_node.modulate.a = 1.
	else:
		visiable_node.modulate.a = to_alpha
		
func _input(event):
	if not visiable_node or not target_node:
		return 
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_NONE:
		if _is_show_time:
			return 
		var has_point = target_node.get_global_rect().has_point(target_node.get_global_mouse_position())
		if has_point and not _inside:
			_inside = true
			var tween = create_tween()
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(visiable_node, "modulate:a", from_alpha, 0.2)
			
		elif not has_point and _inside:
			_inside = false
			var tween = create_tween()
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(visiable_node, "modulate:a", to_alpha, 0.2)

func show_time(value:float= 3):
	_inside = true
	_is_show_time = true
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(visiable_node, "modulate:a", to_alpha, 0.2)
	tween.tween_callback(func(): _is_show_time = false).set_delay(value)
	
