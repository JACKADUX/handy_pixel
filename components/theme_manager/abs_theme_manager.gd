class_name ABSThemeManager extends EditorScript

var theme_path :String
var builder: ThemeTypeBuilder

func _run():
	theme_path = _get_theme_path()
	builder = ThemeTypeBuilder.new(load(theme_path))
	builder.theme.clear()
	store_colors()
	_initialize()
	builder.save(theme_path)
	print("Theme Generated")
	
func _get_theme_path() -> String:
	return "res://assets/main_theme.tres"

func _initialize():
	pass

func set_font(font:Font, size:int):
	builder.theme.default_font = font
	builder.theme.default_font_size = size

func store_colors():
	builder.add_type("COLORS")
	var const_map = get_script().get_script_constant_map()
	for color:String in const_map:
		if color.begins_with("color_"):
			builder.set_color(color, const_map[color])
