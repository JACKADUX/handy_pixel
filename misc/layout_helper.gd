class_name LayoutHelper 

enum AreaTypeLR { NONE, LEFT, RIGHT, BOTH}
enum AreaTypeTB { NONE, TOP, BOTTOM, BOTH}

static func get_point_type_lr(point:Vector2, area:Rect2) -> AreaTypeLR:
	var mid = area.size.x*0.5
	if point.x <= mid:
		return AreaTypeLR.LEFT
	elif mid <= point.x:
		return AreaTypeLR.RIGHT
	return AreaTypeLR.NONE

static func get_point_type_tb(point:Vector2, area:Rect2) -> AreaTypeTB:
	var mid = area.size.y*0.5
	if point.y <= mid:
		return AreaTypeTB.TOP
	elif mid <= point.y:
		return AreaTypeTB.BOTTOM
	return AreaTypeTB.NONE

static func get_area_type_lr(rect:Rect2, area:Rect2) -> AreaTypeLR:
	var mid = area.size.x*0.5
	if rect.end.x <= mid:
		return AreaTypeLR.LEFT
	elif mid <= rect.position.x:
		return AreaTypeLR.RIGHT
	elif rect.position.x < mid and mid < rect.end.x:
		return AreaTypeLR.BOTH
	return AreaTypeLR.NONE

static func get_area_type_tb(rect:Rect2, area:Rect2) -> AreaTypeTB:
	var mid = area.size.y*0.5
	if rect.end.y <= mid:
		return AreaTypeTB.TOP
	elif mid <= rect.position.y:
		return AreaTypeTB.BOTTOM
	elif rect.position.y < mid and mid < rect.end.y:
		return AreaTypeTB.BOTH
	return AreaTypeTB.NONE
