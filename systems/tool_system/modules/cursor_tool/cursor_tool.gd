class_name CursorTool extends BaseTool

var _cursor: Cursor

var cursor_position :Vector2
var cell_pos_floor :Vector2i
var cell_pos_round :Vector2i

var cursor_speed_factor :float = 0.75 # 跟随倍率


static func get_tool_name() -> String:
	return "cursor"

# 工具激活时调用
func activate() -> void:
	_cursor = Cursor.new()
	add_indicator(_cursor)

# 工具禁用时调用
func deactivate() -> void:
	remove_indicator(_cursor)

func get_tool_data() -> Dictionary:
	return {
		"cursor_speed_factor":cursor_speed_factor
	}

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

func _on_event_occurred(event:String, data:Dictionary):
	match event:
		InputRecognizer.EVENT_INPUT_HANDLED:
			var input_data = data.input_datas.get_input_data(0) as InputData
			if input_data and input_data.double_clicked:
				var tap_pos = SystemManager.canvas_system.get_touch_local_position(input_data.end_position)
				if SystemManager.canvas_system.get_canvas_rect().has_point(tap_pos):
					set_value("cursor_position", tap_pos)
		InputRecognizer.EVENT_HOVERED:
			var relative = data.relative*cursor_speed_factor
			set_value("cursor_position", cursor_position+relative/_tool_system.get_camera_zoom())
			
