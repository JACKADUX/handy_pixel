class_name CameraTool extends BaseTool

const ACTION_CENTER_VIEW := "action_center_view"

var follow_cursor := false
var camera_offset := Vector2.ZERO
var camera_zoom :float= 1

var _camera : CanvasCamera
var _offset_zoom := []


static func get_tool_name() -> String:
	return "camera"

# 工具激活时调用
func activate() -> void:
	if _camera:
		return 
	_camera = CanvasCamera.new()
	canvas_manager.add_child(_camera)
	_camera.init_with_tool(self)

# 工具禁用时调用
func deactivate() -> void:
	if not _camera:
		return 
	canvas_manager.remove_child(_camera)
	_camera.queue_free()

func get_tool_data() -> Dictionary:
	return {
		"follow_cursor":follow_cursor,
		"camera_offset":camera_offset,
		"camera_zoom":camera_zoom,
	}
	
func _on_action_just_pressed(action:String):
	match action:
		ACTION_CENTER_VIEW:
			center_view()

func _on_paned(relative:Vector2):
	set_value("camera_offset",  camera_offset -relative/camera_zoom)

func _on_zoomed(center:Vector2, factor:float):
	handle_zoom(SystemManager.canvas_system.get_touch_local_position(center), factor)

func center_view():
	var viewport_size = SystemManager.canvas_system.canvas_manager.subviewport_container.size
	var canvas_size = SystemManager.canvas_system.get_canvas_size()
	_center_view(canvas_size, viewport_size)

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
