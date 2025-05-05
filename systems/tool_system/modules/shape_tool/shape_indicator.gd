class_name ShapeIndicator extends Node2D

var tool: ShapeTool

var texture := ImageTexture.new()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func init_with_tool(p_tool:ShapeTool):
	tool = p_tool
	tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"shape_data":
				update()
	)
	SystemManager.tool_system.camera_tool.property_updated.connect(func(prop_name:String, value):
			match prop_name:
				"camera_zoom":
					update()
	)
	scale = Vector2.ONE*CanvasData.CELL_SIZE

func update():
	queue_redraw()

func _draw():
	if not tool:
		return 
	if not tool.shape_data.is_dynamic_state():
		return 
	var data = tool.get_shape_image_data()
	if not data:
		return
	texture.set_image(data.image)
	# NOTE: 保持图片是白色，这样就可以直接上色了
	var active_color = SystemManager.color_system.active_color
	texture.draw(get_canvas_item(), data.rect.position, active_color)
	
	## Draw Bezier Handle
	var shape_data := tool.shape_data
	if shape_data is ShapeTool.BezierShapeData:
		var zoom = tool.main_canvas_data.camera_zoom 
		var half = Vector2(0.5,0.5)
		var half_line_fn = func(p1, p2, color, width):
			draw_line(Vector2(p1)+half, Vector2(p2)+half, color, width/zoom, true)
		var circle_fn = func(p1, color, radius):
			draw_circle(Vector2(p1)+half, radius, color)
		var c1 = Color.BLACK
		var c2 = Color.WHITE
		match shape_data.state:
			2:
				var p1 = shape_data.p1
				var p2 = shape_data.p1+shape_data.h1
				half_line_fn.call(p1, p2, c1, 0.4)
				half_line_fn.call(p1, p2, c2, 0.2)
				circle_fn.call(p2, c1, 0.6)
				circle_fn.call(p2, c2, 0.5)
			3:
				var p1 = shape_data.p1
				var p2 = shape_data.p1+shape_data.h1
				var p3 = shape_data.p2
				var p4 = shape_data.p2+shape_data.h2
				half_line_fn.call(p1, p2, c1, 0.4)
				half_line_fn.call(p1, p2, c2, 0.2)
				half_line_fn.call(p3, p4, c1, 0.4)
				half_line_fn.call(p3, p4, c2, 0.2)
				circle_fn.call(p2, c1, 0.6)
				circle_fn.call(p2, c2, 0.5)
				circle_fn.call(p4, c1, 0.6)
				circle_fn.call(p4, c2, 0.5)
