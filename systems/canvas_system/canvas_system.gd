class_name CanvasSystem extends Node


var grid_visible := false
var cheker_size := 16

var canvas_manager : CanvasManager

var main_canvas_data :CanvasData = preload("res://systems/canvas_system/main_canvas_data.tres")

func system_initialize():
	var db_system = SystemManager.db_system
	db_system.load_data_requested.connect(func():
		load_data(db_system.get_data("CanvasSystem", {}))
	)
	db_system.save_data_requested.connect(func():
		db_system.set_data("CanvasSystem", save_data())
	)
	
	SystemManager.ui_system.model_data_mapper.property_updated.connect(func(prop_name:String, value):
		if not canvas_manager:
			return 
		match prop_name:
			"grid_visible":
				canvas_manager.grid.grid_enabled = value
			"checker_size":
				canvas_manager.checker_board.checker_size = value * CanvasData.CELL_SIZE
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
	return main_canvas_data.get_canvas_size()

func get_canvas_rect() -> Rect2:
	return Rect2(Vector2.ZERO, get_canvas_size())

func convert_cell_position(pos:Vector2) -> Vector2i:
	return Vector2i(floor(pos/CanvasData.CELL_SIZE))
	
func get_touch_local_position(screen_pos:Vector2) -> Vector2:
	if not canvas_manager:
		return screen_pos
	return canvas_manager.get_global_transform_with_canvas().affine_inverse()* screen_pos

func get_canvas_pos_floor(screen_pos:Vector2) -> Vector2:
	return get_canvas_pos(screen_pos).floor()

func get_canvas_pos_round(screen_pos:Vector2) -> Vector2:
	return get_canvas_pos(screen_pos).round()

func get_canvas_pos(screen_pos:Vector2) -> Vector2:
	return get_touch_local_position(screen_pos)/CanvasData.CELL_SIZE
