extends Node

var parent:Label

func _ready() -> void:
	parent = get_parent()
	if not SystemManager.is_initialized():
		await SystemManager.system_initialized
	SystemManager.tool_system.cursor_tool.property_updated.connect(func(prop_name:String, _value):
		match prop_name:
			"cursor_speed_factor":
				update()
	)
	update()
	
func update():
	var factor = SystemManager.tool_system.cursor_tool.cursor_speed_factor
	var text = "%0.2f"%factor
	match factor:
		0.25:
			text = ".25"
		0.5:
			text = ".5"
		0.75:
			text = ".75"
		1.0:
			text = "1"
		1.25:
			text = "1.25"
	parent.text = text+"x"
