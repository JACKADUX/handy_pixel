class_name CanvasSystem extends Node


var grid_visible := false
# settings
var checkerboard_size := 16
var grid_size := 16
var grid_color := Color("8c8c8c")
var background_color := Color("faf4e6")
#
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
	
	db_system.settings_changed.connect(func():
		checkerboard_size = db_system.get_setting_value("checkerboard_size", 16)
		grid_size = db_system.get_setting_value("grid_size", 16)
		grid_color = db_system.get_setting_value("grid_color", Color("8c8c8c"))
		background_color = db_system.get_setting_value("background_color", Color("faf4e6"))
		update_settings()
	)
	
	SystemManager.ui_system.model_data_mapper.property_updated.connect(func(prop_name:String, value):
		if not canvas_manager:
			return 
		match prop_name:
			"grid_visible":
				canvas_manager.grid.grid_enabled = value
	)
	if canvas_manager:
		canvas_manager.image_layers_canvas.bind_with_controller()
		
	SystemManager.ui_system.model_data_mapper.register_with(self, "grid_visible")
	
	
func update_settings():
	canvas_manager.checker_board.checker_size = checkerboard_size * CanvasData.CELL_SIZE
	canvas_manager.grid.grid_spacing = grid_size * CanvasData.CELL_SIZE
	canvas_manager.grid.grid_color = grid_color
	canvas_manager.bg.color = background_color
	
func save_data():
	return {
		"grid_visible":grid_visible
	}

func load_data(data:Dictionary):
	grid_visible = data.get("grid_visible", false)

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
