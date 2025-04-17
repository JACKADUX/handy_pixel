class_name UISystem extends Node

var model_data_mapper := preload("res://systems/ui_system/ui_model_data.tres")

var projects_edit_state := false
var image_export_custom_mul :int = 1

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
	
	
func save_data() -> Dictionary:
	var data = {}
	data["projects_edit_state"] = projects_edit_state
	data["image_export_custom_mul"] = image_export_custom_mul
	return data
	
func load_data(data:Dictionary):
	projects_edit_state = data.get("projects_edit_state", false)
	image_export_custom_mul = data.get("image_export_custom_mul", false)

func get_tool_ui_control() -> ToolUIControl:
	if not ui:
		return 
	return ui.tool_ui_control
