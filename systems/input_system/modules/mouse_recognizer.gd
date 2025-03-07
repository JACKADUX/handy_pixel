class_name MouseRecognizer extends InputRecognizer

var _is_zooming: bool = false
var _is_panning: bool = false
var _is_hover: bool = false

var input_data_1 : InputData = InputData.new(0)

var _mouse_pos : Vector2

func handle_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.key_label == KEY_Q:
			_is_hover = event.is_pressed()
			if _is_hover:
				input_data_1.clear()
				input_data_1.start_position = _mouse_pos
				input_data_1.end_position = _mouse_pos
				input_data_1.pressed = true
				state = State.HOVER
			else:
				input_data_1.pressed = false
				state = State.NONE
		if event.key_label == KEY_I:
			_send_action(ToolSystem.ACTION_PICK_COLOR, event.is_pressed())
		if event.key_label == KEY_F:
			_send_action(ToolSystem.ACTION_FILL_COLOR, event.is_pressed())
				
	if event is InputEventMouseButton:
		if event.double_click:
			double_clicked.emit(event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_is_zooming = event.is_pressed()
			zoomed.emit(event.position, 0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_is_zooming = event.is_pressed()
			zoomed.emit(event.position, 1.1)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_panning = event.is_pressed()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if not _is_hover:
				return 
			_send_action(ToolSystem.ACTION_TOOL_MAIN_PRESSED, event.pressed)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if not _is_hover:
				return 
			_send_action(ToolSystem.ACTION_TOOL_CANCEL_PRESSED, event.pressed)

	if event is InputEventMouseMotion:
		_mouse_pos = event.position
		if _is_panning:
			paned.emit(event.relative)
		elif _is_hover:
			input_data_1.end_position = event.position
			input_data_1.relative = event.relative
			input_data_1.draged = true
			hovered.emit(event.relative)
		
func _send_action(action:String, pressed:bool):
	if pressed:
		SystemManager.input_system.action_handler.send_press(action)
	else:
		SystemManager.input_system.action_handler.send_release(action)

func get_input_data(index:=0) -> InputData:
	return input_data_1
