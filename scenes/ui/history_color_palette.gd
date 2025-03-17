class_name HistoryColorPalette extends Node

@onready var model := SystemManager.ui_system.model_data_mapper

@export var color_palette_generator : ColorPaletteGenerator

func _ready() -> void:
	model.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"active_color":
				var colors = SystemManager.color_system.history_color.colors
				var active_color = SystemManager.color_system.active_color
				if active_color in colors:
					if colors[0] == active_color:
						return 
					colors.remove_at(colors.find(active_color))
					pass
				colors.insert(0, active_color)
				if colors.size() > SystemManager.color_system.max_history_color:
					colors.resize(SystemManager.color_system.max_history_color)
				SystemManager.color_system.history_color.colors = colors
				SystemManager.ui_system.model_data_mapper.set_value("history_color", SystemManager.color_system.history_color)
				
			"history_color":
				color_palette_generator.generate(SystemManager.color_system.history_color)
				#color_palette_generator.activate_color.call_deferred(SystemManager.color_system.active_color)
	)
	
