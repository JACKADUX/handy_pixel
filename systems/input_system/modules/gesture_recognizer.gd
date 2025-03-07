class_name GestureRecognizer extends InputRecognizer

var finger_1 : InputData = InputData.new(0)
var finger_2 : InputData = InputData.new(1)
var _fingers := [finger_1, finger_2]

var _initial_distance := 0

func get_touch_count() -> int:
	var count = 0
	for finger:InputData in _fingers:
		if finger.pressed:
			count += 1
	return count

func get_drag_count() -> int:
	var count = 0
	for finger:InputData in _fingers:
		if finger.pressed and finger.draged:
			count += 1
	return count

func get_input_data(index:=0) -> InputData:
	if index >= _fingers.size():
		return null
	return _fingers[index]

func handle_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.double_tap:
		double_clicked.emit(event.position)
		
	elif event is InputEventScreenTouch and event.index < 2:
		_handle_finger_touch(event)
		if not get_touch_count():
			state = State.NONE
			_initial_distance = 0
			
	_handle_drag(event)

func _handle_finger_touch(event:InputEventScreenTouch):
	var finger :InputData = _fingers[event.index]
	if event.pressed:
		# 记录触摸点
		finger.clear()
		finger.start_position = event.position
		finger.end_position = event.position
		finger.pressed = true
	else:
		# 移除离开的触摸点
		finger.pressed = false
	pressed.emit(finger.duplicate())

func _handle_finger_drag(event:InputEventScreenDrag):
	var finger :InputData = _fingers[event.index]
	finger.end_position = event.position
	finger.relative = event.relative
	finger.draged = true
	draged.emit(finger.duplicate())

func _handle_drag(event:InputEvent):
	# InputEventScreenDrag: index=0, position=((1331.4, 624.5)), relative=((2.393433, 0.0)), velocity=((746.4211, -3.695625)), pressure=1.00, tilt=((0.0, 0.0)), pen_inverted=(false)
	if event is not InputEventScreenDrag or event.index > 1:
		return 
	_handle_finger_drag(event)
	var touch_count = get_touch_count()
	var drag_count = get_drag_count()
	match state:
		State.NONE:
			if touch_count == 1:
				state = State.HOVER
			elif touch_count == 2 and drag_count == 2:
				var angle = finger_1.relative.angle_to(finger_2.relative)
				if abs(angle) < PI*0.5:
					state = State.PAN
				else:
					_initial_distance = finger_1.start_position.distance_to(finger_2.start_position)
					state = State.ZOOM
					
		State.HOVER:
			if finger_1.index == event.index:
				hovered.emit(event.relative)
		State.PAN:
			if touch_count == 2:
				paned.emit((finger_1.relative+finger_2.relative)*0.5)
		State.ZOOM:
			# 当有两个触摸点时计算缩放
			if touch_count == 2:
				_update_scale()


# 更新缩放比例
func _update_scale() -> void:
	var current_distance = finger_1.end_position.distance_to(finger_2.end_position)
	if _initial_distance == 0:
		return
	# 计算缩放因子
	var factor = current_distance / _initial_distance
	# 更新初始距离为当前距离，实现连续缩放
	_initial_distance = current_distance
	var initial_center = (finger_1.start_position+finger_2.start_position)*0.5
	zoomed.emit(initial_center, factor)
