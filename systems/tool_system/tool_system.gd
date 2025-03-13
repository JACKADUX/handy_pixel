class_name ToolSystem extends Node

signal tool_registered(tool_name:String)
signal tool_changed(tool_name:String)
signal tool_property_updated(tool_name:String, prop_name:String, value:Variant)
signal action_button_requested(action_button_datas:Array, value:bool)


var cursor_speed_factor :float = 0.75 # 跟随倍率

# 当前激活的工具
var _current_tool: BaseTool = null

# 注册的工具列表
var _tools: Dictionary[String, BaseTool] = {}
var _tool_action_button_datas :Dictionary[String, Array] = {}

const ERASER_TOOL := "eraser"
const COLOR_PICKER_TOOL := "color_picker"
const FILL_COLOR_TOOL := "fill_color"

const ACTION_PICK_COLOR := "action_pick_color"
const ACTION_FILL_COLOR := "action_fill_color"
const ACTION_TOOL_MAIN_PRESSED := "action_tool_main_pressed"
const ACTION_TOOL_CONFIRM_PRESSED := "action_tool_confirm_pressed"
const ACTION_TOOL_CANCEL_PRESSED := "action_tool_cancel_pressed"


var camera_tool : CameraTool


func _register_tools() -> void:
	const main_pressed_icon = preload("res://assets/icons/point_scan_96dp_FFFFFF_FILL1_wght400_GRAD0_opsz48.svg")
	const pencil_icon = preload("res://assets/icons/stylus_96dp_FFFFFF_FILL1_wght400_GRAD0_opsz48.svg")
	const erase_icon = preload("res://assets/icons/ink_eraser_96dp_FFFFFF_FILL1_wght400_GRAD0_opsz48.svg")
	const pick_color_icon = preload("res://assets/icons/colorize_96dp_FFFFFF_FILL1_wght400_GRAD0_opsz48.svg")
	const fill_color_icon = preload("res://assets/icons/colors_96dp_FFFFFF_FILL1_wght400_GRAD0_opsz48.svg")
	const cancel_pressed_icon = preload("res://assets/icons/close_96dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.svg")
	
	const move_icon = preload("res://assets/icons/drag_pan_96dp_FFFFFF_FILL1_wght400_GRAD0_opsz48.svg")
	

	register_tool(CameraTool.new(), [])
		
	register_tool(PencilTool.new(), [
		ActionButtonPanel.create_action_button_data(0, PencilTool.ACTION_DRAW_COLOR, pencil_icon),
		ActionButtonPanel.create_action_button_data(2, ACTION_PICK_COLOR, pick_color_icon),
		ActionButtonPanel.create_action_button_data(3, ACTION_FILL_COLOR, fill_color_icon),
		ActionButtonPanel.create_action_button_data(4, EraserTool.ACTION_ERASE_COLOR, erase_icon),
	])
	register_tool(EraserTool.new())
	register_tool(SelectionTool.new(),[
		ActionButtonPanel.create_action_button_data(0, ACTION_TOOL_MAIN_PRESSED, main_pressed_icon),
		ActionButtonPanel.create_action_button_data(2, ACTION_TOOL_CANCEL_PRESSED, cancel_pressed_icon),
	])
	register_tool(TransformTool.new(),[
		ActionButtonPanel.create_action_button_data(0, ACTION_TOOL_MAIN_PRESSED, move_icon),
		#ActionButtonPanel.create_action_button_data(2, ACTION_TOOL_CANCEL_PRESSED, cancel_pressed_icon),
	])
	
func system_initialize():
	_register_tools()
	_register_input_actions()

	SystemManager.db_system.save_data_requested.connect(func():
		SystemManager.db_system.set_data("ToolSystem", save_data())
	)
	
	SystemManager.db_system.load_data_requested.connect(func():
		load_data(SystemManager.db_system.get_data("ToolSystem", {}))
	)
	
	SystemManager.ui_system.model_data_mapper.register_with(self, "cursor_speed_factor")
	
	SystemManager.project_system.project_controller.initialized.connect(func():
		camera_tool.center_view()
	)
	
	#SystemManager.ui_system.model_data_mapper.register("cell_pos_floor",)
	
	# 常驻工具
	camera_tool = get_tool(CameraTool.get_tool_name())
	camera_tool.activate()
	_connect_with_input_system(camera_tool)
	
	# 可替换工具
	var tool_name = TransformTool.get_tool_name()
	var tool = get_tool(tool_name)
	switch_tool(tool_name)

