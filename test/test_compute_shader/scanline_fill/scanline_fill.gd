class_name ScanlineFill

const LOCAL_INVOCATION := 8
var rd := RenderingServer.create_local_rendering_device()

var fns_caller := ComputeShaderHelper.FnsCaller.new()

var shader_RID: RID
var pipeline_RID: RID

var input_image_rid: RID
var output_image_rid: RID
var visited_mask_rid: RID
var work_queue_buffer_rid: RID
var atomic_counter_rid: RID

func _init():
	var shader_file = load("res://test/test_compute_shader/scanline_fill/scanline_fill.glsl")
	var shader_spirv = shader_file.get_spirv()
	shader_RID = rd.shader_create_from_spirv(shader_spirv)
	pipeline_RID = rd.compute_pipeline_create(shader_RID)

func free_rids():
	fns_caller.free_rids()
	rd.free_rid(shader_RID)
	rd.free_rid(pipeline_RID)

func _prepare_resources(image: Image, coord: Vector2i):
	fns_caller.call_fns()
	var width := image.get_width()
	var height := image.get_height()

	# 输入纹理
	var input_fmt := RDTextureFormat.new()
	input_fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	input_fmt.width = width
	input_fmt.height = height
	input_fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	input_image_rid = rd.texture_create(input_fmt, RDTextureView.new(), [image.get_data()])
	fns_caller.add(rd.free_rid.bind(input_image_rid))
	
	# 输出纹理
	var output_fmt := RDTextureFormat.new()
	output_fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	output_fmt.width = width
	output_fmt.height = height
	output_fmt.usage_bits = (RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
							RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT |
							RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT
							)
	output_image_rid = rd.texture_create(output_fmt, RDTextureView.new(), [])
	fns_caller.add(rd.free_rid.bind(output_image_rid))
	
	# 访问标记纹理（单通道）
	var mask_fmt := RDTextureFormat.new()
	mask_fmt.format = RenderingDevice.DATA_FORMAT_R8_UNORM
	mask_fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT
	visited_mask_rid = rd.texture_create(mask_fmt, RDTextureView.new())
	fns_caller.add(rd.free_rid.bind(visited_mask_rid))
	
	# 工作队列缓冲区（存储扫描线段：x_start, x_end, y）
	var initial_data := PackedInt32Array([coord.x, coord.x, coord.y]).to_byte_array()
	work_queue_buffer_rid = rd.storage_buffer_create(initial_data.size(), initial_data)
	fns_caller.add(rd.free_rid.bind(work_queue_buffer_rid))
	
	# 原子计数器（记录队列长度）
	atomic_counter_rid = rd.storage_buffer_create(4, PackedInt32Array([1]).to_byte_array())
	fns_caller.add(rd.free_rid.bind(atomic_counter_rid))

func update(coord: Vector2i):
	# 重置资源
	rd.buffer_clear(work_queue_buffer_rid, 0, 4)
	rd.buffer_update(atomic_counter_rid, 0, 4, PackedInt32Array([0]).to_byte_array())
	rd.texture_clear(visited_mask_rid, Color.BLACK, 1, 1, 0, 1)
	rd.texture_clear(output_image_rid, Color.TRANSPARENT, 1, 1, 0, 1)

	# 初始化工作队列（种子点）
	var initial_data := PackedInt32Array([coord.x, coord.x, coord.y]).to_byte_array()
	rd.buffer_update(work_queue_buffer_rid, 0, initial_data.size(), initial_data)
	rd.buffer_update(atomic_counter_rid, 0, 4, PackedInt32Array([1]).to_byte_array())

func compute(image: Image, qury_pos: Vector2i, fill_color: Color, tolerance: float = 0) -> Image:
	var target_color = image.get_pixelv(qury_pos)
	if target_color == fill_color:
		return
	_prepare_resources(image, qury_pos)
	#update(qury_pos)
	var tex_size = image.get_size()
	# buffer
	var params_buffer_RID := ComputeShaderHelper.new_buffer_RID(rd, [
		target_color.r, target_color.g, target_color.b, target_color.a,
		fill_color.r, fill_color.g, fill_color.b, fill_color.a,
		tolerance
	])
	fns_caller.add(rd.free_rid.bind(params_buffer_RID))
	
	# uniform_set
	var uniform_sets := [
		ComputeShaderHelper.create_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 0, input_image_rid),
		ComputeShaderHelper.create_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 1, output_image_rid),
		ComputeShaderHelper.create_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 2, visited_mask_rid),
		ComputeShaderHelper.create_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 3, work_queue_buffer_rid),
		ComputeShaderHelper.create_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 4, atomic_counter_rid),
		ComputeShaderHelper.create_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 5, params_buffer_RID)
	]
	var uniform_set_RID := rd.uniform_set_create(uniform_sets, shader_RID, 0)
	
	# begin
	var max_iterations = 10
	# 迭代处理
	for i in max_iterations:
		var compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline_RID)
		rd.compute_list_bind_uniform_set(compute_list, uniform_set_RID, 0)
		rd.compute_list_dispatch(compute_list, tex_size.x / LOCAL_INVOCATION, tex_size.y / LOCAL_INVOCATION, 1)
		rd.compute_list_end()
		rd.submit()
		rd.sync()
		
		# 检查队列是否为空
		var counter_data := rd.buffer_get_data(atomic_counter_rid, 0, 4)
		var counter := counter_data.to_int32_array()[0]
		if counter == 0:
			break
		print("counter:", counter)
	
	# out
	var output_data = rd.texture_get_data(output_image_rid, 0)
	var output_image = Image.create_from_data(tex_size.x, tex_size.y, false, Image.FORMAT_RGBA8, output_data)
	fns_caller.call_fns()
	return output_image


# 扫描线填充算法
static func scanline_fill_cpu(original_image: Image, seed_pos: Vector2i, fill_color: Color) -> Image:
	var texture_size = original_image.get_size()
	var output_image = Image.create_empty(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	var target_color = original_image.get_pixelv(seed_pos)
	if target_color == fill_color: return # 避免重复填充
	
	var stack: Array[Vector2i] = []
	stack.append(seed_pos)
	
	# 初始化访问标记数组
	var visited = []
	visited.resize(texture_size.x)
	for x in range(texture_size.x):
		visited[x] = []
		visited[x].resize(texture_size.y)
		for y in range(texture_size.y):
			visited[x][y] = false
	visited[seed_pos.x][seed_pos.y] = true

	while stack.size() > 0:
		var pos = stack.pop_back()
		var y = pos.y
		
		# 向左延伸
		var left = pos.x
		while left >= 0 and original_image.get_pixel(left, y) == target_color:
			left -= 1
		left += 1
		
		# 向右延伸
		var right = pos.x
		while right < texture_size.x and original_image.get_pixel(right, y) == target_color:
			right += 1
		right -= 1
		
		# 填充当前行
		for x in range(left, right + 1):
			output_image.set_pixel(x, y, fill_color)
		
		# 检查上下行
		for dy in [-1, 1]:
			var new_y = y + dy
			if new_y < 0 or new_y >= texture_size.y:
				continue
			
			var added = false
			for x in range(left, right + 1):
				if original_image.get_pixel(x, new_y) == target_color and not visited[x][new_y]:
					if not added:
						stack.append(Vector2i(x, new_y))
						visited[x][new_y] = true
						added = true
				else:
					added = false
	return output_image
