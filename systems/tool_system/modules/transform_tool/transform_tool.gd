class_name TransformTool extends BaseTool

const ACTION_TRANSFORM := "action_transform"

enum TransformState {
	NONE,
	MOVE,
	RESIZE,
	ROTATE,
	}
var transform_state := TransformState.NONE

var rect_expand_size :int = 96
var area_rect = Rect2()
var rects = []
var rotatable:=false
var camera_zoom = 1.0
var _transform_index = 0

var _prev_position : Vector2i

var _start = false
var _pre_rect = Rect2()

enum TransformMode {PART, FULL}
var transform_mode := TransformMode.FULL

var _transform_indicator : Node2D
var _offset_pos := Vector2.ZERO

var _prev_image_layer : ImageLayer
var _bg_image_layer : ImageLayer
var _prev_selection_mask_image : Image
var _split_fg : Image
var _resized_split_fg : Image

var moved = false
var _pressed_start = false

var _draw_started = false

static func get_tool_name() -> String:
	return "transform_tool"

func register_action(action_handler:ActionHandler):
	action_handler.register_action(ACTION_TRANSFORM)
	
func initialize():
	_confirm_transform()
	
# 工具激活时调用
func activate() -> void:
	if not _transform_indicator:
		_transform_indicator = TransformIndicator.new()
		add_indicator(_transform_indicator)
		
		_tool_system.camera_tool.property_updated.connect(func(prop, value):
			match prop:
				"camera_zoom":
					if transform_mode == TransformMode.PART:
						camera_zoom = value
						set_area_rects(area_rect)
		)
		
	camera_zoom = _tool_system.camera_tool.camera_zoom
	_tool_system.cursor_tool._cursor.hide()
		
# 工具禁用时调用
func deactivate() -> void:
	_tool_system.cursor_tool._cursor.show()
	_confirm_transform()

func mode_detecte():
	var image_mask = project_controller.get_image_mask()
	if image_mask.has_mask():
		print(123)
		transform_mode = TransformMode.PART
		set_area_rects(image_mask.get_used_rect()) 
	else:
		transform_mode = TransformMode.FULL
		rects = []
		property_updated.emit("rects", rects)
		
func _get_action_button_datas() -> Array:
	return [
		ActionButtonPanel.create_action_button_data(0, ToolSystem.ACTION_TOOL_MAIN_PRESSED, ToolSystem.confirm_pressed_icon, 0),
		ActionButtonPanel.create_action_button_data(1, ToolSystem.ACTION_TOOL_CANCEL_PRESSED, ToolSystem.cancel_pressed_icon, 0),
	]

func _confirm_transform():
	_pressed_start = false
	moved =	false
	transform_mode = TransformMode.FULL
	rects = []
	property_updated.emit("rects", rects)

func _on_action_called(action:String, state:ActionHandler.State):
	if state == ActionHandler.State.JUST_PRESSED:
		_check_draw_started()
	if not is_draw_started():
		return 
	match action:
		ToolSystem.ACTION_TOOL_MAIN_PRESSED:
			match state:
				ActionHandler.State.JUST_RELEASED:
					_confirm_transform()
					show_action_button_panel(false)
					
		ToolSystem.ACTION_TOOL_CANCEL_PRESSED:
			match state:
				ActionHandler.State.JUST_RELEASED:
					_confirm_transform()
					show_action_button_panel(false)

func _check_draw_started():
	if not project_controller.is_layer_editable(project_controller.get_active_layer_index()):
		_draw_started = false
		PopupArrowPanelManager.get_from_ui_system().quick_notify_dialog("编辑失败:当前图层已锁定！")
	else:
		_draw_started = true

func is_draw_started():
	return _draw_started

func _on_event_occurred(event:String, data:Dictionary):
	if event != InputRecognizer.EVENT_INPUT_HANDLED:
		return 
	if data.state not in [InputRecognizer.State.NONE, InputRecognizer.State.HOVER]:
		return
	var input_data = data.input_datas.get_input_data(0) as InputData
	if not input_data:
		return 
	if input_data.is_just_pressed():
		_check_draw_started()
	if not is_draw_started():
		return 
	if input_data.is_just_pressed() and not moved:
		mode_detecte()
	if is_full_mode():
		_handle_full_mode(input_data)
	else:
		_handle_selection_mode(input_data)
	
