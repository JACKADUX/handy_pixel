extends VBoxContainer

signal value_changed(value:Color)

@onready var color_palette_generator: ColorPaletteGenerator = %ColorPaletteGenerator
@onready var menu_button: MenuButton = %MenuButton
@onready var add_color_button:= %AddColorButton
@onready var add_palette_button:= %AddPaletteButton
@onready var remove_palette_button: Button = %RemovePaletteButton
@onready var remove_color_button: Button = %RemoveColorButton

func _ready() -> void:
	
	SystemManager.ui_system.model_data_mapper.property_updated.connect(func(prop_name:String, value:Variant):
		match prop_name:
			"palettes":
				update_menu()
	)
	
	color_palette_generator.color_selected.connect(func(value):
		value_changed.emit(value)
	)
	
	add_color_button.pressed.connect(func():
		SystemManager.color_system.with_in_active_palette(func(colors:PackedColorArray):
			var color = SystemManager.color_system.get_active_color()
			colors.append(color)
		)
	)
	
	add_palette_button.pressed.connect(func():
		SystemManager.color_system.new_palette()
	)
	
	remove_color_button.pressed.connect(func():
		var index = color_palette_generator.get_color_index(SystemManager.color_system.get_active_color())
		if index == -1:
			return 
		SystemManager.color_system.with_in_active_palette(func(colors:PackedColorArray):
			colors.remove_at(index)
		)
	)
	
	remove_palette_button.pressed.connect(func():
		var center = remove_palette_button.global_position + remove_palette_button.get_rect().get_center()
		var dialog = PopupArrowPanelManager.get_from_ui_system().confirm_dialog(center+Vector2(0, 96))
		dialog.confirmed.connect(func():
			SystemManager.color_system.remove_palette()
		)
	)
	
	update_menu()
	
func update_menu():
	var popup = menu_button.get_popup()
	popup.clear()
	for index:int in SystemManager.color_system.get_palettes_count():
		popup.add_icon_item(SystemManager.color_system._palette_map_textures[index], "")
