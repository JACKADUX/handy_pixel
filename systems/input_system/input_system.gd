class_name InputSystem extends Node

signal double_clicked(position:Vector2)
signal hovered(relative:Vector2)
signal paned(relative:Vector2)
signal zoomed(center:Vector2, factor:float)

signal state_changed

signal pressed(input_data:InputRecognizer.InputData)
signal draged(input_data:InputRecognizer.InputData)


signal input_event()

# TODO: 把当前的状态用图标表示在用户界面
var state := InputRecognizer.State.NONE :
	set(value):
		if state == value:
			return 
		state = value
		state_changed.emit(state)

var action_handler := ActionHandler.new()

var mouse_recognizer := MouseRecognizer.new()
var gesture_recognizer := GestureRecognizer.new()

func _ready() -> void:
	if OS.has_feature("editor"):
		mouse_recognizer.bind_to_input_system(self)
	else:
		gesture_recognizer.bind_to_input_system(self)

func _process(delta: float) -> void:
	action_handler.process()

func _unhandled_input(event: InputEvent) -> void:
	handle_input(event)

func handle_input(event: InputEvent):
	if OS.has_feature("editor"):
		mouse_recognizer.handle_input(event)
	else: 
		gesture_recognizer.handle_input(event)

func get_input_data(index:=0) -> InputRecognizer.InputData:
	var data
	if OS.has_feature("editor"):
		data = mouse_recognizer.get_input_data(index)
	else:
		data = gesture_recognizer.get_input_data(index)
	return data
