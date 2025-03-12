class_name PencilTool extends CursorTool

const ACTION_DRAW_COLOR := "action_draw_color"

# 画笔属性
enum PenShape { CIRCLE, SQUARE }

var pen_shape := PenShape.CIRCLE 
var pen_size :int = 1

var _alpha_image_dirty := true
var _alpha_image: Image
var _alpha_map_dirty := true
var _alpha_map:= BitMap.new()
var _outline_dirty := true
var _outline : PackedVector2Array


var _pen_shape_cursor :PenShapeCursor

var _color_image_color :Color
var _color_image = Image.new()
var _cache_cell_pos := Vector2i(INF,INF)


## OVERRIDE ---------------------------------------------------------------------------------------- 
static func get_tool_name() -> String:
	return "pencil"

# 工具激活时调用
func activate() -> void:
	super()
	_pen_shape_cursor = PenShapeCursor.new()
	canvas_manager.add_child(_pen_shape_cursor)
	_pen_shape_cursor.init_with_tool(self)
	
	_color_image = get_alpha_image().duplicate()
	_color_image.fill(SystemManager.color_system.active_color)
	
# 工具禁用时调用
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
		_update_alpha_image()
	var active_color = SystemManager.color_system.active_color
	match prop_name:
		"pen_size":
			_color_image = get_alpha_image().duplicate()
			_color_image.fill(active_color)
		"pen_shape":
			_color_image = get_alpha_image().duplicate()
			_color_image.fill(active_color)
		
	super(prop_name, value)


		
func _on_action_just_pressed(action:String):
	_cache_cell_pos = Vector2i(INF,INF)
	SystemManager.project_system.project_controller.action_blit_image_start()
	
func _on_action_just_released(action:String):
	SystemManager.project_system.project_controller.action_blit_image_end()
	
func _on_action_pressed(action:String):
	var active_color = SystemManager.color_system.active_color
	match action:
		ToolSystem.ACTION_TOOL_MAIN_PRESSED:
			action_draw(active_color)
		ToolSystem.ACTION_TOOL_CANCEL_PRESSED:
			action_draw(Color.TRANSPARENT)
		PencilTool.ACTION_DRAW_COLOR:
			action_draw(active_color)
		EraserTool.ACTION_ERASE_COLOR:
			action_draw(Color.TRANSPARENT)
		ToolSystem.ACTION_PICK_COLOR:
			#project_setting.set_value("active_color", canvas_data.get_pixel(cell_pos))
			pass
		ToolSystem.ACTION_FILL_COLOR:
			pass
			#canvas_data.fill_color_alg(cell_pos_floor, active_color)


func action_draw(color:Color):
	var cell_pos = get_draw_cell_pos(cell_pos_round, cell_pos_floor)
	if _cache_cell_pos == cell_pos:
		return 
	_cache_cell_pos = cell_pos
	var alpha_image :Image = get_alpha_image()
	if _color_image_color != color:
		_color_image_color = color
		_color_image.fill(color)
	SystemManager.project_system.project_controller.action_blit_image(_color_image, alpha_image, cell_pos)


## Utils -------------------------------------------------------------------------------------------- 

func _update_alpha_image():
	_alpha_image_dirty = true 
	_alpha_map_dirty = true
	_outline_dirty = true
	
func get_alpha_image() -> Image:
	if _alpha_image_dirty:
		_alpha_image_dirty = false
		_alpha_image = generate_alpha_image(pen_size, pen_shape)
	return _alpha_image
	
func get_alpha_map() -> BitMap:
	if _alpha_map_dirty:
		_alpha_map_dirty = false
		_alpha_map.create_from_image_alpha(get_alpha_image(), 0.5)
	return _alpha_map

func get_outline() -> PackedVector2Array:
	if _outline_dirty:
		_outline_dirty = false
		var temp_alpha_map = get_alpha_map()
		_outline = temp_alpha_map.opaque_to_polygons(Rect2(Vector2(), temp_alpha_map.get_size()), 0.01)[0]
		_outline.append(_outline[0])
	return _outline


func is_even() -> bool:
	return pen_size % 2 == 0

func get_draw_cell_pos(cell_pos_round:Vector2i, cell_pos_floor:Vector2i) -> Vector2i:
	# NOTE: 根据像素的奇偶做一个偏移， 输入的参数是中心位置，返回的是左上角的位置
	var cell_pos = cell_pos_round if is_even() else cell_pos_floor
	var ofs = Vector2.ONE*pen_size*0.5
	return cell_pos-Vector2i(ofs)


func _debug():
	for y in _alpha_map.get_size().y:
		for x in _alpha_map.get_size().x:
			print(_alpha_map.get_bit(x, y))



# 生成笔刷形状的坐标偏移
static func generate_alpha_image(size: int, shape: PenShape) -> Image:
	match shape:
		PenShape.SQUARE:
			var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
			image.fill(Color.WHITE)
			return image
		PenShape.CIRCLE:
			return generate_circle_brush_image(size)
	return 

static func generate_circle_brush_image(diameter: int, shrink:float= 1) -> Image:
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

static func generate_circle_brush(diameter: int, shrink:float= 1) -> PackedVector2Array:
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

static func generate_circle_brush_outline(radius: int) -> PackedVector2Array:
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
