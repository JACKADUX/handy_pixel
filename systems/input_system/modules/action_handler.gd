class_name ActionHandler

signal action_called(action:String, state:State)

enum State {JUST_PRESSED, PRESSED, JUST_RELEASED}

var _actions :Array[String] = []

func has_action(action:String) -> bool:
	return action in _actions

func register_action(action:String):
	if has_action(action):
		return 
	_actions.append(action)
	InputMap.add_action(action)

func unregister_action(action:String):
	_actions.erase(action)
	InputMap.erase_action(action)

func process():
	for action in get_actions():
		if Input.is_action_just_pressed(action):
			action_called.emit(action, State.JUST_PRESSED)
		elif Input.is_action_pressed(action):
			action_called.emit(action, State.PRESSED)
		elif Input.is_action_just_released(action):
			action_called.emit(action, State.JUST_RELEASED)
			
func send_press(action:String):
	# NOTE: 不在这里直接发送信号的原因是多次触发的action可以在空闲帧只发送一次
	Input.action_press(action)

func send_release(action:String):
	Input.action_release(action)

func get_actions() -> PackedStringArray:
	return _actions

func register_actions_from_script(script:Script):
	var const_map = script.get_script_constant_map()
	for const_var :String in const_map:
		if const_var.begins_with("ACTION_"):
			register_action(const_map[const_var])
