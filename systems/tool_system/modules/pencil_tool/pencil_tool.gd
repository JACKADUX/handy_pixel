class_name PencilTool extends CursorTool

const ACTION_DRAW_COLOR := "action_draw_color"

# 画笔属性
enum PenShape { CIRCLE, SQUARE }

var pen_shape := PenShape.CIRCLE 
var pen_size :int = 1


var _pen_shape_cursor :PenShapeCursor

var _pen_color :Color
var _color_image : Image
var _color_image_dirty := true
var _mask_image : Image
var _mask_image_dirty := true

var _blit_color_image : Image
var _blit_mask_image : Image
var _prev_image : Image

var _cache_pen_position := Vector2i(INF,INF)
var _draw_started := false

## OVERRIDE ---------------------------------------------------------------------------------------- 
static func get_tool_name() -> String:
	return "pencil"

## 工具激活时调用
func activate() -> void:
	super() # NOTE: cursor就会在上层
	_pen_shape_cursor = PenShapeCursor.new()
	canvas_manager.add_child(_pen_shape_cursor)
	_pen_shape_cursor.init_with_tool(self)
	_cursor.move_to_front()
	
	_pen_color = get_active_color()
	set_mask_image_dirty()

func get_active_color():
	return SystemManager.color_system.active_color

## 工具禁用时调用
func deactivate() -> void:
	super()
	canvas_manager.remove_child(_pen_shape_cursor)
	_pen_shape_cursor.queue_free()

func get_tool_data() -> Dictionary:
	return {
		"pen_shape": pen_shape,
		"pen_size": pen_size
	}

func _handle_value_changed(prop_name:String, value:Variant):
	if prop_name == "pen_shape" or prop_name == "pen_size":
		set_mask_image_dirty()	
	super(prop_name, value)

func _on_action_just_pressed(action:String):
	_cache_pen_position = Vector2i(INF,INF)
	match action:
		PencilTool.ACTION_DRAW_COLOR, ToolSystem.ACTION_TOOL_MAIN_PRESSED:
			set_pen_color(get_active_color())
			begin_draw()
		EraserTool.ACTION_ERASE_COLOR, ToolSystem.ACTION_TOOL_CANCEL_PRESSED:
			set_pen_color(Color.TRANSPARENT)
			begin_draw()
	
func _on_action_pressed(action:String):
	match action:
		PencilTool.ACTION_DRAW_COLOR, ToolSystem.ACTION_TOOL_MAIN_PRESSED:
			draw_list(get_color_image(), get_mask_image(), _generate_pen_pos_list())
		EraserTool.ACTION_ERASE_COLOR, ToolSystem.ACTION_TOOL_CANCEL_PRESSED:
			draw_list(get_color_image(), get_mask_image(), _generate_pen_pos_list())
		ToolSystem.ACTION_PICK_COLOR:
			#project_setting.set_value("active_color", canvas_data.get_pixel(cell_pos))
			pass
		ToolSystem.ACTION_FILL_COLOR:
			pass
			#canvas_data.fill_color_alg(cell_pos_floor, active_color)

func _on_action_just_released(action:String):
	match action:
		PencilTool.ACTION_DRAW_COLOR, ToolSystem.ACTION_TOOL_MAIN_PRESSED:
			end_draw()
		EraserTool.ACTION_ERASE_COLOR, ToolSystem.ACTION_TOOL_CANCEL_PRESSED:
			end_draw()

## Action -------------------------------------------------------------------------------------------- 
func begin_draw():
	_draw_started = true
	var image_layers := project_controller.get_image_layers()
	_blit_color_image = image_layers.new_empty_image()
	_blit_mask_image = image_layers.new_empty_image()
	_prev_image = image_layers.get_layer(project_controller.get_active_layer_index()).image.duplicate()

func draw(src_image:Image, mask_image:Image, dst:Vector2i): 
	_blit_color_image.blit_rect_mask(src_image, mask_image, Rect2(Vector2.ZERO, mask_image.get_size()), dst)
	_blit_mask_image.blit_rect_mask(mask_image, mask_image, Rect2(Vector2.ZERO, mask_image.get_size()), dst)
	var used_rect = _blit_mask_image.get_used_rect()
	project_controller.blit_image_mask(project_controller.get_active_layer_index(), _blit_color_image, _blit_mask_image, used_rect, used_rect.position)

func draw_list(src_image:Image, mask_image:Image, dst_list:PackedVector2Array):
	if not dst_list:
		return 
	for pen_pos in dst_list:
		_blit_color_image.blit_rect_mask(src_image, mask_image, Rect2(Vector2.ZERO, mask_image.get_size()), pen_pos)
		_blit_mask_image.blit_rect_mask(mask_image, mask_image, Rect2(Vector2.ZERO, mask_image.get_size()), pen_pos)
	var used_rect = _blit_mask_image.get_used_rect()
	project_controller.blit_image_mask(project_controller.get_active_layer_index(), _blit_color_image, _blit_mask_image, used_rect, used_rect.position)

