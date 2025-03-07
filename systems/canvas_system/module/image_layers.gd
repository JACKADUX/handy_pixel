class_name ImageLayers extends Resource

@export var canvas_size := Vector2i(32,32)
@export var image_layers :Array[Image] = []
@export var image_positions := PackedVector2Array()

func initialize(p_canvas_size:Vector2i, color:=Color.TRANSPARENT) -> void:
	canvas_size = p_canvas_size
	image_layers.clear()
	image_positions.clear()
	new_layer_image(color)
	
func new_layer_image(color:=Color.TRANSPARENT) -> Image:
	var image = Image.create_empty(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	image_layers.append(image)
	image_positions.append(Vector2.ZERO)
	return image

func get_layer_image(index:int=0) -> Image:
	if index < 0 or image_layers.size() <= index:
		return 
	return image_layers[index]

func create_canvas_image(index:int=0) -> Image:
	var image = get_layer_image(index)
	if not image:
		return 
	var canvas_image = Image.create_empty(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	canvas_image.blit_rect(image, Rect2i(Vector2.ZERO, image.get_size()), image_positions[index])
	return canvas_image

func apply_canvas_image(image:Image, index:int=0):
	pass

func generate_final_image() -> Image:
	# FIXME: 
	return Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
