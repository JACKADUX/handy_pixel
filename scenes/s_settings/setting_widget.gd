extends HBoxContainer

@onready var label: Label = $Label

func set_title(value:String):
	label.text = value
	
func add_control(control:Control):
	add_child(control)
