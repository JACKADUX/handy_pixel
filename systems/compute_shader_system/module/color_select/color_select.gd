# class_name CSO_ColorSelect 
extends ComputeShaderObject

var input_image_rid: RID
var output_image_rid: RID
var params_buffer_RID: RID

func _prepare_resources(compute_shader_data:ComputeShaderData):
	free_rids()
	var main_image = compute_shader_data.image as Image
	var width := main_image.get_width()
	var height := main_image.get_height()
	
	# 输入纹理
	var input_fmt := RDTextureFormat.new()
	input_fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	input_fmt.width = width
	input_fmt.height = height
	input_fmt.usage_bits = (RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
							| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
							)
	input_image_rid = rd.texture_create(input_fmt, RDTextureView.new(), [main_image.get_data()])
	add_to_free_list(input_image_rid)
	
	# 输出纹理
	var output_fmt := RDTextureFormat.new()
	output_fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	output_fmt.width = width
	output_fmt.height = height
	output_fmt.usage_bits = (RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
							| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT # 用 rd.texture_update
							| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT # 用 rd.texture_get
							| RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT # 用 rd.texture_clear
							)
	output_image_rid = rd.texture_create(output_fmt, RDTextureView.new(), [])
	add_to_free_list(output_image_rid)
	
	
	# 属性
	var target_color := Color.BLACK
	var fill_color := Color.BLACK
	var tolerance = 0 / 255.0
	var buffer_data = PackedFloat32Array([
			target_color.r, target_color.g, target_color.b, target_color.a,
			fill_color.r, fill_color.g, fill_color.b, fill_color.a,
			tolerance
	]).to_byte_array()
	params_buffer_RID = rd.storage_buffer_create(buffer_data.size(), buffer_data)
	add_to_free_list(params_buffer_RID)
		
	var uniform_sets := [
		create_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 0, input_image_rid),
		create_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 1, params_buffer_RID),
		create_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 2, output_image_rid),
	]
	uniform_set_RID = rd.uniform_set_create(uniform_sets, shader_RID, 0)

func compute(compute_shader_data:ComputeShaderData) -> Image:
	# NOTE: 这个覆写主要是方便直接跳转到当前脚本
	return super(compute_shader_data)

func _compute_gpu(compute_shader_data:ComputeShaderData) -> Image:
	var image = compute_shader_data.image
	var target_color = compute_shader_data.target_color
	var tolerance = compute_shader_data.tolerance / 255.0
	
	_prepare_resources(compute_shader_data)
	var tex_size = image.get_size()
	# in img
	rd.texture_update(input_image_rid, 0, image.get_data())
	# out img
	rd.texture_clear(output_image_rid, Color(0, 0, 0, 0), 0, 1, 0, 1)
	
	# update buffer
	var buffer_data = PackedFloat32Array([
		target_color.r, target_color.g, target_color.b, target_color.a,
		tolerance
	]).to_byte_array()
	rd.buffer_update(params_buffer_RID, 0, buffer_data.size(), buffer_data)
	
	# begin
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline_RID)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set_RID, 0)
	rd.compute_list_dispatch(compute_list, ceil(float(tex_size.x) / LOCAL_INVOCATION) , ceil(float(tex_size.y) / LOCAL_INVOCATION), 1)
	rd.compute_list_end()
	
	rd.submit()
	rd.sync()

	# out
	var output_data = rd.texture_get_data(output_image_rid, 0)
	var output_image = Image.create_from_data(tex_size.x, tex_size.y, false, Image.FORMAT_RGBA8, output_data)
	return output_image

func _compute_cpu(compute_shader_data:ComputeShaderData) -> Image:
	# var shader_data = compute_shader_data as FloodFillData
	return color_select(
		compute_shader_data.image, 
		compute_shader_data.fill_color, 
		compute_shader_data.tolerance, 
	)

class ColorSelectData extends ComputeShaderData:
	var image: Image
	var target_color: Color
	var tolerance: int = 0 # 0-255
	
	static func create(image:Image, target_color:Color, tolerance:int=0) -> ColorSelectData:
		var data = ColorSelectData.new()
		data.image = image
		data.target_color = target_color
		data.tolerance = tolerance
		return data

static func color_select(image:Image, color:Color, thr:int) -> Image:
	var c1 = Vector4(color.r, color.g, color.b, color.a)
	thr = thr/255.0
	var thr2 = thr*thr
	var img = Image.create_empty(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	for x in image.get_width():
		for y in image.get_height():
			var cxy = image.get_pixel(x, y)
			var c2 = Vector4(cxy.r, cxy.g, cxy.b, cxy.a)
			var diff = (c2-c1).abs()
			if (diff.x*diff.x+diff.y*diff.y+ diff.z*diff.z+ diff.w*diff.w) <= thr2:
				img.set_pixel(x, y, Color.WHITE)
			else:
				img.set_pixel(x, y, Color.BLACK)
	return img
