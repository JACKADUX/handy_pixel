class_name InputActionRequester extends Node

@export var controller:Control
@export var action_name:String

@onready var action_handler :ActionHandler= SystemManager.input_system.action_handler

func _ready() -> void:
	if not controller:
		controller = get_parent()
	if controller is Button or controller is TouchButton:
		controller.button_down.connect(func():
			action_handler.send_press(action_name)
		)
		controller.button_up.connect(func():
			action_handler.send_release(action_name)
		)
