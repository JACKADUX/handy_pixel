class_name ColorSystem extends Node

var active_color = Color.BLACK
var history_color := ColorPalette.new()

func system_initialize():
	var db_system = SystemManager.db_system
	db_system.load_data_requested.connect(func():
		load_data(db_system.get_data("ColorSystem", {}))
	)
	db_system.save_data_requested.connect(func():
		db_system.set_data("ColorSystem", save_data())
	)
	
	SystemManager.ui_system.model_data_mapper.register_with(self, "active_color")
	SystemManager.ui_system.model_data_mapper.register_with(self, "history_color")
	

func save_data() -> Dictionary:
	return {
		"active_color":active_color,
		"history_color":history_color,
	}

func load_data(data:Dictionary):
	active_color = data.get("active_color", Color.ALICE_BLUE)
	history_color = data.get("history_color", ColorPalette.new())
