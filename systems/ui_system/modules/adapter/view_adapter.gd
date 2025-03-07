class_name ViewAdapter extends Node

signal value_changed(value:Variant)

@export var view : Node

func _ready() -> void:
	if not view:
		view = get_parent()
	adapt_view()

func adapt_view():
	#view.button_pressed.connect(func():
		#value_changed.emit()
	#)
	pass

func set_value(value:Variant):
	pass
