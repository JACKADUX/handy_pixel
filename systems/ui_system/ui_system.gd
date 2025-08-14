class_name UISystem extends Node

var model_data_mapper := preload("res://systems/ui_system/ui_model_data.tres")

var projects_edit_state := false
var image_export_custom_mul :int = 1
var color_palette_mode :int = 0  # RECT / RGB/ HSV
var outline_generate_expend_size :int = 1
var outline_generate_pattern :Array = [0,1,0,1,0,1,0,1,0] 

var ui : Control

var _virtical_direction := false

func system_initialize():
	SystemManager.db_system.save_data_requested.connect(func():
		SystemManager.db_system.set_data("UISystem", save_data())
	)
	
	SystemManager.db_system.load_data_requested.connect(func():
		load_data(SystemManager.db_system.get_data("UISystem", {}))
		model_data_mapper.update_all.call_deferred()
	)
	
	SystemManager.db_system.settings_changed.connect(func():
		Engine.max_fps = SystemManager.db_system.get_setting_value("max_fps", 60)
		change_direction(bool(SystemManager.db_system.get_setting_value("screen_direction", 0)))
	)
	
	SystemManager.ui_system.model_data_mapper.register_with(self, "projects_edit_state")
	SystemManager.ui_system.model_data_mapper.register_with(self, "image_export_custom_mul")
	SystemManager.ui_system.model_data_mapper.register_with(self, "color_palette_mode")
	SystemManager.ui_system.model_data_mapper.register_with(self, "outline_generate_expend_size")
	SystemManager.ui_system.model_data_mapper.register_with(self, "outline_generate_pattern")
	
	
func save_data() -> Dictionary:
	var data = {}
	data["projects_edit_state"] = projects_edit_state
	data["image_export_custom_mul"] = image_export_custom_mul
	data["color_palette_mode"] = color_palette_mode
	data["outline_generate_expend_size"] = outline_generate_expend_size
	data["outline_generate_pattern"] = outline_generate_pattern
	return data
	
func load_data(data:Dictionary):
	projects_edit_state = data.get("projects_edit_state", false)
	image_export_custom_mul = data.get("image_export_custom_mul", false)
	color_palette_mode = data.get("color_palette_mode", 0)
	outline_generate_expend_size = data.get("outline_generate_expend_size", 1)
	outline_generate_pattern = data.get("outline_generate_pattern", outline_generate_pattern)

func get_tool_ui_control() -> ToolUIControl:
	if not ui:
		return 
	return ui.tool_ui_control

func get_temp_action_buttons_control() -> TempActionButtons:
	if not ui:
		return 
	return ui.temp_action_buttons


var ui_config_h := {
	"outside_margin" : [96, 16, 96, 16]
}
var ui_config_v := {
	"outside_margin" : [48, 96, 48, 96]
}

func is_virtical() -> bool:
	return _virtical_direction

func change_direction(virtical:=false):
	
	_virtical_direction = virtical
	var v_size = Vector2(720, 1280) if OS.has_feature("editor") else Vector2(1080, 1920)
	var h_size = Vector2(1280, 720) if OS.has_feature("editor") else Vector2(1920, 1080)
	
	if virtical:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
		DisplayServer.window_set_size(v_size)
		get_tree().root.content_scale_factor = h_size.aspect()
		ui.left_bar.alignment = BoxContainer.ALIGNMENT_CENTER
		ui.right_bar.alignment = BoxContainer.ALIGNMENT_CENTER
		
	else:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
		DisplayServer.window_set_size(h_size)
		get_tree().root.content_scale_factor = 1 # v_size.aspect()
		
		ui.left_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
		ui.right_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
		
	handle_screen_resize()
	var margin_props = ["margin_left","margin_top","margin_right","margin_bottom"]
	var config = ui_config_v if virtical else ui_config_h
	for index in margin_props.size():
		ui.main_panel.add_theme_constant_override(margin_props[index], config.outside_margin[index])
	print_info()
	
func handle_screen_resize():
	var os_name = OS.get_name()
	if os_name == "Android" or os_name == "ios":
		var screen_size = get_tree().root.size
		var safe_area = DisplayServer.get_display_safe_area()
		var safe_area_top = safe_area.position.y
		var safe_area_sides = safe_area.position.x
		if os_name == "ios":
			var screen_scale = DisplayServer.screen_get_scale()
			safe_area_top = (safe_area_top / screen_scale)
			safe_area_sides = (safe_area_sides / screen_scale)
		if screen_size.x > screen_size.y:
			print("changed to Landscape")
			var margin = 60
			ui_config_h.outside_margin = [
				safe_area_sides + margin,
				margin,
				safe_area_sides + margin,
				margin,
			]
		else:
			print("changed to Portrait")
			var margin = 60
			ui_config_h.outside_margin = [
				margin,
				safe_area_sides + margin,
				margin / 2.,
				margin,
			]

			
func print_info():
	print(Engine.get_main_loop().root.size)
	print("screen_get_size:",DisplayServer.screen_get_size())
	print("screen_get_dpi:",DisplayServer.screen_get_dpi())
	print("screen_get_max_scale:",DisplayServer.screen_get_max_scale())
	print("screen_get_scale:",DisplayServer.screen_get_scale())
	get_tree().root.content_scale_factor
