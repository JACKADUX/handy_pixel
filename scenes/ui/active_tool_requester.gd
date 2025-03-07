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
