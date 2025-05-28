# class_name ProjectControllerActionRequester 
extends Node

@export var button:Button
@export var action_name:String

@onready var project_controller :ProjectController

func _ready() -> void:
	if not button:
		button = get_parent()
	if not SystemManager.is_initialized():
		await SystemManager.system_initialized
	
	project_controller = SystemManager.project_system.project_controller
	
	if button is Button:
		button.button_up.connect(func():
			project_controller.request_action(action_name)
		)
