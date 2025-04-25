class_name ImageLayers extends Resource

@export var canvas_size := Vector2i(32,32)
@export var layers :Array[ImageLayer] = []

enum BlitMode {BLIT, BLEND}

func initialize(p_canvas_size:Vector2i, color:=Color.TRANSPARENT) -> void:
	canvas_size = p_canvas_size
	layers.clear()
	if color.a != 0:
		create_layer(0, p_canvas_size)
		get_layer(0).image.fill(color)
	else:
		create_layer(0)

func is_valid_layer(index:int) -> bool:
	return 0 <= index and index < layers.size() 

func create_layer(index:int, image_size:=Vector2.ONE, visible:=true, position:=Vector2.ZERO) -> bool:
	if index < 0 or layers.size() < index : # NOTE: 这里的判定和 is_valid_layer 不一样
		return false
	var layer = ImageLayer.create_with(image_size, visible, position)
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

func get_canvas_image(index:int) -> Image:
	var layer = get_layer(index)
	if not layer:
		return 
	var image = Image.create_empty(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	image.blit_rect_mask(layer.image, layer.image, Rect2i(Vector2.ZERO, layer.image.get_size()), layer.position)
	return image
	
func is_inside_canvas(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < get_width() and pos.y < get_height()

func get_pixel(pos: Vector2i) -> Color:
	var color = Color.TRANSPARENT
	var count = get_layer_count()
	for index in count:
		var layer = layers[count -index-1]
		if not layer.visible:
			continue
		var rect = Rect2(layer.position, layer.image.get_size())
		if not rect.has_point(pos):
			continue
		var _color = layer.image.get_pixelv(pos - layer.position)
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

func blit_image(index:int, src:Image, mask:Image, src_rect: Rect2i, dst:Vector2i, mode:=BlitMode.BLIT) -> bool:
	# NOTE: 此方法会去除外围空白像素，保持图像最小化 （extend_blit_image 方法会保留外围的空白像素）
	if not is_valid_layer(index) or not src:
		return false
	var valid_src_rect := src_rect
	var rel_canvas_rect := Rect2(src_rect.position-dst, canvas_size)
	if not rel_canvas_rect.encloses(src_rect):
		valid_src_rect = src_rect.intersection(rel_canvas_rect)
	if not valid_src_rect.has_area():
		return false
	var image_layer = get_layer(index)
	var new_dst = dst + (valid_src_rect.position-src_rect.position) -image_layer.position
	var data = extend_blit_image(image_layer.image, src, mask, valid_src_rect, new_dst, mode)
	if not data:
		return false
	var used_rect :Rect2i = data.image.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		# FIXME: 为了方便我把大小为1的图片当作空图片使用，应该不会造成什么问题？
		var image_size = Vector2.ONE
		image_layer.image = Image.create_empty(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	else:
		image_layer.image = data.image.get_region(used_rect)
	image_layer.position += data.offset + used_rect.position
	return true

static func extend_blit_image(base:Image, src:Image, mask:Image, src_rect:Rect2i, dst:Vector2i, mode:=BlitMode.BLIT) -> Dictionary:
	# NOTE: mask 可以为 null, 为 null 时会调用 blit_rect 方法
	var base_rect = Rect2i(Vector2i.ZERO, base.get_size())
	var rect = Rect2i(dst, src_rect.size) .merge(base_rect)
	if not rect.has_area():
		return {}
	var image = Image.create_empty(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	image.blit_rect(base, base_rect, -rect.position)
	match mode:
		BlitMode.BLIT:
			if mask == null:
				image.blit_rect(src, src_rect, dst-rect.position)
			else:
				image.blit_rect_mask(src, mask, src_rect, dst-rect.position)
		BlitMode.BLEND:
			if mask == null:
				image.blend_rect(src, src_rect, dst-rect.position)
			else:
				image.blend_rect_mask(src, mask, src_rect, dst-rect.position)
	return {"offset": rect.position, "image":image}
