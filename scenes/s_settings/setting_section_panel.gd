extends PanelContainer

@onready var label: Label = %Label
@onready var v_box_container: VBoxContainer = %VBoxContainer

func add_widget(control:Control):
	v_box_container.add_child(control)

func set_title(value:String):
	label.text = value
