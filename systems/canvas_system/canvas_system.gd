class_name CanvasSystem extends Node

var cell_size :int= 10

var grid_visible := false
var cheker_size := 16

var preset_canvas_size := Vector2i(32,32)
var preset_canvas_bg_color := Color.TRANSPARENT


var canvas_data := CanvasData.new()
var canvas_manager : CanvasManager


func system_initialize():
	var db_system = SystemManager.db_system
	db_system.load_data_requested.connect(func():
		cell_size = db_system.get_project_setting("cell_size", 10)
		preset_canvas_size = db_system.get_project_setting("preset_canvas_size", Vector2i(32,32))
		preset_canvas_bg_color = db_system.get_project_setting("preset_canvas_bg_color", Color.TRANSPARENT)
		load_data(db_system.get_data("CanvasSystem", {}))
	)
	db_system.save_data_requested.connect(func():
		db_system.set_project_setting("cell_size", cell_size)
		db_system.set_project_setting("preset_canvas_size", preset_canvas_size)
		db_system.set_project_setting("preset_canvas_bg_color", preset_canvas_bg_color)
		db_system.set_data("CanvasSystem", save_data())
	)
	
	SystemManager.project_system.active_project_changed.connect(func():
		canvas_data.init_with(SystemManager.project_system.get_active_image_layers())
	)
	
	SystemManager.ui_system.model_data_mapper.register_with(self, "grid_visible")
	SystemManager.ui_system.model_data_mapper.register_with(self, "cheker_size")
	SystemManager.ui_system.model_data_mapper.register_with(self, "preset_canvas_size")
	SystemManager.ui_system.model_data_mapper.register_with(self, "preset_canvas_bg_color")
	
func save_data():
	return {
		"grid_visible":grid_visible,
		"cheker_size":cheker_size
	}

func load_data(data:Dictionary):
	grid_visible = data.get("grid_visible", false)
	cheker_size = data.get("cheker_size", 16)

func get_cell_rect() -> Rect2:
	return Rect2(Vector2.ZERO, canvas_data.get_size()*cell_size)

func convert_cell_position(pos:Vector2) -> Vector2i:
	return Vector2i(floor(pos/cell_size))
	
func get_touch_local_position(screen_pos:Vector2) -> Vector2:
	return canvas_manager.get_global_transform_with_canvas().affine_inverse()* screen_pos
