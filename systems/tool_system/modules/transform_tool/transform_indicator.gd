class_name TransformIndicator extends Node2D


var tool : TransformTool

var _zoom :float = 1

func init_with_tool(p_tool:TransformTool):
	tool = p_tool
	var cell_size = SystemManager.canvas_system.cell_size
	var camera_tool = SystemManager.tool_system.camera_tool
	
	tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"rects":
				queue_redraw()
	)
	camera_tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"camera_zoom":
				_zoom = value
				queue_redraw()
	)
	
	scale = Vector2.ONE*cell_size
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	var rects = tool.rects
	var draw_i = [1,3,5,7,9]
	for index in rects.size():
		var rect = rects[index] as Rect2
		if not tool.rotatable and index == 10:
			return 
		if rect.has_area() and index in draw_i:
			draw_rect(rect.grow(-0.1/_zoom), Color.BLACK, false, 0.4/_zoom)
			draw_rect(rect, Color.WHITE, false, 0.2/_zoom)
