@tool
class_name StyleBoxCircle extends StyleBox

@export var radius_offset : float = 0:
	set(value):
		radius_offset = value
		_points_dirty = true
		_redraw()
@export var color := Color.BLACK:
	set(value):
		color = value
		_redraw()
@export_range(0, 100, 1,"or_greater") var outline_width :float= 0:
	set(value):
		outline_width = value
		_points_dirty = true
		_redraw()
@export var outline_color := Color.WHITE:
	set(value):
		outline_color = value
		_colors.fill(outline_color)
		_redraw()
@export_range(3, 128, 1,"or_greater") var point_count :int= 20:
	set(value):
		point_count = value
		_points_dirty = true
		_redraw()

var _points_dirty := true
var _points := PackedVector2Array()
var _colors := PackedColorArray()
var _prev_size := Vector2.ZERO

func _create_points(center:Vector2, radius:float):
	_points.clear()
	var step = 360.0/point_count
	for i in range(point_count):
		var rad = deg_to_rad(step*i)
		_points.append(Vector2(cos(rad)*radius, sin(rad)*radius)+center)
	_points.append(_points[0])

func _draw(to_canvas_item: RID, rect: Rect2) :
	if _prev_size != rect.size:
		_prev_size = rect.size
		_points_dirty = true
	var radius = min(rect.size.x, rect.size.y)*0.5 + radius_offset
	var center = rect.get_center()
	if color.a != 0:
		RenderingServer.canvas_item_add_circle(to_canvas_item, center, radius, color, true)
	if outline_width != 0 and outline_color.a != 0:
		if _points_dirty:
			_points_dirty = false
			_create_points(center, radius)
			_colors.resize(point_count)
			_colors.fill(outline_color)
		RenderingServer.canvas_item_add_polyline(to_canvas_item, _points, _colors, outline_width, true)
		
func _redraw():
	var item = get_current_item_drawn()
	if item:
		item.queue_redraw()
	emit_changed()


	
