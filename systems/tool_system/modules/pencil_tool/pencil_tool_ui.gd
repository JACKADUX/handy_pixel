extends Control

@onready var dock_control: PanelContainer = %DockControl
@onready var bottom_bar: HBoxContainer = %BottomBar

@onready var margin_container: MarginContainer = $DockControl/MarginContainer

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_handle_ui_direction()
	
func _handle_ui_direction():
	var margin_props = ["margin_left","margin_top","margin_right","margin_bottom"]
	var config = [0, 96, 0, 24] if SystemManager.ui_system.is_virtical() else [0,0,0,0]
	for index in margin_props.size():
		margin_container.add_theme_constant_override(margin_props[index], config[index])

func set_on_right():
	dock_control.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE, Control.PRESET_MODE_MINSIZE)
	bottom_bar.size_flags_horizontal = Control.SIZE_SHRINK_END
	
func set_on_left():
	dock_control.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE, Control.PRESET_MODE_MINSIZE)
	bottom_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
