class_name Outline extends ComputeShaderObject

var input_image_RID: RID
var output_image_RID: RID
var params_buffer_RID: RID

func _prepare_resources(compute_shader_data:ComputeShaderData):
	free_rids()
	var main_image = compute_shader_data.image
	var image_size = main_image.get_size()
	
	# 输入
	var input_fmt := RDTextureFormat.new()
	input_fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	input_fmt.width = image_size.x
	input_fmt.height = image_size.y
	input_fmt.usage_bits = (RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
							| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
							)
	input_image_RID = rd.texture_create(input_fmt, RDTextureView.new(), [])
	add_to_free_list(input_image_RID)
	
	# 输出纹理
	var output_fmt := RDTextureFormat.new()
	output_fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	output_fmt.width = image_size.x
	output_fmt.height = image_size.y
	output_fmt.usage_bits = (RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
							| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT # 用 rd.texture_get_data
							| RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT # 用 rd.texture_clear
							)
	output_image_RID = rd.texture_create(output_fmt, RDTextureView.new(), [])
	add_to_free_list(output_image_RID)
	
	# 属性
	var fill_color := Color.BLACK
	var width = 1
	var buffer_data = PackedFloat32Array([
			fill_color.r, fill_color.g, fill_color.b, fill_color.a,
			width
	]).to_byte_array()
	params_buffer_RID = rd.storage_buffer_create(buffer_data.size(), buffer_data)
	add_to_free_list(params_buffer_RID)
	
	var uniform_sets := [
		create_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 0, input_image_RID),
		create_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 1, output_image_RID),
		create_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 2, params_buffer_RID),
	]
	uniform_set_RID = rd.uniform_set_create(uniform_sets, shader_RID, 0)

func compute(compute_shader_data:ComputeShaderData) -> Image:
	# NOTE: 这个覆写主要是方便直接跳转到当前脚本
	return super(compute_shader_data)

func _compute_gpu(compute_shader_data:ComputeShaderData) -> Image:
	var image = compute_shader_data.image
	var fill_color = compute_shader_data.fill_color
	var width = compute_shader_data.width
	
	var image_size = image.get_size()
	_prepare_resources(compute_shader_data)
	# in img
	rd.texture_update(input_image_RID, 0, image.get_data())
	# out img
	rd.texture_clear(output_image_RID, Color(0, 0, 0, 0), 0, 1, 0, 1)
	# update buffer
	var buffer_data = PackedFloat32Array([
		fill_color.r, fill_color.g, fill_color.b, fill_color.a,
		width
	]).to_byte_array()
	rd.buffer_update(params_buffer_RID, 0, buffer_data.size(), buffer_data)
	
	# begin
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline_RID)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set_RID, 0)
	rd.compute_list_dispatch(compute_list, ceil(float(image_size.x) / LOCAL_INVOCATION), ceil(float(image_size.y) / LOCAL_INVOCATION), 1)
	rd.compute_list_end()
	
	rd.submit()
	rd.sync ()

	# out
	var output_data = rd.texture_get_data(output_image_RID, 0)
	var output_image = Image.create_from_data(image_size.x, image_size.y, false, Image.FORMAT_RGBA8, output_data)
	return output_image

func _compute_cpu(compute_shader_data:ComputeShaderData) -> Image:
	var image = compute_shader_data.image as Image
	var fill_color = compute_shader_data.fill_color
	var width = compute_shader_data.width
	var final_image = image.duplicate()
	var image_size = image.get_size()
	var valid_fn = func(x,y):
		if x < 0 or x >= image_size.x or y < 0 or y >= image_size.y:
			return true
		return image.get_pixel(x, y).a == 0
	
	var list = [Vector2i(-1,0), Vector2(0,-1), Vector2(1,0), Vector2(0,1)]
	for x in image_size.x:
		for y in image_size.y:
			var any = false
			for p in list:
				if valid_fn.call(x+p.x, y+p.y):
					any = true
					break
			if any:
				continue
			final_image.set_pixel(x, y, Color(0,0,0,0))
	
	return final_image

class OutlineData extends ComputeShaderData:
	var image: Image
	var fill_color: Color
	var width: int=1
	
	static func create(image:Image, fill_color:Color) -> OutlineData:
		var data = OutlineData.new()
		data.image = image
		data.fill_color = fill_color
		return data
