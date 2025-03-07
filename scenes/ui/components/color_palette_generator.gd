class_name ColorPaletteGenerator extends Control

signal color_selected(color:Color)

@export var default_palette :ColorPalette
@export var container_agent : ContainerAgent
@export var group = "GROUP_COLOR_PALETTE"

func _ready() -> void:
	generate(default_palette)

func generate(palette:ColorPalette):
	container_agent.clear()
	if not palette:
		return 
	for color in palette.colors:
		var color_panel = ColorPanel.new()
		container_agent.add_item(color_panel)
		color_panel.add_to_group(group)
		color_panel.custom_minimum_size = Vector2.ONE*96
		color_panel.set_color(color)
		color_panel.pressed.connect(func():
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
		
		
