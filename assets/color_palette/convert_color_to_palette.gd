@tool
extends EditorScript

func _run() -> void:
	return 
	var file = "res://assets/color_palette/cc-29.txt"
	var color_palette = ColorPalette.new()
	var colors = PackedColorArray()
	var content = FileAccess.get_file_as_string(file)
	for html_color in content.split("\r\n", false):
		colors.append(Color.html(html_color))
	color_palette.colors = colors
	#ResourceSaver.save(color_palette, "res://assets/color_palette/default_palette.tres")
