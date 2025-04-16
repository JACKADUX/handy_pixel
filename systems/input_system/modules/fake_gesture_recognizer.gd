class_name FakeGestureRecognizer extends InputRecognizer

# NOTE: 用于在电脑模拟测试手机的输入，方便debug

func handle_input(event: InputEvent) -> void:
	
	if event is InputEventKey:
		if event.key_label == KEY_Q:
			_send_action(ToolSystem.ACTION_TOOL_MAIN_PRESSED, event.is_pressed())
		if event.key_label == KEY_W:	
			_send_action(ToolSystem.ACTION_TOOL_CANCEL_PRESSED, event.is_pressed())	
		if event.key_label == KEY_I:
			_send_action(ToolSystem.ACTION_PICK_COLOR, event.is_pressed())
		if event.key_label == KEY_F:
			_send_action(ToolSystem.ACTION_FILL_COLOR, event.is_pressed())
				
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_DOWN,MOUSE_BUTTON_WHEEL_UP] :
			if event.is_pressed():
				var factor = 0.9 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else 1.1
				set_state(State.ZOOM)
				send_event(EVENT_ZOOMED, {"center":event.position, "factor": factor})
			else:
				set_state(State.NONE)
			#send_event(EVENT_INPUT_HANDLED, {"input_datas":input_datas, "state":state})
			
		elif event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			var input_data_1 = input_datas.get_or_add_input_data(0)
			if event.is_pressed():
				input_data_1.clear()
				input_data_1.start_position = event.position
				input_data_1.end_position = event.position
				input_data_1.pressed = true
				if event.button_index == MOUSE_BUTTON_LEFT:
					set_state(State.HOVER)
				else:
					set_state(State.PAN)
			else:
				input_data_1.pressed = false
				
			if event.button_index == MOUSE_BUTTON_LEFT:
				input_data_1.double_clicked = event.double_click
			send_event(EVENT_INPUT_HANDLED, {"input_datas":input_datas, "state":state})
			
			if not event.is_pressed():
				set_state(State.NONE)
				input_datas.clear()
			
	if event is InputEventMouseMotion:
		if state != State.HOVER and state != State.PAN:
			return 
		var input_data_1 = input_datas.get_input_data(0)
		input_data_1.end_position = event.position
		input_data_1.relative = event.relative
		input_data_1.draged = true
		if state == State.HOVER:
			send_event(EVENT_HOVERED,  {"relative": input_data_1.relative})
		elif state == State.PAN:
			send_event(EVENT_PANED,  {"relative": input_data_1.relative})
		send_event(EVENT_INPUT_HANDLED, {"input_datas":input_datas, "state":state})
		
func _send_action(action:String, pressed:bool):
	if pressed:
		SystemManager.input_system.action_handler.send_press(action)
	else:
		SystemManager.input_system.action_handler.send_release(action)
