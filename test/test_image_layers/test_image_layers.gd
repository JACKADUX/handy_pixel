extends Control

@onready var image_layers_canvas: ImageLayersCanvas = $ImageLayersCanvas

const testxx = preload("res://assets/test.png")
var test_image :Image:
	get():
		var image = testxx.get_image()
		image.convert(Image.FORMAT_RGBA8) 
		return image

func _ready() -> void:
	#test1()
	test2()

func test2():
	#image_layers_canvas._debug_mode = true
	
	var image_layers := ImageLayers.new()
	image_layers.initialize(Vector2i(64,64), Color.BLACK)
	image_layers.set_layer_property(0, ImageLayer.PROP_POSITION, Vector2i(0,0))

	image_layers.blit_image(0, test_image, null, Rect2(20,20, 50, 50), Vector2(20,10))
	
	#var brush_image = PencilTool.generate_circle_pen_image(5)
	#var color_image :Image = brush_image.duplicate()
	#color_image.fill(Color.AQUA)
	#var color2_image :Image = brush_image.duplicate()
	#color2_image.fill(Color.TRANSPARENT)
	#
	#var src_rect = Rect2(Vector2.ZERO, color_image.get_size())
	#var dst = Vector2(4,6)
	#image_layers.blit_image(0, color_image, brush_image, src_rect, dst)
	#
	#dst = Vector2(18,19)
	#image_layers.blit_image(0, color_image, brush_image, src_rect, dst)
	#
	#dst = Vector2(17,20)
	#image_layers.blit_image(0, color2_image, brush_image, src_rect, dst)
	
	image_layers_canvas.init_with(image_layers)

func test1():
	var image = Image.create_empty(128,128, false, Image.FORMAT_RGBA8)
	image.fill(Color.AQUA)
	
	#image.blit_rect(test_image, Rect2(100,120, 50, 50), Vector2(64,32))
	
	var data = ImageLayers.extend_blit_image(test_image, test_image, null, Rect2(0,0,50,50), Vector2(0, 0))
	
	var image2 = data.image
	image2.save_png("user://test.png")
	OS.shell_open(ProjectSettings.globalize_path("user://test.png"))
	#
