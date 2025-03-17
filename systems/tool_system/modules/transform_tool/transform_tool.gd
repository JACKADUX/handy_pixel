class_name TransformTool extends BaseTool

const ACTION_TRANSFORM := "action_transform"

var _transform_indicator : Node2D
var _drag_start := false

var _bg_image := Image.new()
var _move_image := Image.new()
var _start_pos := Vector2i.ZERO

var cell_pos_floor : Vector2i:
	get(): return _tool_system.cursor_tool.cell_pos_floor
var cell_pos_round : Vector2i:
	get(): return _tool_system.cursor_tool.cell_pos_round
	

static func get_tool_name() -> String:
	return "transform_tool"

# 工具激活时调用
func activate() -> void:
	pass
	#_selection_area_indicator = SelectionAreaIndicator.new()
	#canvas_manager.add_child(_selection_area_indicator)
	#_selection_area_indicator.init_with_tool(self)
	
# 工具禁用时调用
func deactivate() -> void:
	pass
	#canvas_manager.remove_child(_selection_area_indicator)
	#_selection_area_indicator.queue_free()

func _on_action_just_pressed(action:String):
	match action:
		ToolSystem.ACTION_TOOL_MAIN_PRESSED:
			_drag_start = true
			#_bg_image = Image.create_empty(canvas_data.get_width(), canvas_data.get_height(), false, Image.FORMAT_RGBA8)
			#_move_image = canvas_data.get_image()
			_start_pos = cell_pos_floor
			
func _on_action_just_released(action:String):
	match action:
		ToolSystem.ACTION_TOOL_MAIN_PRESSED:
			_drag_start = false
				
func _handle_value_changed(prop_name:String, value:Variant):
	super(prop_name, value)
	match prop_name:
		"cell_pos_floor":
			if not _drag_start:
				return 
			if _move_image.is_empty():
				return 
			var offset = cell_pos_floor - _start_pos
			var rect = Rect2(Vector2.ZERO, _move_image.get_size())
			var new_image :Image = _bg_image.duplicate()
			new_image.get_size()
			new_image.blit_rect_mask(_move_image, _move_image, rect, offset)
			#canvas_data.set_image(new_image)
