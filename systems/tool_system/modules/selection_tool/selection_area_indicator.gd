class_name SelectionAreaIndicator extends Node2D


var tool :SelectionTool

const MARCHING_ANTS = preload("res://assets/shader/marching_ants.gdshader")

var _points : PackedVector2Array

var _sprite : Sprite2D

func _ready() -> void:
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat = ShaderMaterial.new()
	mat.shader = MARCHING_ANTS
	mat.set_shader_parameter("line_scale", 0.1)
	
	_sprite.material = mat

func init_with_tool(p_tool:SelectionTool):
	tool = p_tool
	var camera_tool = SystemManager.tool_system.camera_tool
	var cursor_tool = SystemManager.tool_system.cursor_tool
	cursor_tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"cell_pos_round":
				if tool._started:
					_points = tool.get_outline()
					queue_redraw()
	)
	camera_tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"camera_zoom":
				_sprite.material.set_shader_parameter("line_scale", 0.1/ value)
				_sprite.material.set_shader_parameter("ant_length", 1. *CanvasData.CELL_SIZE/ value)
	)
	
	tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"image_mask_changed":
				if not tool._started:
					_points.clear()
					queue_redraw()
				if not value:
					_sprite.texture = null
				else:
					_sprite.texture = ImageTexture.create_from_image(value)
	)
	
	scale = Vector2.ONE*CanvasData.CELL_SIZE
	_sprite.material.set_shader_parameter("line_scale", 0.1/camera_tool.camera_zoom)
	_sprite.material.set_shader_parameter("ant_length", 1.*CanvasData.CELL_SIZE/camera_tool.camera_zoom)
				
func _draw() -> void:
	if _points.size() >= 2:
		draw_polyline(_points, Color.GREEN, 0.1/SystemManager.tool_system.camera_tool.camera_zoom)
