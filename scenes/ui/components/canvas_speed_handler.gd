extends Node

var parent:Label

func _ready() -> void:
	parent = get_parent()
	if not SystemManager.is_initialized():
		await SystemManager.system_initialized
	SystemManager.tool_system.cursor_tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"cursor_speed_factor":
				update()
	)
	update()
	
func update():
	var factor = SystemManager.tool_system.cursor_tool.cursor_speed_factor
	parent.text = "%0.2fx"%factor
