class_name SelectionAreaIndicator extends Line2D


var tool :SelectionTool

const MARCHING_ANTS = preload("res://assets/shader/marching_ants.gdshader")

func init_with_tool(p_tool:SelectionTool):
	tool = p_tool
	var cell_size = SystemManager.canvas_system.cell_size
	var camera_tool = SystemManager.tool_system.camera_tool
	tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"cell_pos_round":
				if tool._started:
					points = tool.get_outline()
			
	)
	camera_tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"camera_zoom":
				width = 1.0/cell_size / value
	)
	
	tool.data_changed.connect(func():
		points = tool.get_outline()
	)
	scale = Vector2.ONE*cell_size
	texture_mode = Line2D.LINE_TEXTURE_STRETCH
	width = 1.0/cell_size / camera_tool.camera_zoom
	var mat = ShaderMaterial.new()
	mat.shader = MARCHING_ANTS
	mat.set_shader_parameter("ant_width", 1)
	material = mat
	
