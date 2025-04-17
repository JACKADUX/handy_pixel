extends Control

@onready var color_palette_generator: ColorPaletteGenerator = %ColorPaletteGenerator

func _ready() -> void:
	const DEFAULT_PALETTE = preload("res://assets/color_palette/default_palette.tres")
	color_palette_generator.generate(DEFAULT_PALETTE)


func _on_button_pressed() -> void:
	var palette = ColorPalette.new()
	var colors = []
	for i in range(randi_range(1, 100)):
		colors.append(Color(randf(),randf(),randf()))
	palette.colors = colors
	color_palette_generator.generate(palette)
