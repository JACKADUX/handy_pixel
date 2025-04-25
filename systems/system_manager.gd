# class_name SystemManager
extends Node

## 所有注册到系统的行为都可以发生在这里
signal system_initialized  

@onready var db_system: DBSystem = $DBSystem
@onready var project_system: ProjectSystem = $ProjectSystem
@onready var input_system: InputSystem = $InputSystem
@onready var tool_system: ToolSystem = $ToolSystem
@onready var canvas_system: CanvasSystem = $CanvasSystem
@onready var color_system: ColorSystem = $ColorSystem
@onready var undoredo_system: UndoRedoSystem = $UndoRedoSystem
@onready var ui_system: UISystem = $UISystem

var _initialized := false

func _ready() -> void:
	OS.request_permissions()
	if _keep_only(): 
		return
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	await get_tree().root.ready
	initialize()
	load_data()
	
func _notification(what):
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		quit_request()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_request()
	
		
func _keep_only():
	# NOTE: 打开其他测试场景时会移除
	if not get_tree().current_scene.name.to_lower().begins_with("app"):
		queue_free()
		return true
		
func is_initialized() -> bool:
	return _initialized

func initialize():
	for system in get_children():
		if system.has_method("system_initialize"):
			system.system_initialize()
	_initialized = true
	system_initialized.emit()

func quit_request():
	save_data()
	get_tree().quit()

func save_data():
	if db_system:
		db_system.db_save()

func load_data():
	db_system.db_load()
