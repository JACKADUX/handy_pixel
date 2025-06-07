extends Button

signal value_changed(value:Color)

@onready var advanced_color_panel: PanelContainer = $AdvancedColorPanel

func set_value(value:Color):
	advanced_color_panel.set_color(value)
