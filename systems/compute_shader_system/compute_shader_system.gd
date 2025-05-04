class_name ComputeShaderSystem extends Node

var rd := RenderingServer.create_local_rendering_device()
var _compute_shader_objects :Dictionary[String, ComputeShaderObject]= {}

func system_initialize():
	SystemManager.db_system.save_data_requested.connect(func():
		SystemManager.db_system.set_data("ComputeShaderSystem", save_data())
	)
	
	SystemManager.db_system.load_data_requested.connect(func():
		load_data(SystemManager.db_system.get_data("ComputeShaderSystem", {}))
	)

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
