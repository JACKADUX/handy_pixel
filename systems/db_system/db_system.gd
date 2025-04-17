class_name DBSystem extends Node

signal save_data_requested
signal load_data_requested

const db_path := "user://db.tres"
var db := HandyPixelDB.new()

var auto_save_time = 120 # s

func _ready() -> void:
	var timer = Timer.new()
	add_child(timer)
	timer.autostart = true
	timer.wait_time = auto_save_time
	
	timer.timeout.connect(func():
		print("auto_saved")
		db_save()
	)
	
	save_data_requested.connect(func():
		set_data("DBSystem", save_data())
		set_project_setting("auto_save_time", auto_save_time)
	)
	load_data_requested.connect(func():
		load_data(get_data("DBSystem", {}))
		auto_save_time = get_project_setting("auto_save_time")
	)
	
func set_project_setting(key:String, value:Variant):
	db.project_settings[key] = value

func get_project_setting(key:String, default:Variant=null):
	return db.project_settings.get(key, default)

func get_data(key:String, default:Variant=null) -> Variant:
	return db.datas.get(key, default)

func set_data(key:String, Value:Variant):
	db.datas.set(key, Value)

func save_data() -> Dictionary:
	return {}
	
func load_data(data:Dictionary):
	pass

func db_save():
	save_data_requested.emit()
	ResourceSaver.save(db, db_path)
	
func db_load():
	if FileAccess.file_exists(db_path):
		db = ResourceLoader.load(db_path, "HandyPixelDB")
	load_data_requested.emit()
