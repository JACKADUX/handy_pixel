class_name CursorTool extends BaseTool

var _cursor: Cursor

var cursor_position :Vector2
var cell_pos_floor :Vector2i
var cell_pos_round :Vector2i

static func get_tool_name() -> String:
	return "cursor"

# 工具激活时调用
func activate() -> void:
	_cursor = Cursor.new()
	canvas_manager.add_child(_cursor)
	_cursor.init_with_tool(self)

# 工具禁用时调用
func deactivate() -> void:
	canvas_manager.remove_child(_cursor)
	_cursor.queue_free()

func _handle_value_changed(prop_name:String, value:Variant):
	match prop_name:
		"cursor_position":
			var cell_size = SystemManager.canvas_system.cell_size
			var f_pos = Vector2i(floor(cursor_position/cell_size))
			if f_pos != cell_pos_floor:
				cell_pos_floor = f_pos
				property_updated.emit("cell_pos_floor", cell_pos_floor)
			var r_pos = Vector2i(round(cursor_position/cell_size))
			if r_pos != cell_pos_round:
				cell_pos_round = r_pos
				property_updated.emit("cell_pos_round", cell_pos_round)
				

func _on_double_clicked(pos:Vector2):
	var tap_pos = SystemManager.canvas_system.get_touch_local_position(pos)
	if SystemManager.canvas_system.get_cell_rect().has_point(tap_pos):
		set_value("cursor_position", tap_pos)
			
func _on_hovered(relative:Vector2):
	relative *= _tool_system.cursor_speed_factor
	set_value("cursor_position", cursor_position+relative/_tool_system.get_camera_zoom())


func _on_state_changed(state:InputRecognizer.State):
	if state == InputRecognizer.State.NONE:
		request_action_button(false)
	elif state == InputRecognizer.State.HOVER:
		request_action_button(true)
