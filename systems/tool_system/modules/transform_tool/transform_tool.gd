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

var _any_changed = false
var _start = false
var _pre_rect = Rect2()

enum TransformMode {PART, FULL}
var transform_mode := TransformMode.FULL

var _transform_indicator : Node2D
var _offset_pos := Vector2.ZERO


static func get_tool_name() -> String:
	return "transform_tool"

# 工具激活时调用
func activate() -> void:
	if not _transform_indicator:
		_transform_indicator = TransformIndicator.new()
		add_indicator(_transform_indicator)
		
		_tool_system.camera_tool.property_updated.connect(func(prop, value):
			match prop:
				"camera_zoom":
					camera_zoom = value
					
					set_area_rects(area_rect)
		)
		
	
	_tool_system.cursor_tool._cursor.hide()
	
	var select_tool :SelectionTool = _tool_system.get_tool("selection_tool")
	if select_tool.selection_mask_image and not select_tool.selection_mask_image.is_invisible():
		transform_mode = TransformMode.PART
	else:
		transform_mode = TransformMode.FULL
	transform_mode = TransformMode.PART
	set_area_rects(Rect2(1,1,10,10)) 
	
# 工具禁用时调用
func deactivate() -> void:
	_tool_system.cursor_tool._cursor.show()
	#canvas_manager.remove_child(_selection_area_indicator)
	#_selection_area_indicator.queue_free()

func is_full_mode() -> bool:
	return transform_mode == TransformMode.FULL


func _on_state_changed(state:InputRecognizer.State):
	pass
	#if state == InputRecognizer.State.NONE:
		#request_action_button(false)
	#elif state == InputRecognizer.State.HOVER:
		#request_action_button(true)

func _on_pressed(input_data:InputRecognizer.InputData):
	if not input_data.is_first():
		return
	var end_pos = get_canvas_pos_floor(input_data.end_position)
	if is_full_mode():
		if input_data.is_pressed():
			var image_layer = project_controller.get_image_layers().get_layer(project_controller.get_active_layer_index())
			_offset_pos = image_layer.position - Vector2i(end_pos)
	else:
		if input_data.is_pressed():
			_start = true
			_any_changed = false
			update_transform_state(get_canvas_pos(input_data.end_position))
		else:
			if _any_changed and transform_state == TransformState.RESIZE:
				pass # update image
				
			_start = false
			_any_changed = false
		
		# NOTE: 给尺寸为0的矩形补偿最小尺寸 1
		_pre_rect = area_rect
		if _pre_rect.size.x == 0:
			_pre_rect.size.x = 1
			if _transform_index in [1, 4, 7]:
				_pre_rect.position.x -= 1
		if _pre_rect.size.y == 0:
			_pre_rect.size.y = 1
			if _transform_index in [1, 2, 3]:
				_pre_rect.position.y -= 1
		var data = RectUtils.get_resize_target_and_anchor(_pre_rect, _transform_index)
		_offset_pos = data.target - end_pos
		
		
		
func _on_draged(input_data:InputRecognizer.InputData):
	if not input_data.is_first():
		return
	var end_pos = get_canvas_pos_floor(input_data.end_position)+_offset_pos
	if is_full_mode():
		project_controller.update_layer_property(project_controller.get_active_layer_index(), ImageLayer.PROP_POSITION, Vector2i(end_pos))
	else:
		if not _start:
			return 
		match transform_state:
			TransformState.MOVE:
				_any_changed = true
				area_rect.position = end_pos
				set_area_rects(area_rect)
			TransformState.RESIZE:
				_any_changed = true
				var data = RectUtils.get_resize_target_and_anchor(_pre_rect, _transform_index, false)
				var resize_rect = RectUtils.resize_rect(_pre_rect, end_pos, data.target, data.anchor)
				set_area_rects(resize_rect)

func set_area_rects(rect:Rect2):
	area_rect = rect
	rects = RectUtils.create_transform_rects(area_rect, rect_expand_size/camera_zoom/SystemManager.canvas_system.cell_size)
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
		transform_state = TransformState.NONE
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


func get_canvas_pos_floor(screen_pos:Vector2) -> Vector2:
	return get_canvas_pos(screen_pos).floor()

func get_canvas_pos_round(screen_pos:Vector2) -> Vector2:
	return get_canvas_pos(screen_pos).round()

func get_canvas_pos(screen_pos:Vector2) -> Vector2:
	return SystemManager.canvas_system.get_touch_local_position(screen_pos)/SystemManager.canvas_system.cell_size
