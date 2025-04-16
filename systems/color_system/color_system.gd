class_name ColorSystem extends Node

var max_history_color :int= 10

var active_color = Color.BLACK
var history_color := ColorPalette.new()
var palettes := []
var active_palette_index :int= 0

var _palette_map_textures = []


func system_initialize():
	var db_system = SystemManager.db_system
	db_system.load_data_requested.connect(func():
		load_data(db_system.get_data("ColorSystem", {}))
		
	)
	db_system.save_data_requested.connect(func():
		db_system.set_data("ColorSystem", save_data())
	)
	
	SystemManager.ui_system.model_data_mapper.register_with(self, "active_color")
	SystemManager.ui_system.model_data_mapper.register_with(self, "history_color")
	SystemManager.ui_system.model_data_mapper.register_with(self, "palettes")
	SystemManager.ui_system.model_data_mapper.register_with(self, "active_palette_index")

func _creat_palette_texture(index:int) -> Texture2D:
	var image = ImageUtils.get_palette_image(palettes[index].colors, Vector2(20,20), 20)
	return ImageTexture.create_from_image(image) if image else null
	
func _init_palette_map():
	_palette_map_textures.clear()
	for index in palettes.size():
		_palette_map_textures.append(_creat_palette_texture(index))

func get_active_palette() -> ColorPalette:
	active_palette_index = clamp(active_palette_index, 0, palettes.size()-1)
	return palettes[active_palette_index]

func get_active_color() -> Color:
	return active_color

func new_palette():
	var index = -1
	for palette in palettes:
		index += 1
		if palette.colors.is_empty():
			active_palette_index = index
			SystemManager.ui_system.model_data_mapper.update("active_palette_index")
			return 
	palettes.append(ColorPalette.new())
	_palette_map_textures.append(null)
	active_palette_index = palettes.size()-1
	SystemManager.ui_system.model_data_mapper.update("palettes")
	SystemManager.ui_system.model_data_mapper.update("active_palette_index")

func remove_palette():
	if palettes.size() == 1:
		active_palette_index = 0
		palettes[0] = ColorPalette.new()
		_palette_map_textures[0] = null
	else:
		palettes.remove_at(active_palette_index)
		_palette_map_textures.remove_at(active_palette_index)
		active_palette_index = clamp(active_palette_index, 0, palettes.size()-1)
	SystemManager.ui_system.model_data_mapper.update("palettes")
	SystemManager.ui_system.model_data_mapper.update("active_palette_index")

func with_in_active_palette(fn:Callable):
	# fn(colors:PackColorArray)
	var palette = get_active_palette()
	var colors = palette.colors
	fn.call(colors)
	palette.colors = colors  # NOTE:必须要这样
	_palette_map_textures[active_palette_index] = _creat_palette_texture(active_palette_index)
	SystemManager.ui_system.model_data_mapper.update("palettes")
	SystemManager.ui_system.model_data_mapper.update("active_palette_index")
	
func save_data() -> Dictionary:
	return {
		"active_color":active_color,
		"history_color":history_color,
		"palettes":palettes,
		"active_palette_index":active_palette_index
	}

func load_data(data:Dictionary):
	active_color = data.get("active_color", Color.ALICE_BLUE)
	history_color = data.get("history_color", ColorPalette.new())
	palettes = data.get("palettes", [])
	active_palette_index = data.get("active_palette_index", 0)
	if not palettes or (palettes.size()==1 and palettes[0].colors.is_empty()):
		palettes.clear()
		palettes.append(preload("res://assets/color_palette/default_palette.tres"))
	_init_palette_map()
