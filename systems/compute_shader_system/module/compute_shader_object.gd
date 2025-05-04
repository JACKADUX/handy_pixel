class_name ComputeShaderObject

const LOCAL_INVOCATION := 8  # NOTE: 这个8最好就不要改动了
var rd: RenderingDevice

var shader_RID: RID
var pipeline_RID: RID
var uniform_set_RID: RID

var _rid_free_list :Array[RID]=[] 

func create_uniform(type: int, binding: int, rid: RID) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = type
	uniform.binding = binding
	uniform.add_id(rid)
	return uniform

func set_rd(rd:RenderingDevice):
	if not rd:
		return
	self.rd = rd
	var shader_file = load(get_glsl_path())
	var shader_spirv = shader_file.get_spirv()
	shader_RID = rd.shader_create_from_spirv(shader_spirv)
	pipeline_RID = rd.compute_pipeline_create(shader_RID)

func get_glsl_path() -> String:
	# NOTE: 默认调用同路径下的同名.glsl文件, 可覆写该方法返回正确的路径
	var res_path = get_script().resource_path as String
	return res_path.get_basename()+".glsl"

func add_to_free_list(rid:RID):
	if rid not in _rid_free_list:
		_rid_free_list.append(rid)

func free_rids():
	if not rd:
		return
	for rid:RID in _rid_free_list:
		if not rid.is_valid():
			print("rid not valid %s"%str(rid))
			continue
		rd.free_rid(rid)
	_rid_free_list.clear()
	
func _prepare_resources(compute_shader_data:ComputeShaderData):
	# NOTE: 创建RID，具体细节参考flood_fill.gd 或者 ellipse.gd
	# WARNING: 记得在合适的实际 free_rids() 否则可能造成内存泄漏
	free_rids()
	pass

func _gpu_usable()->bool:
	return rd != null

func compute(compute_shader_data:ComputeShaderData) -> Image:
	if _gpu_usable():
		return _compute_gpu(compute_shader_data)
	else:
		return _compute_cpu(compute_shader_data)
		
func _compute_gpu(compute_shader_data:ComputeShaderData) -> Image:
	return 

func _compute_cpu(compute_shader_data:ComputeShaderData) -> Image:
	return


static func get_from_system(key:String) -> ComputeShaderObject:
	return SystemManager.compute_shader_system.get_compute_shader_object(key)


class ComputeShaderData: pass
# NOTE: 继承该类创建compute_shader_object的参数对象
