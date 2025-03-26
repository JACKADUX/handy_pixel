class_name TransformIndicator extends Node2D


var tool : TransformTool

func init_with_tool(p_tool:TransformTool):
	tool = p_tool
	var cell_size = SystemManager.canvas_system.cell_size
	var camera_tool = SystemManager.tool_system.camera_tool
	
	tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"rects":
				queue_redraw()
	)

	scale = Vector2.ONE*cell_size


func _draw() -> void:
	var rects = tool.rects
	for index in rects.size():
		var rect = rects[index]
		if not tool.rotatable and index == 10:
			return 
		if rect.has_area():
			draw_rect(rect, Color.RED, false, 0.2)
		
