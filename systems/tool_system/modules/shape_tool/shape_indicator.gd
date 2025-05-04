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
	var active_color = SystemManager.color_system.active_color
	if active_color.a != 1:
		active_color.a = 1
	texture.draw(get_canvas_item(), data.rect.position, active_color)
