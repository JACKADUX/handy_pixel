class_name DBSystem extends Node

signal save_data_requested
signal load_data_requested
signal settings_changed

const db_path := "user://db.tres"
var db := HandyPixelDB.new()


var default_settings := {
	"max_fps": {"title": "常规/最大帧率", "type": TYPE_INT, "value":60, "select":[0,30,60,120,240], "select_text":["无限制", "30", "60", "120", "240"]},
	"auto_save_time": {"title": "常规/自动保存间隔", "type": TYPE_INT, "value":120, "select":[0, 60, 120, 300], "select_text":["关闭", "1分钟", "2分钟", "5分钟"]},
	"action_button_location": {"title": "常规/功能键位置", "type": TYPE_INT, "value":0, "select":[0, 1, 2], "select_text":["自动", "左边", "右边"]}, # 0 自动 1 左边 2 右边
	
	"checkerboard_size": {"title": "画布/棋盘格尺寸", "type": TYPE_INT, "value":16, "min_value":2, "max_value":2048, "step": 1, "rounded":true},
	"grid_size": {"title": "画布/网格尺寸", "type": TYPE_INT, "value":16, "min_value":2, "max_value":2048, "step": 1, "rounded":true},
	"grid_color": {"title": "画布/网格颜色", "type": TYPE_COLOR, "value":Color("8c8c8c")},
	"background_color": {"title": "画布/背景颜色", "type": TYPE_COLOR, "value":Color("faf4e6")},
	
	"force_use_cpu": {"title": "高级/计算着色器强制使用cpu", "type": TYPE_BOOL, "value":false},
}

var settings := {}

var timer:Timer

func _enter_tree() -> void:
	timer = Timer.new()
	add_child(timer)
	
func _ready() -> void:
	timer.timeout.connect(func():
		#print("auto_saved")
		SystemManager.save_data()
	)
	
	save_data_requested.connect(func():
		set_data("DBSystem", save_data())
		db.settings = settings
	)
	
	load_data_requested.connect(func():
		load_data(get_data("DBSystem", {}))
		settings = default_settings.merged(db.settings)
		for key in db.settings:
			settings[key].value = db.settings[key].value
		raise_settings_changed()
	)
	
	settings_changed.connect(func():
		timer.wait_time = get_setting_value("auto_save_time")
		timer.start()
	)
	
func get_data(key:String, default:Variant=null) -> Variant:
	return db.datas.get(key, default)

func set_data(key:String, Value:Variant):
	db.datas.set(key, Value)
	
func save_data() -> Dictionary:
	return {}
	
func load_data(_data:Dictionary):
	pass

func db_save():
	save_data_requested.emit()
	ResourceSaver.save(db, db_path)
	
func db_load():
	if FileAccess.file_exists(db_path):
		db = ResourceLoader.load(db_path, "HandyPixelDB")
	load_data_requested.emit()	

## Setting
func new_setting(key:String, setting:Dictionary):
	settings[key] = setting

func get_setting_value(key:String, default:Variant=null) -> Variant:
	return settings.get(key, {}).get("value", default)

func set_setting_value(key:String, value:Variant):
	if not settings.has(key):
		return 
	settings[key]["value"] = value

func get_setting(key:String) -> Dictionary:
	return settings.get(key, {})

func get_settings() -> Dictionary:
	return settings.duplicate(true)

func raise_settings_changed() -> void:
	settings_changed.emit()

# Utils
func new_setting_basic(title:String, type:Variant.Type, value:Variant, config:={}) -> Dictionary:
	return {"title": title, "type":type, "value":value}.merged(config)

func new_setting_int_select(title:String, value:int, select:Array, select_text:=[]) -> Dictionary:
	return new_setting_basic(title, TYPE_INT, value, {"select":select, "select_text":select_text})

func new_setting_int_range(title:String, value:int, min_value:int=-100000000, max_value:int=100000000, step:int=1, rounded:=true) -> Dictionary:
	return new_setting_basic(title, TYPE_INT, value, {"min_value":min_value, "max_value":max_value, "step": step, "rounded":rounded})
