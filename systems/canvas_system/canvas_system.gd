class_name CanvasSystem extends Node

var cell_size :int= 10

var grid_visible := false
var cheker_size := 16

var canvas_manager : CanvasManager

func system_initialize():
	var db_system = SystemManager.db_system
	db_system.load_data_requested.connect(func():
		cell_size = db_system.get_project_setting("cell_size", 10)
		load_data(db_system.get_data("CanvasSystem", {}))
	)
	db_system.save_data_requested.connect(func():
		db_system.set_project_setting("cell_size", cell_size)
		db_system.set_data("CanvasSystem", save_data())
	)
	
	SystemManager.ui_system.model_data_mapper.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"grid_visible":
				canvas_manager.grid.grid_enabled = value
			"checker_size":
				canvas_manager.checker_board.checker_size = value * cell_size
	)

	if canvas_manager:
		canvas_manager.image_layers_canvas.bind_with_controller()
	
	SystemManager.ui_system.model_data_mapper.register_with(self, "grid_visible")
	SystemManager.ui_system.model_data_mapper.register_with(self, "cheker_size")
	
	
	
	
func save_data():
	return {
		"grid_visible":grid_visible,
		"cheker_size":cheker_size
	}

func load_data(data:Dictionary):
	grid_visible = data.get("grid_visible", false)
	cheker_size = data.get("cheker_size", 16)

func get_canvas_size():
	return SystemManager.project_system.project_controller.get_image_layers().get_size()*cell_size

func get_canvas_rect() -> Rect2:
	return Rect2(Vector2.ZERO, get_canvas_size())

func convert_cell_position(pos:Vector2) -> Vector2i:
	return Vector2i(floor(pos/cell_size))
	
func get_touch_local_position(screen_pos:Vector2) -> Vector2:
	return canvas_manager.get_global_transform_with_canvas().affine_inverse()* screen_pos
