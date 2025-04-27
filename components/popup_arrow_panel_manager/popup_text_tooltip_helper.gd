extends Node

@export var pressed_node:Node

@export var title := ""
@export_multiline var tooltip := ""
@export var duration :float = 1

func _ready() -> void:
	if not pressed_node:
		pressed_node = get_parent()
	if not title and not tooltip:
		queue_free()
		return 
	if pressed_node.has_signal("pressed"):
		pressed_node.pressed.connect(func():
			PopupArrowPanelManager.get_from_ui_system().tooltip_dialog(title, tooltip, duration)
		)
	
