class_name CanvasData

signal initialized
signal layer_changed
signal canvas_image_updated
signal data_changed

# 画布数据
var _image_layers := ImageLayers.new()
var _canvas_image : Image
var _texture: ImageTexture
var _active_layer_index :int = 0

func init_with(image_layers:ImageLayers):
	if not image_layers:
		return 
	_image_layers = image_layers
	set_active_layer(0)
	initialized.emit()
	
func set_active_layer(index:int=0):
	_active_layer_index = 0
	_canvas_image = _image_layers.create_canvas_image(_active_layer_index)
	_texture = ImageTexture.create_from_image(_canvas_image)
	canvas_image_updated.emit()

func new_layer():
	var image = _image_layers.new_layer_image()
	layer_changed.emit()
	
func get_texture() -> ImageTexture:
	return _texture
	
func get_canvas_image() -> Image:
	return _canvas_image


# 设置像素颜色
func set_pixel(pos: Vector2, color: Color) -> void:
	if not is_valid(pos):
		return 
	_canvas_image.set_pixelv(pos, color)
	_texture.update(_canvas_image)
	canvas_image_updated.emit()

func bilt_image(image:Image, mask: Image, dst: Vector2i):
	var rect = Rect2(Vector2.ZERO, image.get_size())
	_canvas_image.blit_rect_mask(image, mask, rect, dst)
	_texture.update(_canvas_image)
	canvas_image_updated.emit()
	
func is_valid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < get_width() and pos.y < get_height()

func get_pixel(pos: Vector2i) -> Color:
	return _canvas_image.get_pixelv(pos)

func get_size() -> Vector2i:
	return _canvas_image.get_size()

func get_width() -> int:
	return _canvas_image.get_width()

func get_height() -> int:
	return _canvas_image.get_height()

func fill_color_alg(position: Vector2i, fill_color:Color):
	# TODO & FIXME: 用compute_shader 
	if not is_valid(position):
		return 
	var target_color = get_pixel(position)
	if target_color == fill_color:
		return
	var modified = FloodFillOptimized.fill(_canvas_image, position, fill_color)
	_texture.update(_canvas_image)
	canvas_image_updated.emit()
	
