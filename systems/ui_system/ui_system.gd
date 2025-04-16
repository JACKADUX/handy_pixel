class_name UISystem extends Node

var model_data_mapper := preload("res://systems/ui_system/ui_model_data.tres")

var ui : Control
var popup_arrow_panel_manager : PopupArrowPanelManager
var action_button_panel : ActionButtonPanel

func system_initialize():

	SystemManager.db_system.save_data_requested.connect(func():
		pass
	)
	
	SystemManager.db_system.load_data_requested.connect(func():
		model_data_mapper.update_all.call_deferred()
	)
