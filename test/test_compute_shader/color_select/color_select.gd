extends RefCounted

var rd := RenderingServer.get_rendering_device()

var fns_caller := ComputeShaderHelper.FnsCaller.new()

var shader_RID: RID
var pipeline_RID: RID

func _init() -> void:
	var shader_file = load("res://test/test_compute_shader/compute3.glsl")
	var shader_spirv = shader_file.get_spirv()
	shader_RID = rd.shader_create_from_spirv(shader_spirv)
	pipeline_RID = rd.compute_pipeline_create(shader_RID)
	
func compute(input_image: Image, target_color: Color, threshold: float = 0) -> Image:
	fns_caller.clear()
	var tex_size = input_image.get_size()
	
	# in bit
	var color_data = PackedFloat32Array([
						target_color.r,
						target_color.g,
						target_color.b,
						target_color.a,
						threshold
						]
		).to_byte_array()
	var color_buffer_RID = rd.storage_buffer_create(color_data.size(), color_data)
	fns_caller.add(rd.free_rid.bind(color_buffer_RID))

	var data_input_uniform := RDUniform.new()
	data_input_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	data_input_uniform.binding = 0
	data_input_uniform.add_id(color_buffer_RID)

	# in
	var fmt := RDTextureFormat.new()
	fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	fmt.width = tex_size.x
	fmt.height = tex_size.y
	fmt.usage_bits = (RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
					| RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
					)
	var input_texture_RID = rd.texture_create(fmt, RDTextureView.new(), [input_image.get_data()])
	fns_caller.add(rd.free_rid.bind(input_texture_RID))
	
	
	var img_input_uniform := RDUniform.new()
	img_input_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	img_input_uniform.binding = 1
	img_input_uniform.add_id(input_texture_RID)
	
	# out
	var output_format = RDTextureFormat.new()
	output_format.width = tex_size.x
	output_format.height = tex_size.y
	output_format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	output_format.usage_bits = (RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
								| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
								)
	var output_texture_RID = rd.texture_create(output_format, RDTextureView.new())
	fns_caller.add(rd.free_rid.bind(output_texture_RID))
	
	var img_output_uniform := RDUniform.new()
	img_output_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	img_output_uniform.binding = 2
	img_output_uniform.add_id(output_texture_RID)
	
	# uniform_set
	var uniform_set_RID = rd.uniform_set_create([data_input_uniform, img_input_uniform, img_output_uniform], shader_RID, 0)

	# begin
	var compute_list_id := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list_id, pipeline_RID)
	rd.compute_list_bind_uniform_set(compute_list_id, uniform_set_RID, 0)
	rd.compute_list_dispatch(compute_list_id, tex_size.x / 8, tex_size.y / 8, 1)
	rd.compute_list_end()
	
	# output
	var output_data = rd.texture_get_data(output_texture_RID, 0)
	var output_image = Image.create_from_data(tex_size.x, tex_size.y, false, Image.FORMAT_RGBA8, output_data)
	fns_caller.free_rids()
	return output_image


static func cpu_version(image:Image, color:Color, thr:int) -> Image:
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
