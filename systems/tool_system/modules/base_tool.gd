class_name BaseTool

signal property_updated(prop_name:String, value:Variant)
signal data_changed

var _tool_system: ToolSystem

var canvas_manager :CanvasManager:
	get(): return _tool_system.get_canvas_manager()
var zoom : float:
	get(): return _tool_system.get_canvas_zoom()

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

## 针对特定属性修改的效果可以发生在这里
func _handle_value_changed(prop_name:String, value:Variant):
	pass
	
func _on_double_clicked(pos:Vector2):
	pass
			
func _on_hovered(relative:Vector2):
	pass

func _on_paned(relative:Vector2):
	pass

func _on_zoomed(center:Vector2, factor:float):
	pass

func _on_pressed(input_data:InputRecognizer.InputData):
	pass
	
func _on_draged(input_data:InputRecognizer.InputData):
	pass
	
func _on_action_just_pressed(action:String):
	pass
	
func _on_action_pressed(action:String):
	pass
	
func _on_action_just_released(action:String):
	pass

func _on_state_changed(state:InputRecognizer.State):
	pass

func request_action_button(value:bool):
	_tool_system.request_action_button(get_tool_name(), value)
