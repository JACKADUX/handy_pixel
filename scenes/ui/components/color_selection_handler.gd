extends Node

@export var color_palette_generator : ColorPaletteGenerator

@onready var model := SystemManager.ui_system.model_data_mapper

func _ready() -> void:
	model.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"active_color":
				color_palette_generator.activate_color(value)
	)
	
	color_palette_generator.color_selected.connect(func(color:Color):
		model.set_value("active_color", color)
	)
