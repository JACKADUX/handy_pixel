class_name SelectionTool extends BaseTool

const ACTION_SELECT_ALL := "action_select_all"

enum Mode {NONE, RECTANGLE, WAND, POLY}	
var mode := Mode.RECTANGLE

var mask_type := ImageMask.MaskType.NEW
var wand_tolarence := 0

var cell_pos_floor : Vector2i:
	get(): return _tool_system.cursor_tool.cell_pos_floor
var cell_pos_round : Vector2i:
	get(): return _tool_system.cursor_tool.cell_pos_round

var _selection_area_indicator : SelectionAreaIndicator

var _started := false
var _points := PackedVector2Array()

var color_select : ComputeShaderSystem.ColorSelect

const ICON_SELECT_ALL = preload("res://assets/icons/select_all_96dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.svg")

var cancel_action_button : Button
var _input_recognizer_state = 0

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
	if not color_select:
		color_select = _tool_system.get_compute_shader_object("color_select")
	color_select.free_rids()
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
		"wand_tolarence":wand_tolarence,
	}

func _get_action_button_datas() -> Array:
	var index = 0
	if not _started or _input_recognizer_state == InputRecognizer.State.HOVER:
		index = 1
	return [
		ActionButtonPanel.create_action_button_data(0, ToolSystem.ACTION_TOOL_MAIN_PRESSED, ToolSystem.main_pressed_icon, index),
		ActionButtonPanel.create_action_button_data(1, SelectionTool.ACTION_SELECT_ALL, ICON_SELECT_ALL, index)
	]

func _on_action_called(action:String, state:ActionHandler.State):
	if state != ActionHandler.State.JUST_RELEASED:
		return 
	match action:
		ToolSystem.ACTION_TOOL_MAIN_PRESSED:
			match mode:
				Mode.RECTANGLE:
					_rectangle_selection()
					if not _started and _input_recognizer_state != InputRecognizer.State.HOVER:
						show_action_button_panel(false)
				Mode.WAND:
					var query_pos =_tool_system.cursor_tool.cell_pos_floor
					_wand_selection(query_pos)
		
		ACTION_SELECT_ALL:
			_started = false
			_points.clear()
			project_controller.request_action(project_controller.ACTION_IMAGE_MASK_SELECT_ALL)
			if _input_recognizer_state != InputRecognizer.State.HOVER:
				show_action_button_panel(false)
				
			
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
	
func _wand_selection(query_pos:Vector2):
	var image_layers := project_controller.get_image_layers()
	var active_index = project_controller.get_active_layer_index()
	var image = image_layers.create_canvas_image(active_index)
	if not Rect2(Vector2.ZERO, image.get_size()).has_point(query_pos):
		return 
	var target_color = image.get_pixelv(query_pos)
	var color_select_data = color_select.ColorSelectData.create(
			image, target_color, wand_tolarence
	)
	var mask = color_select.compute(color_select_data)
	project_controller.request_action(project_controller.ACTION_ADD_IMAGE_MASK, {"mask": mask, "mask_type":mask_type})

func _on_event_occurred(event:String, data:Dictionary):
	match event:
		InputRecognizer.EVENT_STATE_CHANGED:
			_input_recognizer_state = data.state
			if data.state == InputRecognizer.State.NONE:
				if not _started:
					show_action_button_panel(false)
				else:
					show_action_button_panel(true)
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
			
