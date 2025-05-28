extends PanelContainer

signal value_changed(value)

@onready var trace:= %Trace
@onready var label: Label = %Label
@onready var color_rect: ColorRect = $ColorRect

var _value :float = 1

func _ready() -> void:
	trace.location_changed.connect(func():
		_value = 1.-trace.get_location().y
		_update()
	)
	trace.drag_ended.connect(func():
		value_changed.emit(_value)
	)
	set_value(_value)
	
func set_value(value:float):
	_value = clamp(value, 0., 1.)
	_update()
	
func get_value() -> float:
	return _value
	
func _update():
	trace.set_location(Vector2(0, 1.-_value))
	color_rect.self_modulate.a = _value
	label.text = "%0.0f%%"%(_value*100)
	
