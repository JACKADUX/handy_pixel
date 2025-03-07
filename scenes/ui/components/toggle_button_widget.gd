extends Node

signal value_changed(value:Variant)

@export var button_datas : Dictionary[Button, Variant]

func _ready() -> void:
	for button :Button in button_datas.keys():
		button.pressed.connect(func():
			value_changed.emit(button_datas[button])
		)

func set_value(value):
	for button :Button in button_datas.keys():
		button.set_pressed_no_signal(button_datas[button] == value)
	
func get_value():
	for button :Button in button_datas.keys():
		if button.button_pressed:
			return button_datas[button]
	return 