func end_draw():
	if not _draw_started:
		return 
	_draw_started = false
	var used_rect = _blit_mask_image.get_used_rect()
	project_controller.action_blit_image_mask(project_controller.get_active_layer_index(),
		_blit_color_image.get_region(used_rect),
		_blit_mask_image.get_region(used_rect),
		Rect2(Vector2.ZERO, used_rect.size),
		used_rect.position,
		_prev_image.get_region(used_rect)
	)

## Utils -------------------------------------------------------------------------------------------- 
func _generate_pen_pos_list() -> Array[Vector2i]:
	# NOTE: 可以保证线条是连续的
	var pen_pos := get_pen_position()
	var prev_pos = _cache_pen_position if _cache_pen_position != Vector2i(INF,INF) else pen_pos
	if _cache_pen_position == pen_pos:
		return []
	_cache_pen_position = pen_pos
	var pos_list := Geometry2D.bresenham_line(prev_pos, pen_pos)
	if pos_list.size() > 2:
		# 把重复的部分去除
		pos_list.pop_front()
	return pos_list
	
func set_mask_image_dirty():
	_mask_image_dirty = true
	_color_image_dirty = true
	
func set_pen_color(color:Color):
	_pen_color = color
	if _color_image_dirty:
		get_color_image()
	_color_image.fill(_pen_color)
	
func get_mask_image() -> Image:
	if _mask_image_dirty:
		_mask_image_dirty = false
		_mask_image = generate_alpha_image(pen_size, pen_shape)
	return _mask_image

func get_color_image() -> Image:
	if _color_image_dirty:
		_color_image_dirty = false
		_color_image = get_mask_image().duplicate()
		_color_image.fill(_pen_color)
	return _color_image

func get_pen_position() -> Vector2i:
	return _get_draw_cell_pos(cell_pos_round, cell_pos_floor)

func _is_even_pen_size() -> bool:
	return pen_size % 2 == 0

func _get_draw_cell_pos(cell_pos_round:Vector2i, cell_pos_floor:Vector2i) -> Vector2i:
	# NOTE: 根据像素的奇偶做一个偏移， 输入的参数是中心位置，返回的是左上角的位置
	var cell_pos = cell_pos_round if _is_even_pen_size() else cell_pos_floor
	var ofs = Vector2.ONE*pen_size*0.5
	return cell_pos-Vector2i(ofs)


# 生成笔刷形状的坐标偏移
static func generate_alpha_image(size: int, shape: PenShape) -> Image:
	match shape:
		PenShape.SQUARE:
			var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
			image.fill(Color.WHITE)
			return image
		PenShape.CIRCLE:
			return generate_circle_pen_image(size)
	return 

static func generate_circle_pen_image(diameter: int, shrink:float= 1) -> Image:
	var image := Image.create_empty(diameter, diameter, false, Image.FORMAT_RGBA8)
	var radius = diameter*0.5
	if diameter < 10:
		shrink = 0.88  # 这个是通过测试得出来的结果比较好得常量
	else:
		shrink = 1
	var radius_sq = radius*radius*shrink
	var ofs = 0.5
	var color1 = Color.WHITE
	var color2 = Color.TRANSPARENT
	for x in diameter:
		for y in diameter:
			var dx = x-radius+ofs
			var dy = y-radius+ofs
			var dist_sq = dx*dx + dy*dy
			image.set_pixel(x, y, color1 if dist_sq <= radius_sq else color2)
	return image

static func generate_circle_pen(diameter: int, shrink:float= 1) -> PackedVector2Array:
	var points := PackedVector2Array()
	var radius = diameter*0.5
	if diameter < 10:
		shrink = 0.88  # 这个是通过测试得出来的结果比较好得常量
	else:
		shrink = 1
	var radius_sq = radius*radius*shrink
	var ofs = 0.5
	for x in diameter:
		for y in diameter:
			var dx = x-radius+ofs
			var dy = y-radius+ofs
			var dist_sq = dx*dx + dy*dy
			if dist_sq <= radius_sq:
				points.append(Vector2i(x, y))
	return points

static func generate_circle_pen_outline(radius: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var x := radius
	var y := 0
	var p := 1 - radius  # 初始决策参数
	var center = Vector2(radius,radius)
	# 初始点
	points.append_array(_get_circle_points(center, x, y))

	# Midpoint Circle Algorithm
	while x > y:
		y += 1
		
		# Mid-point 在圆内或圆上
		if p <= 0:
			p = p + 2 * y + 1
		else:
			x -= 1
			p = p + 2 * y - 2 * x + 1
		
		# 确保 x >= y
		if x < y:
			break
		
		# 添加对称点
		points.append_array(_get_circle_points(center, x, y))
		if x != y:
			points.append_array(_get_circle_points(center, y, x))

	return points

# 获取圆上对称的8个点
static func _get_circle_points(center: Vector2i, x: int, y: int) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(center.x + x, center.y + y),
		Vector2(center.x - x, center.y + y),
		Vector2(center.x + x, center.y - y),
		Vector2(center.x - x, center.y - y),
		Vector2(center.x + y, center.y + x),
		Vector2(center.x - y, center.y + x),
		Vector2(center.x + y, center.y - x),
		Vector2(center.x - y, center.y - x)
	])
