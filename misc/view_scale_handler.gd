extends Node

var _config_path

func save_setting():
	var config = ConfigFile.new()
	if FileAccess.file_exists(_config_path):
		config.load(_config_path)
	config.set_value("viewport", "scale_factor", get_tree().root.content_scale_factor)
	config.save(_config_path)
	
func get_default_scale_factor():
	var config = ConfigFile.new()
	if FileAccess.file_exists(_config_path):
		config.load(_config_path)
	return config.get_value("viewport", "scale_factor", auto_scale_factor())
	
func auto_scale_factor() -> float:
	var screen_size = DisplayServer.screen_get_size()
	var win_size = get_tree().root.size
	var x = screen_size.x/float(win_size.x)
	var y = screen_size.y/float(win_size.y)
	return (x+y)/2

func init_viewsize():
	get_tree().root.content_scale_factor = get_default_scale_factor()
