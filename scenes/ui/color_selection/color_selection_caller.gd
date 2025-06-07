extends Node

@export var widget: Button
@export var color_panel : Control
func _ready() -> void:
	if not widget:
		widget = get_parent()
	
	widget.pressed.connect(func():
		var color_selection = PopupArrowPanelManager.get_from_ui_system().call_popup_panel_plugin("color_selection")
		color_selection.value_changed.connect(func(value):
			color_panel.set_color(value)
			widget.value_changed.emit(value)
		)
	)
	color_panel.activate.call_deferred()
