class_name ImageMask

# NOTE: 会和 image_layers 的 canvas 尺寸一致，蒙版区域为白色，非蒙版区域为空
enum MaskType {NEW, ADD, SUBTRACT, INTERSECT}
var _image : Image
var _mask_size :Vector2

func clear():
	_image = null

func set_mask_size(value:Vector2):
	_mask_size = value

func get_mask() -> Image:
	return _image.duplicate() if _image else null

func get_region_mask(rect:Rect2i) -> Image:
	if not _image: return 
	return _image.get_region(rect)

func get_used_rect() -> Rect2:
	if not _image: return Rect2()
	return _image.get_used_rect() 

func has_mask() -> bool:
	return _image and not _image.is_invisible() and not _image.is_empty()

func set_mask(image:Image):
	_image = image

func update_mask_with(rect:Rect2, mask_type:=MaskType.NEW):
	if not _image:
		_image = Image.create_empty(_mask_size.x, _mask_size.y, false, Image.FORMAT_RGBA8)
	match mask_type:
		MaskType.NEW:
			_image.fill(Color.TRANSPARENT)
			_image.fill_rect(rect, Color.WHITE)
		MaskType.ADD:
			_image.fill_rect(rect, Color.WHITE)
		MaskType.SUBTRACT:
			_image.fill_rect(rect, Color.TRANSPARENT)
		MaskType.INTERSECT:
			var region_image = _image.get_region(rect)
			_image.fill(Color.TRANSPARENT)
			_image.blit_rect(region_image, Rect2(Vector2.ZERO, region_image.get_size()), rect.position)

func intersect_mask(src:Image, mask:Image, src_rect:Rect2, dst:Vector2) -> Image:
	if not src or not has_mask():
		return mask
	var mask_size = src.get_size()
	if not mask:
		# NOTE: 返回的 mask 尺寸必须要和原图一致
		return get_region_mask(Rect2(dst-src_rect.position, mask_size))
	var other_mask = get_region_mask(Rect2(dst-src_rect.position, mask_size))
	var output_image = mask.duplicate() as Image
	output_image.fill(Color.TRANSPARENT)
	output_image.blit_rect_mask(mask, other_mask, Rect2i(Vector2i.ZERO, mask_size), Vector2.ZERO)
	return output_image
