extends Node

@export var view : Button
@export var tool_name := ""

func _ready() -> void:
	if not tool_name:
		return 
	if not view:
		view = get_parent()
	view.pressed.connect(func():
		SystemManager.tool_system.switch_tool(tool_name)
	)
	
	SystemManager.tool_system.tool_changed.connect(func(_tool_name):
		if tool_name == _tool_name:
			view.set_pressed_no_signal(true)
			view.toggled.emit(true)
		else:
			view.set_pressed_no_signal(false)
			view.toggled.emit(false)
			
	)
