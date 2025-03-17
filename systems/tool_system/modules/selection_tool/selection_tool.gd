class_name SelectionTool extends BaseTool

const ACTION_SELECT_ALL := "action_select_all"

var _points := PackedVector2Array()
var _started := false

enum Mode {NONE, RECTANGLE, POLY}	
var mode := Mode.RECTANGLE

var _selection_area_indicator : SelectionAreaIndicator

var cell_pos_floor : Vector2i:
	get(): return _tool_system.cursor_tool.cell_pos_floor
var cell_pos_round : Vector2i:
	get(): return _tool_system.cursor_tool.cell_pos_round
	
static func get_tool_name() -> String:
	return "selection_tool"

# 工具激活时调用
func activate() -> void:
	_selection_area_indicator = SelectionAreaIndicator.new()
	add_indicator(_selection_area_indicator)
	
# 工具禁用时调用
func deactivate() -> void:
	remove_indicator(_selection_area_indicator)

func _on_action_just_released(action:String):
	match action:
		ToolSystem.ACTION_TOOL_MAIN_PRESSED:
			match mode:
				Mode.POLY:
					if not _started:
						_started = true
						_points.clear()
						_points.append(cell_pos_floor)
					else:
						if Vector2i(_points[0]) == cell_pos_round:
							_started = false
						_points.append(cell_pos_round)
						
				Mode.RECTANGLE:
					if not _started:
						_started = true
						_points.clear()
						_points.append(cell_pos_floor)
					else:
						_started = false
						_points.append(cell_pos_round)
			data_changed.emit()
				
		ToolSystem.ACTION_TOOL_CANCEL_PRESSED:
			_started = false
			_points.clear()
			data_changed.emit()

func _on_state_changed(state:InputRecognizer.State):
	if state == InputRecognizer.State.NONE:
		request_action_button(false)
	elif state == InputRecognizer.State.HOVER:
		request_action_button(true)

func get_outline() -> PackedVector2Array:
	match mode:
		Mode.POLY:
			return _points
		Mode.RECTANGLE:
			var outline_points := PackedVector2Array()
			var pc = _points.size()
			if not pc:
				return outline_points
			elif pc == 1:
				var rect = RectUtils.get_rect_from(_points[0], cell_pos_round)
				outline_points = RectUtils.create_points_from_rect(rect)
			elif pc == 2:
				var rect = RectUtils.get_rect_from(_points[0], _points[1])
				outline_points = RectUtils.create_points_from_rect(rect) 
			return outline_points
	return []
			
