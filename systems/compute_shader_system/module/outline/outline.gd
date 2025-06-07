# class_name CSO_Outline 
extends ComputeShaderObject

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
							| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT # 用 rd.texture_get_data
							| RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT # 用 rd.texture_clear
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
	var pattern = [0,0,0,0,0,0,0,0,0]
	var buffer_data = PackedFloat32Array(pattern).to_byte_array()
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
	var image = compute_shader_data.image as Image
	image.convert(Image.FORMAT_RGBA8)
	var pattern = compute_shader_data.pattern
	var count = compute_shader_data.count
	
	var image_size = image.get_size()
	_prepare_resources(compute_shader_data)
	var output_image : Image
	
	# update buffer
	var buffer_data = PackedFloat32Array(pattern).to_byte_array()
	rd.buffer_update(params_buffer_RID, 0, buffer_data.size(), buffer_data)
	# out img
	rd.texture_clear(output_image_RID, Color(0, 0, 0, 0), 0, 1, 0, 1)
	
	for i in count:
		var in_image = output_image if output_image else image
		# in img
		rd.texture_update(input_image_RID, 0, in_image.get_data())
		
		# begin
		var compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline_RID)
		rd.compute_list_bind_uniform_set(compute_list, uniform_set_RID, 0)
		rd.compute_list_dispatch(compute_list, ceil(float(image_size.x) / LOCAL_INVOCATION), ceil(float(image_size.y) / LOCAL_INVOCATION), 1)
		rd.compute_list_end()
	
		rd.submit()
		rd.sync()

		# out
		var output_data = rd.texture_get_data(output_image_RID, 0)
		output_image = Image.create_from_data(image_size.x, image_size.y, false, Image.FORMAT_RGBA8, output_data)

		
	return output_image

func _compute_cpu(compute_shader_data:ComputeShaderData) -> Image:
	var image = compute_shader_data.image as Image
	image.convert(Image.FORMAT_RGBA8)
	var pattern = compute_shader_data.pattern
	var count = compute_shader_data.count
	 
	var pos_list = [Vector2i(-1,-1),Vector2i(0,-1),Vector2i(1,-1),
					Vector2i(-1, 0),Vector2i(0, 0),Vector2i(1, 0),
					Vector2i(-1, 1),Vector2i(0, 1),Vector2i(1, 1)
				   ]
	var output_image = image.duplicate(true) as Image
	output_image.fill(Color.TRANSPARENT)
	for j in count:
		var in_image = output_image.duplicate(true) if j != 0 else image
		for x in image.get_width():
			for y in image.get_height():
				var coord = Vector2i(x, y)
				var color = in_image.get_pixelv(coord);
				if color.a == 0:
					continue
				for i in 9:
					var offset_coord = coord +pos_list[i];
					if (in_image.get_pixelv(offset_coord).a == 0 and pattern[i] > 0.5 ):
						output_image.set_pixelv(offset_coord, Color.WHITE)
		
	return output_image

class OutlineData extends ComputeShaderData:
	enum PatternType {NONE, PLUS, PLUS_CROSS} # + X
	var image: Image
	var pattern := []
	var count :int= 1
	
	const _type_plus = [
		0,1,0,
		1,0,1,
		0,1,0,
	]
	const _type_plus_cross = [
		1,1,1,
		1,0,1,
		1,1,1,
	]
	
	static func create(image:Image, pattern_type:PatternType, count:int=1) -> OutlineData:
		var data = OutlineData.new()
		data.image = image
		data.pattern = _type_plus_cross if pattern_type == PatternType.PLUS_CROSS else _type_plus
		data.count = count
		return data
	
	static func create_with_list(image:Image, pattern:Array, count:int=1) -> OutlineData:
		var data = OutlineData.new()
		data.image = image
		data.pattern = pattern
		data.count = count
		return data
