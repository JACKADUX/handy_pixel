extends Node

var tooltip_dlg 
var camera_tool

var _prev = false
var _pv = []
var duration = 2

func _ready() -> void:
	tooltip_dlg = get_parent()
	if not SystemManager.is_initialized():
		await SystemManager.system_initialized
	camera_tool = SystemManager.tool_system.camera_tool
	camera_tool.property_updated.connect(func(prop, value):
		match prop:
			"camera_zoom", "camera_offset":
				_update()
				if tooltip_dlg.modulate.a != 0:
					return
				_prev = true
				var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
				tween.tween_method(func(v):
					tooltip_dlg.modulate.a = v
					, 0., 1., 0.1
				)
	)
	tooltip_dlg.modulate.a = 0
	tooltip_dlg.show()
	
func _process(delta: float) -> void:
	if Engine.get_process_frames() % 60*duration == 0 and _prev:
		if _pv != [camera_tool.camera_zoom, camera_tool.camera_offset]:
			_pv = [camera_tool.camera_zoom, camera_tool.camera_offset]
			return 
		tooltip_dlg.modulate.a = 0
		_prev = false

func _update():
	var tooltip = "s:%d%% | x:%d | y:%d"%[int(camera_tool.camera_zoom*100), int(camera_tool.camera_offset.x/CanvasData.CELL_SIZE), int(camera_tool.camera_offset.y/CanvasData.CELL_SIZE)]
	tooltip_dlg.set_tooltip("", tooltip)
	
