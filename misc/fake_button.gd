class_name FakeButton extends Node

signal pressed

@export var agent : Control
## 触发pressed 信号需要拖拽长度小于这个数值
@export var drag_length :float= 50  
## 触发pressed 信号需要拖拽时长小于这个数值
@export var drag_duration :float= 1

var _hold := false
var _dt :float= 0
var _dpos := Vector2.ZERO


func _ready() -> void:
	if not agent:
		agent = get_parent()
	agent.gui_input.connect(_gui_input)
	
func _gui_input(event: InputEvent) -> void:
	if is_valid_event(event) and event.is_pressed() :
		_hold = true
		_dt = Time.get_ticks_msec()
		_dpos = get_event_global_position(event)  # NOTE: 触屏上不能使用get_global_mouse_position() 会有误差
		
	if _hold and is_valid_event(event) and event.is_released():
		_hold = false
		_dt = (Time.get_ticks_msec()- _dt)/1000.0
		_dpos = get_event_global_position(event)-_dpos
		if _dpos.length() > drag_length or _dt > drag_duration:
			return 
		pressed.emit()

func is_valid_event(event:InputEvent) -> bool:
	return event is InputEventMouseButton or event is InputEventScreenTouch

func get_event_global_position(event: InputEvent):
	var mp : Vector2
	if OS.has_feature("android") and InputEventScreenTouch:
		return event.position
	if event is InputEventMouseButton:
		mp = event.global_position
	return mp
