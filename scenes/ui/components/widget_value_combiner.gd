extends Node

signal value_changed(value)

@export var value_type :String
@export var widgets :Array[Control]= []

func _ready() -> void:
	for i in widgets.size():
		widgets[i].value_changed.connect(func(value):
			value_changed.emit(get_value())
		)

func get_value() -> Variant:
	var value
	match value_type:
		"Vector2":
			value = Vector2.ZERO
		_:
			return null
	for i in widgets.size():
		value[i] = widgets[i].get_value()
	return value
	
func set_value(value):
	for i in widgets.size():
		widgets[i].set_value(value[i])
