class_name ProjectSystem extends Node

signal active_project_changed
signal project_datas_changed

const files_path := r"user://projects"

var active_project_id := ""
var project_datas := []

var project_cover_size := 256
var preset_canvas_size := Vector2i(32,32)
var preset_canvas_bg_color := Color.TRANSPARENT

var project_controller := ProjectController.new()

func system_initialize():
	DirAccess.make_dir_recursive_absolute(files_path)
	
	var db_system = SystemManager.db_system
	db_system.load_data_requested.connect(func():
		project_cover_size = db_system.get_project_setting("project_cover_size", 256)
		preset_canvas_size = db_system.get_project_setting("preset_canvas_size", Vector2i(32,32))
		preset_canvas_bg_color = db_system.get_project_setting("preset_canvas_bg_color", Color.TRANSPARENT)
		load_data(db_system.get_data("ProjectSystem", {}))
		_local_data_check()
		project_datas_changed.emit()
	)
	db_system.save_data_requested.connect(func():
		if active_project_id:
			save_project_image_layers(active_project_id, project_controller.get_image_layers())
		
		db_system.set_project_setting("preset_canvas_size", preset_canvas_size)
		db_system.set_project_setting("preset_canvas_bg_color", preset_canvas_bg_color)
		db_system.set_project_setting("project_cover_size", project_cover_size)
		db_system.set_data("ProjectSystem", save_data())
	)
	
	SystemManager.ui_system.model_data_mapper.register_with(self, "preset_canvas_size")
	SystemManager.ui_system.model_data_mapper.register_with(self, "preset_canvas_bg_color")

func set_property(id:String, prop:String, value:Variant) -> bool:
	for data:Dictionary in project_datas:
		if data.id == id and data.has(prop):
			data[prop] = value
			return true
	return false

func get_property(id:String, prop:String, defualt:Variant=null) -> Variant:
	for data:Dictionary in project_datas:
		if data.id == id:
			return data.get(id, defualt)
	return 

func _create_project(id:="", name:="", file_path:="", cover_path:="") -> Dictionary:
	return {
		"id": id,
		"name": name,
		"created_at": Time.get_unix_time_from_system(),
		"updated_at": Time.get_unix_time_from_system(),
		"file_path": file_path,
		"cover_path": cover_path  # 256x256
	}

func new_project(name:="", p_canvas_size:=Vector2i(32, 32), color:=Color.TRANSPARENT) -> String:
	var id = UUID.v4()
	var file_path := files_path.path_join(id+".tres")
	var cover_path := files_path.path_join(id+".png")
	var image_layers = ImageLayers.new()
	image_layers.initialize(p_canvas_size, color)
	ResourceSaver.save(image_layers, file_path)
	var pd := _create_project(id, name, file_path, cover_path)
	project_datas.append(pd)
	project_datas_changed.emit()
	return id

func _delete_project(id:=""):
	for data:Dictionary in project_datas:
		if data.id == id:
			project_datas.erase(data)
			var file_path := files_path.path_join(id+".tres")
			var cover_path := files_path.path_join(id+".png")
			DirAccess.remove_absolute(file_path)
			DirAccess.remove_absolute(cover_path)
			return true
	return false
			
func delete_project(id:=""):
	if _delete_project(id):
		_validate_active_id()
		set_active_project.call_deferred(active_project_id, false)
		project_datas_changed.emit()
	
func get_project_data(id:String) -> Dictionary:
	for data:Dictionary in project_datas:
		if data.id == id:
			return data.duplicate(true)
	return {}
	
func set_project_data(data:Dictionary) -> bool:
	for ori_data:Dictionary in project_datas:
		if data.id == ori_data.id:
			ori_data.merge(data, true)
			return true
	return false

func set_active_project(id:String, save_prev:=true):
	var _active_image_layers = project_controller.get_image_layers()
	if save_prev and active_project_id and _active_image_layers:
		save_project_image_layers(active_project_id, _active_image_layers)
	active_project_id = id
	project_controller.action_init_with(load_project_image_layers(active_project_id))
	active_project_changed.emit()
		
func load_project_image_layers(id:String) -> ImageLayers:
	var data := get_project_data(id)
	if not data:
		return 
	if not FileAccess.file_exists(data.file_path):
		return 
	return ResourceLoader.load(data.file_path)

func save_project_image_layers(id:String, image_layers:ImageLayers):
	var data := get_project_data(id)
	if not data:
		return 
	data.updated_at = Time.get_unix_time_from_system()
	var cover = get_image_layers_cover(image_layers)
	cover.save_png(data.cover_path)
	ResourceSaver.save(image_layers, data.file_path)
	set_project_data(data)

func get_image_layers_cover(image_layers:ImageLayers):
	var cover :Image = image_layers.generate_final_image()
	return ImageUtils.shrink_image(cover, project_cover_size)

func get_project_datas() -> Array:
	return project_datas.duplicate(true)

func save_data():
	return {
		"active_project_id":active_project_id,
		"project_datas":project_datas
	}

func load_data(data:Dictionary):
	active_project_id = data.get("active_project_id", "")
	project_datas = data.get("project_datas", [])

func _validate_active_id():
	var saved_ids = project_datas.map(func(d): return d.id)
	if not project_datas:
		active_project_id = new_project("未命名")
	elif not active_project_id or active_project_id not in saved_ids:
		active_project_id = project_datas[0].id

func _local_data_check():
	# NOTE: 假设DB出现问题初始化了，依旧可以加载本地的文件
	# WARNING : 如果图像文件格式变了可能会出现问题，但是有待考究
	var local_ids := Array(DirAccess.get_files_at(files_path)) \
						.filter(func(file): return file.ends_with(".tres")) \
						.map(func(file): return file.get_basename())

	var saved_ids = project_datas.map(func(d): return d.id)
	var remove_ids := []
	for saved_id in saved_ids:
		var file_path = files_path.path_join(saved_id+".tres")
		if not FileAccess.file_exists(ProjectSettings.globalize_path(file_path)):
			remove_ids.append(saved_id)
	
	for remove_id in remove_ids:
		# NOTE: 这里删除的是本地文件已经丢失但是project_data依旧存在的数据
		_delete_project(remove_id)
	
	for local_id:String in local_ids:
		if local_id in saved_ids:
			continue
		var file_path = files_path.path_join(local_id+".tres")
		var cover_path = files_path.path_join(local_id+".png")
		var pd := _create_project(local_id, "未命名", file_path, cover_path)
		project_datas.append(pd)
	_validate_active_id()
	
	set_active_project.call_deferred(active_project_id, false)
