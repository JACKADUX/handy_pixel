extends Node

func _ready() -> void:
	get_parent().text = ""
	if not SystemManager.is_initialized():
		await SystemManager.system_initialized
	SystemManager.tool_system.cursor_tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"cell_pos_floor":
				get_parent().show()
				var pos = value + Vector2i.ONE
				get_parent().text = "(%d, %d)"%[pos.x , pos.y]
	)
