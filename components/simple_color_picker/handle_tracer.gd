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
	if mouse_pressed(event):
		_pressed = true
		drag_started.emit()
		
	elif mouse_press_and_move(event) and _pressed:
		update()
		
	elif mouse_released(event):
		if _pressed:
			update()
			drag_ended.emit()
		_pressed = false
	
func update():
	var mp = get_local_mouse_position()
	var pos = Vector2(mp.x/size.x, mp.y/size.y)
	pos = pos.clamp(Vector2.ZERO, Vector2.ONE)
	beacon_located.emit(pos)

static func mouse_motion(event:InputEvent):
	return event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_NONE
	
static func mouse_pressed(event:InputEvent, button:=MOUSE_BUTTON_LEFT):
	return event is InputEventMouseButton and event.button_index == button and event.is_pressed()

static func mouse_press_and_move(event:InputEvent, button:=MOUSE_BUTTON_MASK_LEFT):
	return event is InputEventMouseMotion and event.button_mask == button

static func mouse_released(event:InputEvent, button:=MOUSE_BUTTON_LEFT):
	return event is InputEventMouseButton and event.button_index == button and event.is_released()
