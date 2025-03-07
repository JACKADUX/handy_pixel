class_name HistoryColorPalette extends Node

@onready var model := SystemManager.ui_system.model_data_mapper

@export var max_color_num := 5
@export var color_palette_generator : ColorPaletteGenerator

func _ready() -> void:
	model.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"active_color":
				pass
				#var colors = project_setting.history_color.colors
				#var active_color = project_setting.active_color
				#if active_color in colors:
					#if colors[0] == active_color:
						#return 
					#colors.remove_at(colors.find(active_color))
					#pass
				#colors.insert(0, active_color)
				#if colors.size() > max_color_num:
					#colors.resize(max_color_num)
				#project_setting.history_color.colors = colors
				#controller.set_value("history_color", project_setting.history_color)
				
			"history_color":
				#color_palette_generator.generate(project_setting.history_color)
				pass
				
	)
