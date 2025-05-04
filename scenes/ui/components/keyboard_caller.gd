extends Node

@export var widget: CustomSpinBoxWidget

func _ready() -> void:
	if not widget:
		widget = get_parent()
	
	widget.double_clicked.connect(func():
		var manager = PopupArrowPanelManager.get_from_ui_system()
		manager.call_keyboard(widget.get_value(), func(value:float):
			if value == widget.get_value():
				return 
			widget.set_value(value)
			widget.value_changed.emit(widget.get_value()) # 
		)
	)
