class_name GestureRecognizer extends InputRecognizer

var _initial_distance := 0

func handle_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var finger :InputData = input_datas.get_or_add_input_data(event.index)
		if event.pressed:
			# 记录触摸点
			finger.clear()
			finger.start_position = event.position
			finger.end_position = event.position
			finger.pressed = true
		else:
			# 移除离开的触摸点
			finger.pressed = false
		finger.double_clicked = event.double_tap
		
		send_event(EVENT_INPUT_HANDLED, {"input_datas":input_datas, "state":state})
		
		if not input_datas.get_touch_count():
			_initial_distance = 0
			set_state(State.NONE)
			input_datas.clear()
		
	if event is InputEventScreenDrag:
		var finger :InputData = input_datas.get_input_data(event.index)
		finger.end_position = event.position
		finger.relative = event.relative
		finger.draged = true
		_update_state(event)
		send_event(EVENT_INPUT_HANDLED, {"input_datas":input_datas, "state":state})

func _update_state(event:InputEventScreenDrag):
	# InputEventScreenDrag: index=0, position=((1331.4, 624.5)), relative=((2.393433, 0.0)), velocity=((746.4211, -3.695625)), pressure=1.00, tilt=((0.0, 0.0)), pen_inverted=(false)
	var touch_count = input_datas.get_touch_count()
	var drag_count = input_datas.get_drag_count()
	match state:
		State.NONE:
			if touch_count == 1:
				set_state(State.HOVER)
			elif touch_count == 2 and drag_count == 2:
				var finger_1 = input_datas.get_input_data(0)
				var finger_2 = input_datas.get_input_data(1)
				var angle = finger_1.relative.angle_to(finger_2.relative)
				if abs(angle) < PI*0.5:
					set_state(State.PAN)
				else:
					_initial_distance = finger_1.start_position.distance_to(finger_2.start_position)
					set_state(State.ZOOM)
		State.HOVER:
			if event.index == 0:
				var finger_1 = input_datas.get_input_data(0)
				send_event(EVENT_HOVERED, {"relative": finger_1.relative})
		State.PAN:
			if touch_count == 2:
				var finger_1 = input_datas.get_input_data(0)
				var finger_2 = input_datas.get_input_data(1)
				var pan = (finger_1.relative+finger_2.relative)*0.5
				send_event(EVENT_PANED, {"relative": finger_1.relative})
		State.ZOOM:
			# 当有两个触摸点时计算缩放
			if touch_count == 2:
				var zoom_data = _update_zoom()
				if zoom_data:
					send_event(EVENT_ZOOMED, zoom_data)
					

# 更新缩放比例
func _update_zoom() -> Dictionary:
	var finger_1 = input_datas.get_input_data(0)
	var finger_2 = input_datas.get_input_data(1)
	var current_distance = finger_1.end_position.distance_to(finger_2.end_position)
	if _initial_distance == 0:
		return {}
	# 计算缩放因子
	var factor = current_distance / _initial_distance
	# 更新初始距离为当前距离，实现连续缩放
	_initial_distance = current_distance
	var center = (finger_1.start_position+finger_2.start_position)*0.5
	return {"center":center, "factor": factor}
