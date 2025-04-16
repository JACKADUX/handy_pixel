extends PanelContainer

@export var color := Color.WHITE
@onready var color_rect: ColorRect = %ColorRect
@onready var color_rect_2: ColorRect = %ColorRect2
@onready var active: Panel = %Active

var _active:= false

func _ready() -> void:
	set_color(color)
	deactivate()
	
func set_color(value:Color):
	color = value
	color_rect.color = Color(value, 1)
	color_rect_2.color = value
	
func get_color() -> Color:
	return color

func activate():
	_active = true
	active.show()
	
func deactivate():
	_active = false
	active.hide()
