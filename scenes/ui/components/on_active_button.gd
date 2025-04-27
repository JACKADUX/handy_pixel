extends Button

func _ready() -> void:
	var parent = get_parent()
	if parent is not Button:
		return 
	focus_mode = Control.FOCUS_NONE
	parent.toggled.connect(func(toggle_on:bool):
		if toggle_on:
			show()
			mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			hide()
			mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
	hide()
