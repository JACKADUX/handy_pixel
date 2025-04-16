class_name Cursor extends Node2D

@export var cursor_length = 24

var tool :CursorTool

var _zoom : float = 1

const INVERT_COLOR = preload("res://assets/shader/invert_color.gdshader")

func init_with_tool(p_tool:CursorTool):
	tool = p_tool
	tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"cursor_position":
				global_position = value
				queue_redraw()
	)
	
	SystemManager.tool_system.camera_tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"camera_zoom":
				_zoom = value
				queue_redraw()
	)
	z_index = 1
	_zoom = SystemManager.tool_system.camera_tool.camera_zoom
	global_position = tool.cursor_position
	var mat = ShaderMaterial.new()
	mat.shader = INVERT_COLOR
	material = mat
	queue_redraw()

func _draw() -> void:
	var color = Color.BLACK
	var length = cursor_length / _zoom
	draw_line(Vector2(-length, 0), Vector2(length, 0), color, 3./_zoom)
	draw_line(Vector2(0, -length), Vector2(0, length), color, 3./_zoom)
	
	


	
	
