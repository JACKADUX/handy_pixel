class_name ImageLayers extends Resource

@export var canvas_size := Vector2i(32,32)
@export var layers :Array[ImageLayer] = []

func initialize(p_canvas_size:Vector2i, color:=Color.TRANSPARENT) -> void:
	canvas_size = p_canvas_size
	layers.clear()
	create_layer(0)
	get_layer(0).image.fill(color)

func is_valid_layer(index:int) -> bool:
	return 0 <= index and index < layers.size() 

func create_layer(index:int) -> bool:
	if index < 0 or layers.size() < index : # NOTE: 这里的判定和 is_valid_layer 不一样
		return false
	var layer = ImageLayer.create_with(canvas_size)
	layers.insert(index, layer)
	return true

func delete_layer(index:int) -> bool:
	if not is_valid_layer(index):
		return false
	layers.remove_at(index)
	return true
	
func move_layer(index:int, to_index:int) -> bool:
	if index == to_index:
		return false
	if not is_valid_layer(index) or not is_valid_layer(to_index):
		return false
	var layer = layers[to_index] 
	layers[to_index] = layers[index] 
	layers[index] = layer
	return true

func get_layers() -> Array[ImageLayer]:
	return layers.duplicate()

func get_layer(index:int) -> ImageLayer:
	if not is_valid_layer(index):
		return null
	return layers[index]

func set_layer(index:int, image_layer:ImageLayer) -> bool:
	if not is_valid_layer(index):
		return false
	if image_layer in layers:
		return false
	layers[index] = image_layer
	return true

func get_layer_count() -> int:
	return layers.size()

func get_layer_property(index:int, property:String):
	return get_layer(index).get(property)

func set_layer_property(index:int, property:String, value:Variant):
	get_layer(index).set(property, value)

func create_canvas_image(index:int=0) -> Image:
	var layer = get_layer(index)
	if not layer:
		return 
	var canvas_image = Image.create_empty(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	canvas_image.blit_rect(layer.image, Rect2i(Vector2.ZERO, layer.image.get_size()), layer.position)
	return canvas_image

func generate_final_image() -> Image:
	var image = Image.create_empty(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	for index in layers.size():
		var layer = layers[index]
		if layer.visible:
			image.blit_rect_mask(layer.image, layer.image, Rect2i(Vector2.ZERO, layer.image.get_size()), layer.position)
	return image
	
func is_inside_canvas(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < get_width() and pos.y < get_height()

func get_pixel(pos: Vector2i) -> Color:
	var color = Color.TRANSPARENT
	for index in get_layer_count():
		var layer = layers[index]
		var _color = layer.image.get_pixelv(pos)
		if _color.a != 0:
			color = _color
			break
	return color

func get_size() -> Vector2i:
	return canvas_size

func get_width() -> int:
	return canvas_size.x

func get_height() -> int:
	return canvas_size.y

func is_init_state() -> bool:
	if get_layer_count() == 1:
		var image = get_layer(0).image
		return image.is_invisible() and image.get_size() == get_size()
	return false
	
#func fill_color_alg(position: Vector2i, fill_color:Color):
	## TODO & FIXME: 用compute_shader 
	#if not is_valid(position):
		#return 
	#var target_color = get_pixel(position)
	#if target_color == fill_color:
		#return
	#var modified = FloodFillOptimized.fill(_canvas_image, position, fill_color)
	#canvas_image_updated.emit()

func new_empty_image() -> Image:
	return Image.create_empty(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	
