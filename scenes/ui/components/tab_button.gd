extends Node

@export var button: Button

func _ready() -> void:
	if not button:
		return 
	button.toggled.connect(func(toggled_on:bool):
		get_parent().visible = toggled_on
	)
	get_parent().visible = button.button_pressed
