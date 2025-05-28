class_name SelectionTool extends BaseTool

const ACTION_SELECT_ALL := "action_select_all"

enum Mode {NONE, RECTANGLE, POLY}	
var mode := Mode.RECTANGLE

var mask_type := ImageMask.MaskType.NEW

var cell_pos_floor : Vector2i:
	get(): return _tool_system.cursor_tool.cell_pos_floor
var cell_pos_round : Vector2i:
	get(): return _tool_system.cursor_tool.cell_pos_round

var _selection_area_indicator : SelectionAreaIndicator

var _started := false
var _points := PackedVector2Array()

const ICON_SELECT_ALL = preload("res://assets/icons/select_all_96dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.svg")

var cancel_action_button : Button

static func get_tool_name() -> String:
	return "selection_tool"

func register_action(action_handler:ActionHandler):
	action_handler.register_action(ACTION_SELECT_ALL)
	
	# FIXME: 需要更好的位置
	project_controller.action_called.connect(func(action_name:String, data:Dictionary):
		match action_name:
			project_controller.ACTION_IMAGE_MASK_CHANGED:
				property_updated.emit("image_mask_changed", project_controller.get_image_mask().get_mask())
	)
	
func initialize():
	_started = false
	_points.clear()
	
# 工具激活时调用
func activate() -> void:
	if not _selection_area_indicator:
		_selection_area_indicator = SelectionAreaIndicator.new()
		add_indicator(_selection_area_indicator)
	
		
# 工具禁用时调用
func deactivate() -> void:
	#remove_indicator(_selection_area_indicator)
	pass

func get_tool_data() -> Dictionary:
	return {
		"mode":mode,
		"mask_type":mask_type,
	}

func _get_action_button_datas() -> Array:
	return [
		ActionButtonPanel.create_action_button_data(0, ToolSystem.ACTION_TOOL_MAIN_PRESSED, ToolSystem.main_pressed_icon),
		ActionButtonPanel.create_action_button_data(1, SelectionTool.ACTION_SELECT_ALL, ICON_SELECT_ALL)
	]

func _on_action_called(action:String, state:ActionHandler.State):
	if state != ActionHandler.State.JUST_RELEASED:
		return 
	match action:
		ToolSystem.ACTION_TOOL_MAIN_PRESSED:
			match mode:
				Mode.RECTANGLE:
					_rectangle_selection()
		
		ACTION_SELECT_ALL:
			project_controller.request_action(project_controller.ACTION_IMAGE_MASK_SELECT_ALL)
			
			
func _rectangle_selection():
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
	project_controller.request_action(project_controller.ACTION_ADD_RECT_IMAGE_MASK, {"rect": rect, "mask_type":mask_type})


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
			
