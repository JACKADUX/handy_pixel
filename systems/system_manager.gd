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
	await get_tree().root.ready
	for system in get_children():
		if system.has_method("system_initialize"):
			system.system_initialize()
	_initialized = true
	system_initialized.emit()
	db_system.load_data()
	
func _notification(what):
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		quit_request()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_request()

func is_initialized() -> bool:
	return _initialized

func quit_request():
	db_system.save_data()
	get_tree().quit()
