extends Node

@export var color_palette_generator : ColorPaletteGenerator
@export var model_data_mapper :ModelDataMapper

func _ready() -> void:
	if not model_data_mapper:
		printerr(self, get_parent())
		return 
	model_data_mapper.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"active_color":
				color_palette_generator.activate_color(value)
	)
	
	color_palette_generator.color_selected.connect(func(color:Color):
		model_data_mapper.set_value("active_color", color)
	)
