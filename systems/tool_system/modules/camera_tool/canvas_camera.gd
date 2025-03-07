class_name CanvasCamera extends Camera2D

var tool :CameraTool

func init_with_tool(p_tool:CameraTool):
	tool = p_tool
	
	tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"follow_cursor":
				offset = SystemManager.tool_system.get_current_tool().cursor_position
			"camera_zoom":
				zoom.x = value
				zoom.y = value
			"camera_offset":
				offset = value
			#
	)
	SystemManager.tool_system.tool_property_updated.connect(func(tool_name:String, prop_name:String, value):
		match prop_name:
			"cursor_position":
				if tool.follow_cursor:
					offset = SystemManager.tool_system.get_current_tool().cursor_position
	)
	
