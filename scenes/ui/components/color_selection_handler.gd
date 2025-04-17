extends Node

@export var color_palette_generator : ColorPaletteGenerator
@export var model_data_mapper :ModelDataMapper
@export var use_history_palette := false

func _ready() -> void:
	if not model_data_mapper:
		printerr(self, get_parent())
		return 
	model_data_mapper.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"active_color":
				color_palette_generator.activate_color.call_deferred(value)
			"history_color":
				update()
			"active_palette_index":
				update()
	)
	
	color_palette_generator.color_selected.connect(func(color:Color):
		SystemManager.ui_system.model_data_mapper.set_value("active_color", color)
	)
	update()
	
func update():
	if not color_palette_generator.is_node_ready():
		await color_palette_generator.ready
	if use_history_palette:
		color_palette_generator.generate(SystemManager.color_system.history_color)
	else:
		color_palette_generator.generate(SystemManager.color_system.get_active_palette())
