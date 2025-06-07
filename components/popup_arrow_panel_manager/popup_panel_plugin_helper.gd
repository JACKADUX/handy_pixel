extends Node

@export var plugin_name:String

func _ready() -> void:
	var parent = get_parent()
	if parent is not Button:
		return 
	parent.pressed.connect(func():
		PopupArrowPanelManager.get_from_ui_system().call_popup_panel_plugin(plugin_name)
	)
	
