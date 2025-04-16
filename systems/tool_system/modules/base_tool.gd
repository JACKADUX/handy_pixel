class_name BaseTool

signal property_updated(prop_name:String, value:Variant)

var _tool_system: ToolSystem

var project_controller:ProjectController:
	get(): return _tool_system.get_project_controller()
var undoredo_system:UndoRedoSystem:
	get(): return _tool_system.get_undoredo_system()

static func get_tool_name() -> String:
	return ""

	
## 工具激活时调用
func activate() -> void:
	pass

## 工具禁用时调用
func deactivate() -> void:
	pass
	
## 保存工具数据
func get_tool_data() -> Dictionary:
	return {}

func set_tool_data(data:Dictionary):
	for key in data:
		set_value(key, data[key])

func set_value(prop_name:String, value:Variant):
	if get(prop_name) == value:
		return 
	set(prop_name, value)
	_handle_value_changed(prop_name, value)
	property_updated.emit(prop_name, value) 

func get_value(prop_name:String) -> Variant:
	return get(prop_name)

func add_indicator(indocator:Node):
	var canvas_manager :CanvasManager = _tool_system.get_canvas_manager()
	if not canvas_manager:
		return 
	canvas_manager.add_child(indocator)
	indocator.init_with_tool(self)
	
func remove_indicator(indocator:Node):
	if not indocator:
		return 
	var canvas_manager :CanvasManager = _tool_system.get_canvas_manager()
	if not canvas_manager:
		return 
	canvas_manager.remove_child(indocator)
	indocator.queue_free()

## 针对特定属性修改的效果可以发生在这里
func _handle_value_changed(prop_name:String, value:Variant):
	pass

func _on_event_occurred(event:String, data:Dictionary):
	pass

func _on_action_called(action:String, state:ActionHandler.State):
	pass

func request_action_button(value:bool):
	_tool_system.request_action_button(get_tool_name(), value)

func update_all():
	var data = get_tool_data()
	for prop_name in data:
		property_updated.emit(prop_name, data[prop_name]) 
