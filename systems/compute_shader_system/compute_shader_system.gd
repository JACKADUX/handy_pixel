class_name ComputeShaderSystem extends Node

var rd := RenderingServer.create_local_rendering_device()
var _compute_shader_objects :Dictionary[String, ComputeShaderObject]= {}

var shader_objects_path = r"res://systems/compute_shader_system/module/"

const ColorSelect = preload("res://systems/compute_shader_system/module/color_select/color_select.gd")
const Ellipse = preload("res://systems/compute_shader_system/module/ellipse/ellipse.gd")
const FloodFill = preload("res://systems/compute_shader_system/module/flood_fill/flood_fill.gd")
const Inline = preload("res://systems/compute_shader_system/module/inline/inline.gd")
const Outline = preload("res://systems/compute_shader_system/module/outline/outline.gd")

func system_initialize():
	SystemManager.db_system.save_data_requested.connect(func():
		SystemManager.db_system.set_data("ComputeShaderSystem", save_data())
	)
	
	SystemManager.db_system.load_data_requested.connect(func():
		load_data(SystemManager.db_system.get_data("ComputeShaderSystem", {}))
	)
	
	for shader_name:String in DirAccess.get_directories_at(shader_objects_path):
		var shader_obj = load(shader_objects_path.path_join(shader_name).path_join(shader_name+".gd"))
		register_compute_shader_object(shader_name, shader_obj.new())
		

func register_compute_shader_object(key:String, compute_shader_object:ComputeShaderObject):
	if _compute_shader_objects.has(key):
		printerr("compute_shader_object: '%s' already exists."%key)
		return 
	compute_shader_object.set_rd(rd)
	_compute_shader_objects[key] = compute_shader_object

func get_compute_shader_object(key:String) -> ComputeShaderObject:
	return _compute_shader_objects.get(key)

func save_data() -> Dictionary:
	return {}
	
func load_data(data:Dictionary):
	pass
