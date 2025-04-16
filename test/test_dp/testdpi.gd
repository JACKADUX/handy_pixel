extends Control

func _ready() -> void:
	const DEFAULT_PALETTE = preload("res://assets/color_palette/default_palette.tres")
	var image = ImageUtils.get_palette_image(DEFAULT_PALETTE.colors)
	$TextureRect.texture = ImageTexture.create_from_image(image)
	image.save_png("user://test.png")