func _register_input_actions():
	var action_handler = SystemManager.input_system.action_handler
	action_handler.register_action(PencilTool.ACTION_DRAW_COLOR)
	action_handler.register_action(EraserTool.ACTION_ERASE_COLOR)
	action_handler.register_action(CameraTool.ACTION_CENTER_VIEW)
	action_handler.register_action(ACTION_TOOL_MAIN_PRESSED)
	action_handler.register_action(ACTION_TOOL_CONFIRM_PRESSED)
	action_handler.register_action(ACTION_TOOL_CANCEL_PRESSED)
	
	action_handler.register_action(ACTION_FILL_COLOR)
	action_handler.register_action(ACTION_PICK_COLOR)

func _connect_with_input_system(tool:BaseTool):
	var input_system :InputSystem = SystemManager.input_system	
	input_system.double_clicked.connect(tool._on_double_clicked)
	input_system.hovered.connect(tool._on_hovered)
	input_system.paned.connect(tool._on_paned)
	input_system.zoomed.connect(tool._on_zoomed)
	input_system.state_changed.connect(tool._on_state_changed)
	input_system.pressed.connect(tool._on_pressed)
	input_system.draged.connect(tool._on_draged)
	input_system.action_handler.action_just_pressed.connect(tool._on_action_just_pressed)
	input_system.action_handler.action_pressed.connect(tool._on_action_pressed)
	input_system.action_handler.action_just_released.connect(tool._on_action_just_released)

func _disconnect_with_input_system(tool:BaseTool):
	var input_system :InputSystem = SystemManager.input_system	
	input_system.double_clicked.disconnect(tool._on_double_clicked)
	input_system.hovered.disconnect(tool._on_hovered)
	input_system.paned.disconnect(tool._on_paned)
	input_system.zoomed.disconnect(tool._on_zoomed)
	input_system.state_changed.disconnect(tool._on_state_changed)
	input_system.pressed.disconnect(tool._on_pressed)
	input_system.draged.disconnect(tool._on_draged)
	input_system.action_handler.action_just_pressed.disconnect(tool._on_action_just_pressed)
	input_system.action_handler.action_pressed.disconnect(tool._on_action_pressed)
	input_system.action_handler.action_just_released.disconnect(tool._on_action_just_released)

func save_data() -> Dictionary:
	var data = {}
	var tool_datas = {}
	for tool_name in _tools:
		tool_datas[tool_name] = _tools[tool_name].get_tool_data()
	data["tool_datas"] = tool_datas
	data["current_tool"] = _current_tool.get_tool_name() 
	data["cursor_speed_factor"] = cursor_speed_factor
	return data
	
func load_data(data:Dictionary):
	cursor_speed_factor = data.get("cursor_speed_factor", 0.75)
	var tool_datas = data.get("tool_datas", {})
	for tool_name in tool_datas:
		_tools[tool_name].set_tool_data(tool_datas[tool_name])
	switch_tool(data.get("current_tool", PencilTool.get_tool_name()))

# 注册工具
func register_tool(tool: BaseTool, action_button_datas:=[]) -> void:
	var tool_name = tool.get_tool_name()
	if not _tools.has(tool_name):
		tool._tool_system = self
		_tools[tool_name] = tool
		_tool_action_button_datas[tool_name] = action_button_datas
		tool.property_updated.connect(func(prop_name:String, value:Variant):
			tool_property_updated.emit(tool_name, prop_name, value)
		)
		tool_registered.emit(tool_name)

func get_tool(tool_name:String) -> BaseTool:
	return _tools.get(tool_name)

func get_current_tool() -> BaseTool:
	return _current_tool

# 切换工具
func switch_tool(tool_name:String) -> void:
	if _current_tool and _current_tool.get_tool_name() == tool_name:
		return 
	if _current_tool:
		_current_tool.deactivate()  # 禁用当前工具
		_disconnect_with_input_system(_current_tool)
	_current_tool = get_tool(tool_name)
	_current_tool.activate()  # 激活新工具
	_connect_with_input_system(_current_tool)
	tool_changed.emit(tool_name)

func get_tool_action_button_datas(tool_name:String) -> Array:
	return _tool_action_button_datas.get(tool_name, [])

func request_action_button(tool_name:String, value:bool):
	action_button_requested.emit(get_tool_action_button_datas(tool_name), value)

func get_canvas_manager() -> CanvasManager:
	return SystemManager.canvas_system.canvas_manager

func get_project_controller() -> ProjectController:
	return SystemManager.project_system.project_controller

func get_undoredo_system() -> UndoRedoSystem:
	return SystemManager.undoredo_system

func get_camera_zoom() -> float:
	return camera_tool.camera_zoom if camera_tool else 1.0
