class_name CameraTool extends BaseTool

const ACTION_CENTER_VIEW := "action_center_view"

var follow_cursor := false
var camera_offset := Vector2.ZERO
var camera_zoom :float= 1

var _camera : CanvasCamera
var _offset_zoom := []
var zoom_limit_min_aspect :float = 0.5 # NOTE:这个不是 camera_zoom, 而是画布与窗口的比值
var zoom_limit_max_value :float = 100  # NOTE: 这个就是 camera_zoom 的值

static func get_tool_name() -> String:
	return "camera"

func register_action(action_handler:ActionHandler):
	action_handler.register_action(ACTION_CENTER_VIEW)

func initialize():
	center_view(true)

# 工具激活时调用
func activate() -> void:
	_camera = CanvasCamera.new()
	add_indicator(_camera)

# 工具禁用时调用
func deactivate() -> void:
	remove_indicator(_camera)
	

func get_tool_data() -> Dictionary:
	return {
		"follow_cursor":follow_cursor,
		"camera_offset":camera_offset,
		"camera_zoom":camera_zoom,
	}

func _handle_value_changed(prop_name:String, value:Variant):
	match prop_name:
		"camera_offset":
			main_canvas_data.camera_offset = value
		"camera_zoom":
			main_canvas_data.camera_zoom = value
			
func _on_action_called(action:String, state:ActionHandler.State):
	match action:
		ACTION_CENTER_VIEW:
			if state == ActionHandler.State.JUST_PRESSED:
				center_view()

func _on_event_occurred(event:String, data:Dictionary):
	match event:
		InputRecognizer.EVENT_PANED:
			var offset = camera_offset -data.relative/camera_zoom
			offset = _offset_limit(offset)
			set_value("camera_offset", offset)
		InputRecognizer.EVENT_ZOOMED:
			if _zoom_limit(data.factor):
				return 
			handle_zoom(SystemManager.canvas_system.get_touch_local_position(data.center), data.factor)

func _offset_limit(offset:Vector2):
	# NOTE: 简单来说就是画布和视图的交集矩形最小边的长度要大于100px
	var zoomed_offset = offset*camera_zoom
	var viewport_size = main_canvas_data.viewport_size
	var canvas_size = main_canvas_data.get_zoomed_canvas_size()
	var rect1 = Rect2(Vector2.ZERO, canvas_size)
	var rect2 = Rect2(zoomed_offset-viewport_size*0.5, viewport_size)

	var rect1_center = rect1.get_center() 
	var points1 = RectUtils.create_points_from_rect(rect1)
	var points2 = RectUtils.create_points_from_rect(rect2)
	var polyline = PackedVector2Array([rect1_center, zoomed_offset])
	var intersect1 = Geometry2D.intersect_polyline_with_polygon(polyline, points1)
	var intersect2 = Geometry2D.intersect_polyline_with_polygon(polyline, points2)
	if intersect1 and intersect2:
		var p1 = intersect1[0][1]
		var p2 = intersect2[0][0]
		
		var v21 = p2-p1
		var v_off = zoomed_offset-rect1_center
		if v21.dot(v_off) > 0:
			var dir = Vector2.ZERO
			zoomed_offset -= v21 + v21.normalized()*100
		return zoomed_offset/camera_zoom
	return offset


func _zoom_limit(factor:float):
	var viewport_size = main_canvas_data.viewport_size
	var canvas_size = main_canvas_data.get_zoomed_canvas_size()
	var aspect = 1
	if viewport_size.aspect() > canvas_size.aspect():
		aspect = canvas_size.y/viewport_size.y
	else:
		aspect = canvas_size.x/viewport_size.x
	if (aspect < zoom_limit_min_aspect and factor < 1) or (camera_zoom* CanvasData.CELL_SIZE >= zoom_limit_max_value and factor > 1):
		return true
		
func center_view(no_toggle:=false):
	if no_toggle:
		_offset_zoom = []
	_center_view(main_canvas_data.get_canvas_size(), main_canvas_data.viewport_size)

func _center_view(canvas_size:Vector2, viewport_size:Vector2):
	var offset = canvas_size*0.5
	var percent = 1
	if viewport_size.aspect() > canvas_size.aspect():
		percent = canvas_size.y/ viewport_size.y
	else:
		percent = canvas_size.x/ viewport_size.x
	var zoom = 1/(percent*1.1)
	
	if not _offset_zoom or not camera_offset.is_equal_approx(offset) or zoom != camera_zoom:
		_offset_zoom = [camera_offset, camera_zoom]
		set_value("camera_offset", offset)
		set_value("camera_zoom", zoom)
	else:
		set_value("camera_offset", _offset_zoom[0])
		set_value("camera_zoom", _offset_zoom[1])

func handle_zoom(center:Vector2, factor:float):
	if follow_cursor:
		set_value("camera_zoom", camera_zoom* factor)
	else:
		var offset = camera_offset
		var zoom = camera_zoom
		var diff = (center-offset)*factor
		zoom *= factor
		set_value("camera_zoom", zoom)
		offset -= (center-offset)-diff
		set_value("camera_offset", offset)
