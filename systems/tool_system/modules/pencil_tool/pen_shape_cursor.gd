class_name PenShapeCursor extends Sprite2D


var tool :PencilTool

const OUTLINE = preload("res://assets/shader/inline.gdshader")

func init_with_tool(p_tool:PencilTool):
	tool = p_tool
	tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			
			"pen_size":
				update_texture()
				_align_center()
			"pen_shape":
				texture.set_image(tool.get_mask_image())
				update_texture()
				_align_center()
	)
	
	SystemManager.ui_system.model_data_mapper.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"active_color":
				material.set_shader_parameter("line_color", value)
	)
	
	SystemManager.tool_system.cursor_tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"cell_pos_floor":
				_align_center()
			"cell_pos_round":
				_align_center()
	)
	
	SystemManager.tool_system.camera_tool.property_updated.connect(func(prop_name:String, value):
			match prop_name:
				"camera_zoom":
					material.set_shader_parameter("line_scale", 3.0/SystemManager.canvas_system.cell_size/value)
	)
	var cell_size = SystemManager.canvas_system.cell_size
	var zoom = SystemManager.tool_system.get_camera_zoom()
	scale = Vector2.ONE*cell_size
	texture = ImageTexture.new()
	var mat = ShaderMaterial.new()
	mat.shader = OUTLINE
	mat.set_shader_parameter("line_scale", 3.0/cell_size/zoom)
	mat.set_shader_parameter("line_color", SystemManager.color_system.active_color)
	mat.set_shader_parameter("use_line", 1.0)  # 0. fill  1. line
	material = mat
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = false
	
	update_texture()
	_align_center()
	

func update_texture():
	var image = tool.get_mask_image()
	if image.get_size() != Vector2i(texture.get_size()):
		texture.set_image(image)
	else:
		texture.update(image)
	
func _align_center():
	if not tool:
		return
	global_position = tool.get_pen_position()*SystemManager.canvas_system.cell_size
