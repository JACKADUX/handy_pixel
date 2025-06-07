extends Control

var rd := RenderingServer.create_local_rendering_device()

@onready var texture_rect: TextureRect = $TextureRect
@onready var texture_rect_2: TextureRect = $TextureRect2

const test_texture = preload("res://assets/images/Checkerboard_16.svg")

func _ready() -> void:
	var image = test_texture.get_image()
	print(image)
	var outline = AdvanceOutline.new()
	outline.set_rd(rd)
	var out_image = outline._compute_gpu(AdvanceOutline.AdvanceOutlineData.create(image, AdvanceOutline.AdvanceOutlineData.OutLineType.PLUS_CROSS))
	texture_rect.texture = test_texture
	texture_rect_2.texture = ImageTexture.create_from_image(out_image)
	
		
