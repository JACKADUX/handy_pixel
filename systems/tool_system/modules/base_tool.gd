class_name BaseTool

signal property_updated(prop_name:String, value:Variant)

var _tool_system: ToolSystem

var project_controller:ProjectController:
	get(): return _tool_system.get_project_controller()
var undoredo_system:UndoRedoSystem:
	get(): return _tool_system.get_undoredo_system()

var main_canvas_data:CanvasData:
	get(): return _tool_system.get_main_canvas_data()

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

func update_all():
	var data = get_tool_data()
	for prop_name in data:
		property_updated.emit(prop_name, data[prop_name]) 

func get_layout_area_type() -> LayoutHelper.AreaTypeLR:
	#return LayoutHelper.AreaTypeLR.LEFT
	var tool_ui_control := _tool_system.get_tool_ui_control()
	var input_data = SystemManager.input_system.input_recognizer.input_datas.get_input_data(0)
	var pos = input_data.start_position
	return LayoutHelper.get_point_type_lr(pos, tool_ui_control.get_viewport_rect())

func show_action_button_panel(value:bool):
	var tool_ui_control := _tool_system.get_tool_ui_control()
	var action_button_panel = tool_ui_control.action_button_panel
	var ui = tool_ui_control.owner
	ui.set_main_panel_visible(not value)
	
	if value:
		var action_button_datas = _get_action_button_datas()
		var area_type = get_layout_area_type()
		if area_type == LayoutHelper.AreaTypeLR.LEFT:
			action_button_panel.set_mode(2)
		elif area_type == LayoutHelper.AreaTypeLR.RIGHT:
			action_button_panel.set_mode(1)
		action_button_panel.setup_action_buttons(action_button_datas)
		action_button_panel.show()
	else:
		action_button_panel.hide()

## MainOverrides ---------------------------------------------------------------------------------
## 工具名称
static func get_tool_name() -> String:
	return ""

## 行为注册，方便在ui调用
func register_action(action_handler:ActionHandler):
	# action_handler.register_action(PencilTool.ACTION_DRAW_COLOR)
	pass

## ComputeShader注册, 非必要的工具可跳过
func register_shader(compute_shader_system:ComputeShaderSystem):
	# compute_shader_system.register_compute_shader_object("flood_fill", flood_fill)
	pass

## 工具初始化， 新建项目时自动调用
func initialize() -> void:
	pass

## 保存工具数据
func get_tool_data() -> Dictionary:
	# NOTE： 用于保存的数据
	return {}

## 工具激活时调用
func activate() -> void:
	#_pen_shape_cursor = PenShapeCursor.new()
	#add_indicator(_pen_shape_cursor)
	pass

## 工具禁用时调用
func deactivate() -> void:
	# remove_indicator(_pen_shape_cursor)
	pass

## 使用工具时的功能按钮
func _get_action_button_datas() -> Array:
	#return [
		#ActionButtonPanel.create_action_button_data(0, ToolSystem.ACTION_TOOL_MAIN_PRESSED, icon),
	#]
	return []

## 针对特定属性修改的效果可以发生在这里
func _handle_value_changed(prop_name:String, value:Variant):
	#match prop_name:
		#"pen_shape":
			#pass
	pass

func _on_event_occurred(event:String, data:Dictionary):
	#match event:
		#InputRecognizer.EVENT_STATE_CHANGED:
			#if data.state == InputRecognizer.State.NONE:
				#show_action_button_panel(false)
			#elif data.state == InputRecognizer.State.HOVER:
				#show_action_button_panel(true)
	pass

func _on_action_called(action:String, state:ActionHandler.State):
	#match state:
		#ActionHandler.State.JUST_RELEASED:
			#match action:
				#ToolSystem.ACTION_TOOL_MAIN_PRESSED:
					#pass
	pass
