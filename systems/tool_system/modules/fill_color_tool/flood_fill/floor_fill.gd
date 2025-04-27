class_name FloodFill

const LOCAL_INVOCATION := 8
var rd: RenderingDevice

var shader_RID: RID
var pipeline_RID: RID
var uniform_set_RID: RID

var input_image_rid: RID
var output_image_rid: RID
var visited_mask_rid: RID
var params_buffer_RID: RID
var counter_buffer_RID: RID

var main_image: Image

func set_rd(p_rd: RenderingDevice):
	if not p_rd:
		return
	rd = p_rd
	var shader_file = load("res://systems/tool_system/modules/fill_color_tool/flood_fill/flood_fill.glsl")
	var shader_spirv = shader_file.get_spirv()
	shader_RID = rd.shader_create_from_spirv(shader_spirv)
	pipeline_RID = rd.compute_pipeline_create(shader_RID)
	
func free_rids():
	if not rd or not input_image_rid:
		return
	rd.free_rid(input_image_rid)
	rd.free_rid(output_image_rid)
	rd.free_rid(visited_mask_rid)
	rd.free_rid(params_buffer_RID)
	rd.free_rid(counter_buffer_RID)
	
func _prepare_resources():
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
	# 访问标记纹理
	var mask_fmt := RDTextureFormat.new()
	mask_fmt.width = width
	mask_fmt.height = height
	mask_fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	mask_fmt.usage_bits = (RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
						| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
						| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
						)
	visited_mask_rid = rd.texture_create(mask_fmt, RDTextureView.new())
	
	# 属性
	var target_color := Color.BLACK
	var fill_color := Color.BLACK
	var tolerance = 0
	var buffer_data = PackedFloat32Array([
			target_color.r, target_color.g, target_color.b, target_color.a,
			fill_color.r, fill_color.g, fill_color.b, fill_color.a,
			tolerance
	]).to_byte_array()
	params_buffer_RID = rd.storage_buffer_create(buffer_data.size(), buffer_data)
	
	var counter_data = PackedInt32Array([0, 0]).to_byte_array()
	counter_buffer_RID = rd.storage_buffer_create(counter_data.size(), counter_data)

	var uniform_sets := [
		create_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 0, input_image_rid),
		create_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 1, output_image_rid),
		create_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 2, visited_mask_rid),
		create_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 3, params_buffer_RID),
		create_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 4, counter_buffer_RID)
	]
	uniform_set_RID = rd.uniform_set_create(uniform_sets, shader_RID, 0)

func create_uniform(type: int, binding: int, rid: RID) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = type
	uniform.binding = binding
	uniform.add_id(rid)
	return uniform

func compute(image: Image, qury_pos: Vector2i, fill_color: Color, tolerance: float = 0, max_iter = 1000) -> Image:
	# NOTE: 理论上 max_iter 基本不会到1000，比较大的图20-30基本能跑完， 所以可以保持默认
	var target_color = image.get_pixelv(qury_pos)
	if target_color == fill_color:
		return
	var tex_size = image.get_size()
	if main_image != image:
		main_image = image
		free_rids()
		_prepare_resources()
	
	# in img
	rd.texture_update(input_image_rid, 0, image.get_data())
	# out img
	rd.texture_clear(output_image_rid, Color(0, 0, 0, 0), 0, 1, 0, 1)
	# mask img
	var mask = Image.create(tex_size.x, tex_size.y, false, Image.FORMAT_RGBA8)
	mask.set_pixelv(qury_pos, Color(0, 1, 0, 0))
	rd.texture_update(visited_mask_rid, 0, mask.get_data())
	
	# update buffer
	var buffer_data = PackedFloat32Array([
		target_color.r, target_color.g, target_color.b, target_color.a,
		fill_color.r, fill_color.g, fill_color.b, fill_color.a,
		tolerance
	]).to_byte_array()
	rd.buffer_update(params_buffer_RID, 0, buffer_data.size(), buffer_data)
	
	# begin
	#NOTE: hv_pass 0 水平，1 垂直。由于手机端会出现未知原因的不完整填充 所以暂时关闭这个功能，但不影响结果
	var hv_pass: int = 0 
	for i in max_iter:
		var counter_data = PackedInt32Array([0, hv_pass]).to_byte_array()
		rd.buffer_update(counter_buffer_RID, 0, counter_data.size(), counter_data)
		
		var compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline_RID)
		rd.compute_list_bind_uniform_set(compute_list, uniform_set_RID, 0)
		rd.compute_list_dispatch(compute_list, ceil(float(tex_size.x) / LOCAL_INVOCATION) , ceil(float(tex_size.y) / LOCAL_INVOCATION), 1)
		rd.compute_list_end()
		
		rd.submit()
		rd.sync()

		var outdata = rd.buffer_get_data(counter_buffer_RID, 0, counter_data.size()).to_int32_array()
		if outdata[0] == 0:
			break
		hv_pass = 1 - hv_pass
	# out
	var output_data = rd.texture_get_data(output_image_rid, 0)
	var output_image = Image.create_from_data(tex_size.x, tex_size.y, false, Image.FORMAT_RGBA8, output_data)
	return output_image


static func floor_fill_cpu(image: Image, qury_pos: Vector2i, fill_color: Color, tolerance: float = 0, max_iter = 1000):
	var w = image.get_width()
	var h = image.get_height()
	var output_image :Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var poss := PackedVector2Array()
	poss.append(qury_pos)
	var next_poss : PackedVector2Array
	
	var target_color = image.get_pixelv(qury_pos)
	
	var color_match_fn = func(color1, color2):
		var dr = color1.r - color2.r
		var dg = color1.g - color2.g
		var db = color1.b - color2.b
		var sqr = dr*dr + dg*dg + db*db
		return sqr <= tolerance*tolerance
		
	var counter := 0
	var hv_pass = 0
	while true:
		if not poss:
			break
		counter += 1
		if counter >= max_iter:
			break
		next_poss = PackedVector2Array()
		for pos in poss:
			output_image.set_pixelv(pos, fill_color)
			var left = pos.x
			while hv_pass:
				left -= 1
				if left < 0: break
				var coord = Vector2(left, pos.y)
				if not color_match_fn.call(image.get_pixelv(coord), target_color) or output_image.get_pixelv(coord) == fill_color:
					break
				if coord in poss or coord in next_poss:
					break
				next_poss.append(coord)
				
			var right = pos.x
			while hv_pass:
				right += 1
				if right >= w: break
				var coord = Vector2(right, pos.y)
				if not color_match_fn.call(image.get_pixelv(coord), target_color) or output_image.get_pixelv(coord) == fill_color:
					break
				if coord in poss or coord in next_poss:
					break
				next_poss.append(coord)
			var top = pos.y
			while not hv_pass:
				top -= 1
				if top < 0: break
				var coord = Vector2(pos.x, top)
				if not color_match_fn.call(image.get_pixelv(coord), target_color) or output_image.get_pixelv(coord) == fill_color:
					break
				if coord in poss or coord in next_poss:
					break
				next_poss.append(coord)
			var bottom = pos.y
			while not hv_pass:
				bottom += 1
				if bottom >= h: break
				var coord = Vector2(pos.x, bottom)
				if not color_match_fn.call(image.get_pixelv(coord), target_color) or output_image.get_pixelv(coord) == fill_color:
					break
				if coord in poss or coord in next_poss:
					break
				next_poss.append(coord)
		poss = next_poss
		hv_pass = 1- hv_pass
	return output_image