func _handle_full_mode(input_data:InputData):
	if not input_data:
		return
	if input_data.is_just_pressed():
		var end_pos = SystemManager.canvas_system.get_canvas_pos_floor(input_data.end_position)
		var active_index = project_controller.get_active_layer_index()
		var image_layer = project_controller.get_image_layers().get_layer(active_index)
		_prev_position = image_layer.position
		_offset_pos = image_layer.position - Vector2i(end_pos)
		
	elif not input_data.is_pressed():
		var active_index = project_controller.get_active_layer_index()
		var image_layer = project_controller.get_image_layers().get_layer(active_index)
		var do_value = image_layer.position
		SystemManager.undoredo_system.add_simple_undoredo("LayerPropertyUpdated", func(undoredo:UndoRedo):
			undoredo.add_do_method(project_controller.update_layer_property.bind(active_index, ImageLayer.PROP_POSITION, do_value))
			undoredo.add_undo_method(project_controller.update_layer_property.bind(active_index, ImageLayer.PROP_POSITION, _prev_position))
		)
	elif input_data.is_draged():
		var end_pos = SystemManager.canvas_system.get_canvas_pos_floor(input_data.end_position)+_offset_pos
		project_controller.update_layer_property(project_controller.get_active_layer_index(), ImageLayer.PROP_POSITION, Vector2i(end_pos))

