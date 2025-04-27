extends Node

signal drag_started
signal drag_ended

@export var agent: ScrollContainer

var _hold = false
var start_pos :Vector2

func _ready() -> void:
	if not agent:
		agent = get_parent()
	agent.gui_input.connect(func(event):
		if InputEventUtils.is_pressed(event):
			_hold = true
			start_pos = InputEventUtils.get_event_global_position(event)
			# NOTE: 特殊需求：MOUSE_FILTER_PASS 模式下 agent.accept_event() 无法组织事件传递到canvas
			# 所以采用这种方式进行拖拽事件的阻断
			agent.mouse_filter = Control.MOUSE_FILTER_STOP 
			drag_started.emit()
			
		elif InputEventUtils.is_dragged(event):
			if not _hold:
				return 
			var cp =  InputEventUtils.get_event_global_position(event)
			var diff = cp-start_pos
			agent.scroll_vertical -= diff.y
			agent.scroll_horizontal -= diff.x
			# NOTE: 滑屏移动速度越快 额外移动的越多，翻页也就越快
			start_pos = start_pos.move_toward(cp, 100) 
			
		elif InputEventUtils.is_released(event):
			agent.mouse_filter = Control.MOUSE_FILTER_PASS
			if _hold:
				_hold = false
				drag_ended.emit()
	)
	_hold = false

func is_hold() -> bool:
	return _hold
