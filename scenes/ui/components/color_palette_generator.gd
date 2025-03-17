class_name ColorPaletteGenerator extends Control

signal color_selected(color:Color)

@export var default_palette :ColorPalette
@export var container_agent : ContainerAgent
@export var group = "GROUP_COLOR_PALETTE"
@export var scale_factor := 0.8
@export var max_color_num := 50

func _ready() -> void:
	generate(default_palette)

func generate(palette:ColorPalette):
	container_agent.clear()
	if not palette:
		return 
	var index = 0
	for color in palette.colors:
		index += 1
		if index > max_color_num:
			return
		var color_panel = ColorPanel.new()
		var fake_button = FakeButton.new()
		color_panel.scale_factor = scale_factor
		color_panel.add_child(fake_button)
		container_agent.add_item(color_panel)
		color_panel.add_to_group(group)
		color_panel.custom_minimum_size = Vector2.ONE*96
		color_panel.set_color(color)
		fake_button.pressed.connect(func():
			color_selected.emit(color_panel.get_color())
			get_tree().call_group(group, "deactivate")
			color_panel.activate()
		)
	
func activate_color(color:Color):
	get_tree().call_group(group, "deactivate")
	for color_panel in container_agent.get_items():
		if color_panel.get_color() == color:
			color_panel.activate()
			break 
		
		
