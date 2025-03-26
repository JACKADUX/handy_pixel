extends Control


enum TransformState {
	NONE,
	MOVE,
	RESIZE,
	ROTATE,
	}
var transform_state := TransformState.NONE

var area_rect = Rect2(400,400,200,200)
var rects = []
var rotatable:=false

var _any_changed = false
var _start = false
var _transform_index = 0
var _pre_rect = Rect2()
var _offset = Vector2.ZERO

var image : Image 
var texture : ImageTexture

func _ready() -> void:
	image = Image.load_from_file("res://logo.png")
	image = image.get_region(image.get_used_rect())
	set_area_rects(Rect2(100, 100, image.get_width(), image.get_height()))
	texture = ImageTexture.create_from_image(image)

func _process(delta: float) -> void:
	queue_redraw()

func get_transform_index(gpos:Vector2)->int:
	if rects:
		var pos = get_global_transform().affine_inverse()*gpos
		for i in rects.size():
			if not i: continue
			if rects[i].has_point(pos):
				return i
	return 0

func update_transform_state(gpos:Vector2):
	_transform_index = get_transform_index(gpos)
	var _prev = transform_state
	if _transform_index == 0:
		transform_state = TransformState.NONE
	elif _transform_index == 5:
		transform_state = TransformState.MOVE
	elif _transform_index <= 9:
		transform_state = TransformState.RESIZE
	elif _transform_index <= 13 and rotatable:
		transform_state = TransformState.ROTATE
	else:
		_transform_index = 0
		transform_state = TransformState.NONE
	return _prev != transform_state
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton :
		if event.is_pressed():
			_start = true
			_any_changed = false
			update_transform_state(get_global_mouse_position())
		else:
			if _any_changed and transform_state == TransformState.RESIZE:
				image.resize(area_rect.size.x, area_rect.size.y, Image.Interpolation.INTERPOLATE_NEAREST)
				texture.set_image(image)
				queue_redraw()
				
			_start = false
			_any_changed = false
			
		_pre_rect = area_rect
		var data = RectUtils.get_resize_target_and_anchor(_pre_rect, _transform_index)
		_offset =  data.target - get_global_mouse_position()
		
	elif event is InputEventMouseMotion:
		if not _start:
			return 
		match transform_state:
			TransformState.MOVE:
				_any_changed = true
				area_rect.position += event.relative
				set_area_rects(area_rect)
			TransformState.RESIZE:
				_any_changed = true
				var data = RectUtils.get_resize_target_and_anchor(_pre_rect, _transform_index, false)
				var resize_rect = RectUtils.resize_rect(_pre_rect, get_global_mouse_position()+_offset, data.target, data.anchor)
				set_area_rects(resize_rect)

func set_area_rects(rect:Rect2):
	rect.size = rect.size.max(Vector2(1,1))
	area_rect = rect
	rects = RectUtils.create_transform_rects(area_rect, 96)
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(texture, area_rect, false)
	
	var had = false
	for index in rects.size():
		var rect = rects[index]
		if not rotatable:
			if index == 10:
				return 
		
		if not rect.has_point(get_local_mouse_position()) or had:
			draw_rect(rect, Color.RED, false)
		else:
			had = true
			draw_rect(rect, Color.GREEN_YELLOW, false, 4)
	

	
	
