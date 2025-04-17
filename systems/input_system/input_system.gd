class_name InputSystem extends Node

signal event_occurred(event:String, data:Dictionary)

var action_handler := ActionHandler.new()
var input_recognizer : InputRecognizer

func _ready() -> void:
	if OS.has_feature("editor"):
		input_recognizer = FakeGestureRecognizer.new()
	elif OS.has_feature("windows"):
		# NOTE: 如果需要，可以创建对应的 InputRecognizer
		input_recognizer = FakeGestureRecognizer.new()
		
	elif OS.has_feature("android"):
		input_recognizer = GestureRecognizer.new()
		
	input_recognizer.event_occurred.connect(func(event:String, data:Dictionary):
		event_occurred.emit(event, data)
	)
	
func _process(delta: float) -> void:
	action_handler.process()

func _unhandled_input(event: InputEvent) -> void:
	input_recognizer.handle_input(event)
