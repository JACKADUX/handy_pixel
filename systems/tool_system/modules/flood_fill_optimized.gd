class_name FloodFillOptimized 

# TODO: 用 compute_shader 重构

# ================== 核心算法 ==================
static func fill(image: Image, start_pos: Vector2i, new_color: Color, tolerance: float = 0.0, boundary_colors: Array[Color] = []) -> Dictionary:
	
	var original_color := image.get_pixelv(start_pos)
	if original_color == new_color:
		return {}

	var modified := {}
	var stack :Array[Vector2i]= []
	var size := image.get_size()
	
	# 初始种子点
	stack.append(start_pos)
	modified[start_pos] = original_color
	
	while not stack.is_empty():
		var pos :Vector2i = stack.pop_back()
		var x = pos.x
		var y = pos.y
		
		# 向左寻找边界
		var left = x
		while left >= 0 and _should_fill(image, Vector2i(left, y), original_color, tolerance, boundary_colors):
			left -= 1
		left += 1
		
		# 向右寻找边界
		var right = x
		while right < size.x and _should_fill(image, Vector2i(right, y), original_color, tolerance, boundary_colors):
			right += 1
		
		# 标记当前扫描线
		var in_span_above = false
		var in_span_below = false
		
		# 填充并检查上下行
		for x_fill in range(left, right):
			image.set_pixel(x_fill, y, new_color)
			modified[Vector2i(x_fill, y)] = original_color
			
			# 检查上方像素
			if y > 0:
				_check_span(
					image, Vector2i(x_fill, y - 1),
					original_color, tolerance, boundary_colors,
					stack, modified, in_span_above
				)
			
			# 检查下方像素
			if y < size.y - 1:
				_check_span(
					image, Vector2i(x_fill, y + 1),
					original_color, tolerance, boundary_colors,
					stack, modified, in_span_below
				)
	
	return modified

# ================== 辅助方法 ==================
static func _should_fill(image: Image, pos: Vector2i, target_color: Color, tolerance: float, boundaries: Array) -> bool:
	
	if pos.x < 0 or pos.y < 0 or pos.x >= image.get_width() or pos.y >= image.get_height():
		return false
	
	var current_color := image.get_pixelv(pos)
	
	# 边界颜色检测
	if boundaries.has(current_color):
		return false
	
	# 颜色容差计算
	return _color_distance_sqr(current_color, target_color) <= tolerance*tolerance

static func _check_span(
	image: Image,
	pos: Vector2i,
	target_color: Color,
	tolerance: float,
	boundaries: Array,
	stack: Array,
	modified: Dictionary,
	in_span: bool
) -> bool:
	
	if _should_fill(image, pos, target_color, tolerance, boundaries):
		if not modified.has(pos):
			if not in_span:
				stack.append(pos)
				modified[pos] = image.get_pixelv(pos)
			return true
	return false

# 颜色差异计算 (CIE94公式)
static func _color_distance_sqr(c1: Color, c2: Color) -> float:
	var dr = c1.r - c2.r
	var dg = c1.g - c2.g
	var db = c1.b - c2.b
	return dr*dr + dg*dg + db*db