func _handle_selection_mode(input_data:InputData):
	if not input_data:
		return
	var image_mask = project_controller.get_image_mask()
	if input_data.is_just_pressed():
		_start = true
		update_transform_state(SystemManager.canvas_system.get_canvas_pos(input_data.end_position))
		## Handle image_layers
		var active_index = project_controller.get_active_layer_index()
		var image_layers := project_controller.get_image_layers()
		_prev_image_layer = image_layers.get_layer(active_index).duplicate(true)
		_prev_selection_mask_image = image_mask.get_mask()
		
		if not moved:
			var prev_image := image_layers.get_canvas_image(active_index)
			if not prev_image:
				print_debug("当前图层是空的，无法移动")
				return 
			show_action_button_panel(true)
			moved = true
			var used_rect = _prev_selection_mask_image.get_used_rect()
			var selection_mask_image = _prev_selection_mask_image.get_region(used_rect)
			var image_size = selection_mask_image.get_size()
			prev_image = prev_image.get_region(used_rect)
			var src_rect = Rect2(0,0,image_size.x, image_size.y)
			
			_split_fg = Image.create_empty(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
			_split_fg.blit_rect_mask(prev_image, selection_mask_image, src_rect, Vector2.ZERO)
			_resized_split_fg = _split_fg.duplicate()
			
			var split_bg := Image.create_empty(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
			project_controller.blit_image(active_index, split_bg, selection_mask_image, src_rect, used_rect.position, ImageLayers.BlitMode.BLIT)
			_bg_image_layer = image_layers.get_layer(active_index).duplicate(true)
			project_controller.blit_image(active_index, _resized_split_fg, _resized_split_fg, Rect2(Vector2.ZERO, _resized_split_fg.get_size()), area_rect.position, ImageLayers.BlitMode.BLEND)
		
		# NOTE: 给尺寸为0的矩形补偿最小尺寸 1, 否则无法放大
		var end_pos = SystemManager.canvas_system.get_canvas_pos_floor(input_data.end_position)
		_pre_rect = area_rect
		if _pre_rect.size.x == 0:
			_pre_rect.size.x = 1
			if _transform_index in [1, 4, 7]:
				_pre_rect.position.x -= 1
		if _pre_rect.size.y == 0:
			_pre_rect.size.y = 1
			if _transform_index in [1, 2, 3]:
				_pre_rect.position.y -= 1
		var resize_data = RectUtils.get_resize_target_and_anchor(_pre_rect, _transform_index)
		_offset_pos = resize_data.target - end_pos
			
	elif not input_data.is_pressed():
		_start = false
		
		var active_index = project_controller.get_active_layer_index()
		var image_layers := project_controller.get_image_layers()
		var do_image_layer = image_layers.get_layer(active_index).duplicate(true)
		var undo_image_layer = _prev_image_layer.duplicate(true)
		
		var do_mask_image = image_mask.get_mask()
		var undo_mask_image = _prev_selection_mask_image.duplicate()
		
		SystemManager.undoredo_system.add_simple_undoredo("LayerTransform", func(undoredo:UndoRedo):
			project_controller.action_set_image_mask(do_mask_image, undo_mask_image)
			undoredo.add_do_method(func():
				project_controller.set_layer(active_index, do_image_layer)
				var used_rect = do_mask_image.get_used_rect()
				set_area_rects(used_rect) 
			)
			undoredo.add_undo_method(func():
				project_controller.set_layer(active_index, undo_image_layer)
				var used_rect = undo_mask_image.get_used_rect()
				set_area_rects(used_rect) 
			)
		)
		
	elif input_data.is_draged():
		if not _start:
			return 
		var end_pos = SystemManager.canvas_system.get_canvas_pos_floor(input_data.end_position)+_offset_pos
		match transform_state:
			TransformState.MOVE:
				area_rect.position = end_pos
				set_area_rects(area_rect)
				## Handle image_layers
				if moved:
					var active_index = project_controller.get_active_layer_index()
					project_controller.set_layer(active_index, _bg_image_layer.duplicate(true))
					var src_rect = Rect2(Vector2.ZERO, _resized_split_fg.get_size())
					project_controller.blit_image(active_index, _resized_split_fg, _resized_split_fg, src_rect, area_rect.position, ImageLayers.BlitMode.BLEND)
					
					# update selection
					var empty = project_controller.get_image_layers().new_empty_image()
					empty.blit_rect(_resized_split_fg, src_rect, area_rect.position)
					image_mask.set_mask(empty) 
					project_controller.raise_action(project_controller.ACTION_IMAGE_MASK_CHANGED)
					
			TransformState.RESIZE:
				var data = RectUtils.get_resize_target_and_anchor(_pre_rect, _transform_index, false)
				var resize_rect = RectUtils.resize_rect(_pre_rect, end_pos, data.target, data.anchor)
				set_area_rects(resize_rect)
				
				## Handle image_layers
				if moved:
					var active_index = project_controller.get_active_layer_index()
					project_controller.set_layer(active_index, _bg_image_layer.duplicate(true))
					
					var empty = project_controller.get_image_layers().new_empty_image()
					
					if area_rect.size.x >= 1 and area_rect.size.y >= 1:
						_resized_split_fg = _split_fg.duplicate()
						_resized_split_fg.resize(area_rect.size.x, area_rect.size.y, Image.Interpolation.INTERPOLATE_NEAREST)
						var src_rect = Rect2(Vector2.ZERO, _resized_split_fg.get_size())
						project_controller.blit_image(active_index, _resized_split_fg, _resized_split_fg, src_rect, area_rect.position, ImageLayers.BlitMode.BLEND)
						
						empty.blit_rect(_resized_split_fg, src_rect, area_rect.position)
						
					image_mask.set_mask(empty) 
					project_controller.raise_action(project_controller.ACTION_IMAGE_MASK_CHANGED)
				

func is_full_mode() -> bool:
	return transform_mode == TransformMode.FULL

func set_area_rects(rect:Rect2):
	area_rect = rect
	rects = RectUtils.create_transform_rects(area_rect, rect_expand_size/camera_zoom/CanvasData.CELL_SIZE)
	property_updated.emit("rects", rects)

func get_transform_index(gpos:Vector2)->int:
	if rects:
		for i in rects.size():
			if not i: continue
			if rects[i].has_point(gpos):
				return i
	return 0

func update_transform_state(gpos:Vector2):
	_transform_index = get_transform_index(gpos)
	var _prev = transform_state
	if _transform_index == 0:
		transform_state = TransformState.MOVE 
	elif _transform_index == 5:
		transform_state = TransformState.MOVE
	elif _transform_index <= 9:
		transform_state = TransformState.RESIZE
	elif _transform_index <= 13 and rotatable:
		transform_state = TransformState.ROTATE
	else:
		_transform_index = 0
		transform_state = TransformState.NONE
	return _prev != transform_state
