extends Node

@export var widget: CustomSpinBoxWidget

func _ready() -> void:
	if not widget:
		widget = get_parent()
	
	widget.double_clicked.connect(func():
		var key_board = PopupArrowPanelManager.get_from_ui_system().call_popup_panel_plugin("keyboard")
		if not key_board:
			return 
		key_board.set_value(widget.get_value())
		key_board.confirmed.connect(func(value):
			if value == widget.get_value():
				return 
			widget.set_value(value)
			widget.value_changed.emit(widget.get_value()) 
			key_board.queue_free()
		)
		key_board.canceled.connect(func():
			key_board.queue_free()
		)

	)
