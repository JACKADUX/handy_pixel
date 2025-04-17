## class_name SystemInterface 
extends Node

var any_project_setting_var := "any_project_setting_var"
var any_data := "any_data"

func system_initialize():
	SystemManager.db_system.save_data_requested.connect(func():
		SystemManager.db_system.set_data("SystemInterface", save_data())
		SystemManager.db_system.set_project_setting("any_project_setting_var", any_project_setting_var)
	)
	
	SystemManager.db_system.load_data_requested.connect(func():
		load_data(SystemManager.db_system.get_data("SystemInterface", {}))
		any_project_setting_var = SystemManager.db_system.get_project_setting("any_project_setting_var")
	)
	
	SystemManager.ui_system.model_data_mapper.register_with(self, "any_data")
	
	
func save_data() -> Dictionary:
	return {
		"any_data":any_data
	}
	
func load_data(data:Dictionary):
	any_data = data.get("any_data", "defualt_value")
