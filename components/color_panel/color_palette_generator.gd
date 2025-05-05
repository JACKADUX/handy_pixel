class_name ColorPaletteGenerator extends Control

signal color_selected(color:Color)

const AdvancedColorPanel = preload("res://components/color_panel/advanced_color_panel.gd")
const ADVANCED_COLOR_PANEL = preload("res://components/color_panel/advanced_color_panel.tscn")

@export var default_palette :ColorPalette
@export var container_agent : ContainerAgent
@export var max_color_num := -1
@export var min_size := 96

var group = "GROUP_COLOR_PALETTE"
func _ready() -> void:
	group += str(get_instance_id())
	container_agent.clear()
	generate(default_palette)
	
func generate(palette:ColorPalette):
	if not palette:
		container_agent.clear()
		return 
	var colors = palette.colors
	if max_color_num != -1:
		colors = colors.slice(0, max_color_num)
	if not colors:
		container_agent.clear()
		return 
	var index = -1
	var items = container_agent.get_items()
	for color in colors:
		index += 1
		var color_panel
		if items.size() <= index:
			color_panel  = ADVANCED_COLOR_PANEL.instantiate()
			var fake_button = FakeButton.new()
			color_panel.add_child(fake_button)
			container_agent.add_item(color_panel)
			color_panel.add_to_group(group)
			color_panel.custom_minimum_size = Vector2.ONE*min_size
			fake_button.double_clicked.connect(func():
				pass
			)
			fake_button.pressed.connect(func():
				color_selected.emit(color_panel.get_color())
				get_tree().call_group(group, "deactivate")
				color_panel.activate()
			)
		else:
			color_panel = items[index]
		color_panel.set_color(color)
		
	var dif = container_agent.get_item_count()-colors.size()
	items = container_agent.get_items()
	if colors.size() > 0 :
		for i in range(dif):
			var item = items.pop_back()
			container_agent.remove_item(item)
	get_tree().call_group(group, "deactivate")

func get_color_index(color:Color) -> int:
	var index = -1
	for color_panel in container_agent.get_items():
		index += 1
		if color_panel.get_color() == color:
			return index
	return index
	
func activate_color(color:Color):
	get_tree().call_group(group, "deactivate")
	for color_panel in container_agent.get_items():
		if color_panel.get_color() == color:
			color_panel.activate()
			break 
		
		
