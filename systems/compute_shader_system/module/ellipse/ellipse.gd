# class_name Ellipse 
extends ComputeShaderObject

# FIXME: gpu 和 cpu 算法结果不一样

var output_image_RID: RID
var params_buffer_RID: RID

func _prepare_resources(compute_shader_data:ComputeShaderData):
	free_rids()
	var image_size = compute_shader_data.size
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
	var buffer_data = PackedFloat32Array([
			fill_color.r, fill_color.g, fill_color.b, fill_color.a
	]).to_byte_array()
	params_buffer_RID = rd.storage_buffer_create(buffer_data.size(), buffer_data)
	add_to_free_list(params_buffer_RID)
	
	var uniform_sets := [
		create_uniform(RenderingDevice.UNIFORM_TYPE_IMAGE, 0, output_image_RID),
		create_uniform(RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER, 1, params_buffer_RID),
	]
	uniform_set_RID = rd.uniform_set_create(uniform_sets, shader_RID, 0)

func compute(compute_shader_data:ComputeShaderData) -> Image:
	# NOTE: 这个覆写主要是方便直接跳转到当前脚本
	return super(compute_shader_data)

func _compute_gpu(compute_shader_data:ComputeShaderData) -> Image:
	compute_shader_data = compute_shader_data as EllipseData
	var image_size = compute_shader_data.size
	var fill_color = compute_shader_data.fill_color
	if image_size.x == 0 or image_size.y == 0:
		return 
	if image_size.x <= 2 or image_size.y <= 2:
		# NOTE:小于2 就不走glsl的算法,而且等于2时由于减角算法 glsl 会输出空图，所以这样最好
		var image = Image.create_empty(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
		image.fill(fill_color)
		return image
	image_size += Vector2i.ONE  # NOTE: +1 是因为 glsl的算法会比实际传入值小1，所以算是个补偿
	compute_shader_data.size = image_size
	_prepare_resources(compute_shader_data)
	var image = compute_ellipse(image_size, fill_color)
	image.resize(image_size.x, image_size.y,Image.INTERPOLATE_TRILINEAR)
	if image_size.x > 1 :
		# NOTE: -1 是因为 glsl的算法会比实际传入值小1，所以算是个补偿后把多余的1个像素剪掉
		image.crop(image_size.x-1, image_size.y)
	if image_size.y > 1:
		image.crop(image.get_width(), image_size.y-1)
		
	return image

func compute_ellipse(image_size: Vector2, fill_color: Color) -> Image:
	if image_size.x <= 0 or image_size.y <= 0:
		return
	# out img
	rd.texture_clear(output_image_RID, Color(0, 0, 0, 0), 0, 1, 0, 1)
	# update buffer
	var buffer_data = PackedFloat32Array([
		fill_color.r, fill_color.g, fill_color.b, fill_color.a,
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
	var is_point_in_ellipse_fn = func(x:int, y:int, rect_size:Vector2) -> bool:
		#计算椭圆中心 (a, b) 和半轴
		var a = rect_size.x * 0.5
		var b = rect_size.y * 0.5
		
		# 计算点相对于椭圆中心的偏移
		var dx = float(x) - a   # 补偿中心偏移 这样就方便裁切末端的空像素
		var dy = float(y) - b
		
		# 避免浮点精度问题的整数形式椭圆方程
		var lhs = (dx * dx) * (b * b) + (dy * dy) * (a * a);
		var rhs = (a * a) * (b * b);
		return lhs <= rhs
	var image_size = compute_shader_data.size
	var fill_color = compute_shader_data.fill_color
	var image = Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	var is_odd_x := bool(image_size.x %2 != 0)
	var is_odd_y := bool(image_size.y %2 != 0)
	var w = round(image_size.x*0.5)
	var h = round(image_size.y*0.5)
	var quater = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for x in w:
		for y in h:
			var coord = Vector2i(x+1, y+1)
			if not is_point_in_ellipse_fn.call(coord.x, coord.y, image_size):
				continue
			# NOTE: 由于我只做1/4 所以只需要检查左边和上面
			var left = is_point_in_ellipse_fn.call(coord.x-1, coord.y, image_size)
			var top = is_point_in_ellipse_fn.call(coord.x, coord.y-1, image_size)
			if not left and not top:
				continue
			quater.set_pixel(x, y, fill_color)
	image.blit_rect(quater, Rect2(0,0,w,h), Vector2.ZERO)
	quater.flip_x()
	if is_odd_x:
		image.blit_rect(quater, Rect2(0,0,w,h), Vector2(w-1,0))
	else:
		image.blit_rect(quater, Rect2(0,0,w,h), Vector2(w,0))
	var rect_top = Rect2(0,0, image_size.x, h)
	var top_part = image.get_region(rect_top)
	top_part.flip_y()
	if is_odd_y:
		image.blit_rect(top_part, rect_top, Vector2(0,h-1))
	else:
		image.blit_rect(top_part, rect_top, Vector2(0,h))
	
	return image

class EllipseData extends ComputeShaderData:
	var size:Vector2i  # w x h
	var fill_color: Color
	
	static func create(size:Vector2i, fill_color:Color) -> EllipseData:
		var data = EllipseData.new()
		data.size = size
		data.fill_color = fill_color
		return data
