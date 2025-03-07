class_name DBSystem extends Node

signal save_data_requested
signal load_data_requested

const db_path := "user://db.tres"
var db := HandyPixelDB.new()

func set_project_setting(key:String, value:Variant):
	db.project_settings[key] = value

func get_project_setting(key:String, default:Variant=null):
	return db.project_settings.get(key, default)

func get_data(key:String, default:Variant=null) -> Variant:
	return db.datas.get(key, default)

func set_data(key:String, Value:Variant):
	db.datas.set(key, Value)

func save_data():
	save_data_requested.emit()
	ResourceSaver.save(db, db_path)
	
func load_data():
	if FileAccess.file_exists(db_path):
		db = ResourceLoader.load(db_path, "HandyPixelDB")
	load_data_requested.emit()
