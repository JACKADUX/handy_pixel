class_name UISystem extends Node

var model_data_mapper := preload("res://systems/ui_system/ui_model_data.tres")

var projects_edit_state := false
var image_export_custom_mul :int = 1
var color_palette_mode :int = 0  # RECT / RGB/ HSV
var outline_generate_expend_size :int = 1
var outline_generate_pattern :Array = [0,1,0,1,0,1,0,1,0] 

var ui : Control

func system_initialize():
	SystemManager.db_system.save_data_requested.connect(func():
		SystemManager.db_system.set_data("UISystem", save_data())
	)
	
	SystemManager.db_system.load_data_requested.connect(func():
		load_data(SystemManager.db_system.get_data("UISystem", {}))
		model_data_mapper.update_all.call_deferred()
	)
	
	SystemManager.ui_system.model_data_mapper.register_with(self, "projects_edit_state")
	SystemManager.ui_system.model_data_mapper.register_with(self, "image_export_custom_mul")
	SystemManager.ui_system.model_data_mapper.register_with(self, "color_palette_mode")
	SystemManager.ui_system.model_data_mapper.register_with(self, "outline_generate_expend_size")
	SystemManager.ui_system.model_data_mapper.register_with(self, "outline_generate_pattern")
	
	
func save_data() -> Dictionary:
	var data = {}
	data["projects_edit_state"] = projects_edit_state
	data["image_export_custom_mul"] = image_export_custom_mul
	data["color_palette_mode"] = color_palette_mode
	data["outline_generate_expend_size"] = outline_generate_expend_size
	data["outline_generate_pattern"] = outline_generate_pattern
	return data
	
func load_data(data:Dictionary):
	projects_edit_state = data.get("projects_edit_state", false)
	image_export_custom_mul = data.get("image_export_custom_mul", false)
	color_palette_mode = data.get("color_palette_mode", 0)
	outline_generate_expend_size = data.get("outline_generate_expend_size", 1)
	outline_generate_pattern = data.get("outline_generate_pattern", outline_generate_pattern)

func get_tool_ui_control() -> ToolUIControl:
	if not ui:
		return 
	return ui.tool_ui_control

func get_temp_action_buttons_control() -> TempActionButtons:
	if not ui:
		return 
	return ui.temp_action_buttons
