extends Node

@export var enable := true
@export var color_palet := false

@onready var model = SystemManager.ui_system.model_data_mapper
func _ready() -> void:
	if not enable:
		return 
	model.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"active_color":
				if color_palet:
					get_parent().set_color(value)
				else:
					if value.a == 0:
						value = Color.WHITE_SMOKE
					get_parent().self_modulate = value
	)
