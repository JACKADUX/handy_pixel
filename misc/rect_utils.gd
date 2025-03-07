class_name RectUtils

#---------------------------------------------------------------------------------------------------
static func get_rect_from(p1:Vector2,p2:Vector2):
	var start = Vector2(min(p1.x, p2.x), min(p1.y, p2.y))
	var end = Vector2(max(p1.x, p2.x), max(p1.y, p2.y))
	return Rect2(start, end-start)

#---------------------------------------------------------------------------------------------------
static func create_points_from_rect(value:Rect2, trans:=Transform2D()) -> PackedVector2Array:
	var points :PackedVector2Array = []
	points.append(value.position)
	points.append(Vector2(value.end.x, value.position.y))
	points.append(value.end)
	points.append(Vector2(value.position.x, value.end.y))
	points.append(points[0])
	return trans*points

#---------------------------------------------------------------------------------------------------
static func create_rect_from_points(points:PackedVector2Array, trans:=Transform2D()) -> Rect2:
	# points 默认是在全局坐标上的点，自动转换为 trans坐标下的点
	# 并返回出包含所有点的最小Rect
	if not points:
		return Rect2()
	var x_min = INF
	var y_min = INF
	var x_max = -INF
	var y_max = -INF
	points = trans.affine_inverse()*points
	for p in points:
		x_min = min(x_min, p.x)
		y_min = min(y_min, p.y)
		x_max = max(x_max, p.x)
		y_max = max(y_max, p.y)
	return get_rect_from(Vector2(x_min, y_min), Vector2(x_max, y_max))


#---------------------------------------------------------------------------------------------------

static func get_resize_target_and_anchor(rect:Rect2, transform_index:int, keep_anchor_center:= false) -> Dictionary:
	var start = rect.position
	var w = rect.size.x
	var h = rect.size.y
	var anchor_fn = func(offset):
		return start + Vector2(w*offset.x, h*offset.y)
	var target_offset:Vector2
	var anchor_offset:Vector2
	match transform_index:
		1:
			target_offset = Vector2(0, 0)
			anchor_offset = Vector2(1, 1)
		2:
			target_offset = Vector2(0.5, 0)
			anchor_offset = Vector2(0.5, 1)
		3:
			target_offset = Vector2(1, 0)
			anchor_offset = Vector2(0, 1)
		4:
			target_offset = Vector2(0, 0.5)
			anchor_offset = Vector2(1, 0.5)
		6:
			target_offset = Vector2(1, 0.5)
			anchor_offset = Vector2(0, 0.5)
		7:
			target_offset = Vector2(0, 1)
			anchor_offset = Vector2(1, 0)
		8:
			target_offset = Vector2(0.5, 1)
			anchor_offset = Vector2(0.5, 0)
		9:
			target_offset = Vector2(1, 1)
			anchor_offset = Vector2(0, 0)
	
	if keep_anchor_center:
		anchor_offset = Vector2(0.5, 0.5)
	
	var target = anchor_fn.call(target_offset)
	var anchor = anchor_fn.call(anchor_offset)
	return {"target":target, "anchor":anchor}

static func get_resize_scale(point:Vector2, target:Vector2, anchor:Vector2, keep_ratio:=false)  -> Vector2 :
	# point -> 终点  target -> 目标点  anchor -> 锚点
	var v1 = point-target
	var v2 = target-anchor
	var scale:Vector2
	if keep_ratio:
		var x = v1.dot(v2.normalized())/v2.length()
		scale = Vector2.ONE * x 
	else:
		var x = 0 if v2.x == 0 else v1.x/v2.x
		var y = 0 if v2.y == 0 else v1.y/v2.y
		scale = Vector2(x, y)
	return Vector2.ONE+ scale

static func resize_rect(rect:Rect2, point:Vector2, target:Vector2, anchor:Vector2, keep_ratio:=false)  -> Rect2 :
	# local points :  point -> 终点  target -> 目标点  anchor -> 锚点
	var start = rect.position
	var end = rect.end
	var v1 = point-target
	var v2 = target-anchor
	var scale:Vector2
	if keep_ratio:
		var x = v1.dot(v2.normalized())/v2.length()
		scale = Vector2.ONE * x 
	else:
		var x = 0 if v2.x == 0 else v1.x/v2.x
		var y = 0 if v2.y == 0 else v1.y/v2.y
		scale = Vector2(x, y)
		
	scale = Vector2.ONE+ scale
	start = anchor+(start-anchor)*scale
	end = anchor+(end-anchor)*scale
	
	start.x = min(start.x, anchor.x)
	start.y = min(start.y, anchor.y)
	end.x = max(end.x, anchor.x)
	end.y = max(end.y, anchor.y)
	return Rect2(start, end -start)
