class_name HandleTracer extends Control

signal drag_started
signal beacon_located(value:Vector2)
signal drag_ended

var _pressed := false

#---------------------------------------------------------------------------------------------------
func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	focus_mode = FOCUS_CLICK
	
#---------------------------------------------------------------------------------------------------
func _gui_input(event):
	if Utils.mouse_pressed(event):
		_pressed = true
		drag_started.emit()
		
	elif Utils.mouse_press_and_move(event) and _pressed:
		update()
		
	elif Utils.mouse_released(event):
		if _pressed:
			update()
			drag_ended.emit()
		_pressed = false
	
func update():
	var mp = get_local_mouse_position()
	var pos = Vector2(mp.x/size.x, mp.y/size.y)
	pos = pos.clamp(Vector2.ZERO, Vector2.ONE)
	beacon_located.emit(pos)
