extends PanelContainer

signal value_changed(value:bool)

@onready var off_button: Button = %OffButton
@onready var on_button: Button = %OnButton

@export var bool_value:= false

func _ready() -> void:
	on_button.pressed.connect(func():
		value_changed.emit(true)
	)
	off_button.pressed.connect(func():
		value_changed.emit(false)
	)
	set_value(bool_value)
	
	
func set_value(value:bool):
	bool_value = value
	on_button.set_pressed_no_signal(value)
	off_button.set_pressed_no_signal(not value)
	
func get_value()->bool:
	return bool_value
