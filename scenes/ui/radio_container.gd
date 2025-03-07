@tool
class_name RadioContainer extends Container

@export var radius := 100
@export var start_angle := 0
@export var end_angle := 90
@export var center_offset := Vector2.ZERO
@export var rotation_offset := 0


func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		sort_controls()

func _process(delta: float) -> void:
	_debug_uodate()

func sort_controls():
	var index := 0
	var child_count:int = get_child_count()
	var step = (end_angle-start_angle)/(child_count-1) if child_count >= 2 else 0
	for child: Control in get_children():
		#if not child.visible:
		#	continue
		var v1 = Vector2.from_angle(deg_to_rad(start_angle+step*index+rotation_offset))
		var offset = child.get_size()*0.5
		fit_child_in_rect(child, Rect2(center_offset + v1*radius -offset, child.size))
		index+=1

func _debug_uodate():
	if Engine.is_editor_hint() and Engine.get_process_frames() % 1 == 0:
		sort_controls()
