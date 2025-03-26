extends Button


func _ready() -> void:
	var parent = get_parent()
	if parent is not Button:
		return 
	focus_mode = Control.FOCUS_NONE
	parent.toggled.connect(func(toggle_on:bool):
		if toggle_on:
			mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
