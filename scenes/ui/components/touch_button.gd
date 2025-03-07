class_name TouchButton extends Control

signal button_down
signal pressed
signal button_up
signal toggled(toggled_on:bool)

@export var disabled := false
@export var button_index := 1
@export var toggle_mode :bool=false
@export var button_pressed := false
@export var keep_pressed := false

func _gui_input(event: InputEvent) -> void:
	if not visible or disabled:
		return 
	if event is InputEventScreenTouch and event.index == button_index:
		button_pressed = event.pressed
		if event.pressed:
			button_down.emit()
		else:
			button_up.emit()
		if toggle_mode:
			toggled.emit(button_pressed)
		elif not event.pressed:
			pressed.emit()  # release mode
