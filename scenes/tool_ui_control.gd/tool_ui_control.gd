class_name ToolUIControl extends Control

@onready var margin_container: MarginContainer = %MarginContainer
@onready var action_button_panel: ActionButtonPanel = %ActionButtonPanel


func add_tool_ui(node:Control):
	margin_container.add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE)
	node.mouse_filter = Control.MOUSE_FILTER_PASS
