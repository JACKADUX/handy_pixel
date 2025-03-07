extends Button

signal value_changed(value:Color)

@onready var color_rect = %ColorRect

@export var color_picker : SimpleColorPicker
# Called when the node enters the scene tree for the first time.
func _ready():
	color_picker.value_changed.connect(func(c):
		color_rect.color = c
		value_changed.emit(c)
	)

func set_value(value):
	if value == color_rect.color:
		return 
	color_rect.color = value
	color_picker.set_color(value)
