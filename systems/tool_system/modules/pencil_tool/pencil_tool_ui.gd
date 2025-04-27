extends Control

@onready var dock_control: PanelContainer = %DockControl
@onready var bottom_bar: HBoxContainer = %BottomBar

func set_on_right():
	dock_control.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE, Control.PRESET_MODE_MINSIZE)
	bottom_bar.size_flags_horizontal = Control.SIZE_SHRINK_END
	
func set_on_left():
	dock_control.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE, Control.PRESET_MODE_MINSIZE)
	bottom_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
