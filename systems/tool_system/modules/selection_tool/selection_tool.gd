class_name SelectionTool extends BaseTool

const ACTION_SELECT_ALL := "action_select_all"

enum Mode {NONE, RECTANGLE, POLY}	
var mode := Mode.RECTANGLE

enum SelectionType {NEW, ADD, SUBTRACT, INTERSECT}
var selection_type := SelectionType.NEW

var cell_pos_floor : Vector2i:
	get(): return _tool_system.cursor_tool.cell_pos_floor
var cell_pos_round : Vector2i:
	get(): return _tool_system.cursor_tool.cell_pos_round

var _selection_area_indicator : SelectionAreaIndicator

var _started := false
var _points := PackedVector2Array()

# NOTE: 会和 image_layers 的 canvas 尺寸一致，蒙版区域为白色，非蒙版区域为空
var selection_mask_image : Image


const select_all = preload("res://assets/icons/select_all_96dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.svg")

static func get_tool_name() -> String:
	return "selection_tool"

func initialize():
	_started = false
	_points.clear()
	selection_mask_image = null
	raise_selection_updated()
	
# 工具激活时调用
func activate() -> void:
	if not _selection_area_indicator:
		_selection_area_indicator = SelectionAreaIndicator.new()
		add_indicator(_selection_area_indicator)
	
		
# 工具禁用时调用
func deactivate() -> void:
	#remove_indicator(_selection_area_indicator)
	pass

func get_data() -> Dictionary:
	return {
		"mode":mode,
		"selection_type":selection_type,
	}

func _get_action_button_datas() -> Array:
	return [
		ActionButtonPanel.create_action_button_data(0, ToolSystem.ACTION_TOOL_MAIN_PRESSED, ToolSystem.main_pressed_icon),
		ActionButtonPanel.create_action_button_data(1, ToolSystem.ACTION_TOOL_CANCEL_PRESSED, ToolSystem.cancel_pressed_icon),
		#ActionButtonPanel.create_action_button_data(4, SelectionTool.ACTION_SELECT_ALL, select_all)
	]
	
func _on_action_called(action:String, state:ActionHandler.State):
	match state:
		ActionHandler.State.JUST_RELEASED:
			match action:
				ToolSystem.ACTION_TOOL_MAIN_PRESSED:
					match mode:
						Mode.RECTANGLE:
							if not _started:
								_started = true
								_points.clear()
								_points.append(cell_pos_floor)
							else:
								_started = false
								_points.append(cell_pos_round)
							
							if _points.size() != 2:
								return 
							
							var rect = RectUtils.get_rect_from(_points[0], _points[1])
							var undo_image = selection_mask_image.duplicate() if selection_mask_image else null
							if not selection_mask_image:
								selection_mask_image = project_controller.get_image_layers().new_empty_image()
							match selection_type:
								SelectionType.NEW:
									selection_mask_image.fill(Color.TRANSPARENT)
									selection_mask_image.fill_rect(rect, Color.WHITE)
								SelectionType.ADD:
									selection_mask_image.fill_rect(rect, Color.WHITE)
								SelectionType.SUBTRACT:
									selection_mask_image.fill_rect(rect, Color.TRANSPARENT)
								SelectionType.INTERSECT:
									var region_image = selection_mask_image.get_region(rect)
									selection_mask_image.fill(Color.TRANSPARENT)
									selection_mask_image.blit_rect(region_image, Rect2(Vector2.ZERO, region_image.get_size()), rect.position)
									
							var do_image = selection_mask_image.duplicate()
							SystemManager.undoredo_system.add_simple_undoredo("Selection", 
								func(undoredo:UndoRedo):
									undoredo.add_do_method(func():
										selection_mask_image = do_image
										raise_selection_updated()
									)
									undoredo.add_undo_method(func():
										selection_mask_image = undo_image
										raise_selection_updated()
									)
							)
							
					raise_selection_updated()
						
				ToolSystem.ACTION_TOOL_CANCEL_PRESSED:
					_started = false
					_points.clear()
					var undo_image = selection_mask_image.duplicate() if selection_mask_image else null
					selection_mask_image = null
					var do_image = null
					raise_selection_updated()
					
					SystemManager.undoredo_system.add_simple_undoredo("Selection", 
						func(undoredo:UndoRedo):
							undoredo.add_do_method(func():
								selection_mask_image = do_image
								raise_selection_updated()
							)
							undoredo.add_undo_method(func():
								selection_mask_image = undo_image
								raise_selection_updated()
							)
					)

func _on_event_occurred(event:String, data:Dictionary):
	match event:
		InputRecognizer.EVENT_STATE_CHANGED:
			if data.state == InputRecognizer.State.NONE:
				show_action_button_panel(false)
			elif data.state == InputRecognizer.State.HOVER:
				show_action_button_panel(true)


func get_outline() -> PackedVector2Array:
	match mode:
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
			
func raise_selection_updated():
	property_updated.emit("selection_mask_image", selection_mask_image)
