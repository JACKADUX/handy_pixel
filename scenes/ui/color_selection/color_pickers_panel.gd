extends VBoxContainer

signal value_changed(value)

@onready var toggle_button_widget: Node = %ToggleButtonWidget
@onready var simple_color_picker = %SimpleColorPicker
@onready var rgb_color_picker = %RgbColorPicker
@onready var hsv_color_picker = %HSVColorPicker
@onready var color_nodes: HBoxContainer = %ColorNodes

@onready var color_palette_generator: ColorPaletteGenerator = %ColorPaletteGenerator

func _ready() -> void:
	for color_node in color_nodes.get_children():
		color_node.value_changed.connect(func(v):
			value_changed.emit(get_value())
		)
	
	color_palette_generator.color_selected.connect(func(c):
		value_changed.emit(c)
	)
		
func set_value(value):
	simple_color_picker.set_value(value)
	rgb_color_picker.set_value(value)
	hsv_color_picker.set_value(value)
	
func get_value():
	var color_picker = color_nodes.get_child(toggle_button_widget.get_value())
	return color_picker.get_value()
