#class_name ComputeShaderHelper



static func create_uniform(type: int, binding: int, rid: RID) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = type
	uniform.binding = binding
	uniform.add_id(rid)
	return uniform

static func new_buffer_RID(rd :RenderingDevice, data:Array) -> RID:
	# [color.r, color.g, color.b, color.a, threshold, ...]
	var buffer_data = PackedFloat32Array(data).to_byte_array()
	return rd.storage_buffer_create(buffer_data.size(), buffer_data)
	
static func new_buffer_uniform(buffer_RID:RID, binding:int=0) -> RDUniform:
	var buffer_uniform := RDUniform.new()
	buffer_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	buffer_uniform.binding = binding
	buffer_uniform.add_id(buffer_RID)
	return buffer_uniform

static func texture_RID_from_sampling_image(rd :RenderingDevice, image:Image, input:=true) -> RID:
	var img_size = image.get_size()
	var fmt := RDTextureFormat.new()
	fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	fmt.width = img_size.x
	fmt.height = img_size.y
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	if input:
		fmt.usage_bits |=  RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	else:
		fmt.usage_bits |=  RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	return rd.texture_create(fmt, RDTextureView.new(), [image.get_data()])

static func new_image_uniform(texture_RID:RID, binding:int=0) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = binding
	uniform.add_id(texture_RID)
	return uniform

		
func _glsl_copy_to_use():
	"""
#[compute]

#version 450

// 这里记得和 LOCAL_INVOCATION 对应
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set=0, binding=0) buffer MyBuffer {
	vec4 target_color;
	float threshold;
} u_buffer;

layout(set=0, binding=1, rgba8) uniform readonly image2D u_input_image;

layout(set=0, binding=2, rgba8) uniform writeonly image2D u_output_image;

void main() {
	ivec2 pixel_coord = ivec2(gl_GlobalInvocationID.xy);
	ivec2 img_size = imageSize(u_input_image);
	if (pixel_coord.x >= img_size.x || pixel_coord.y >= img_size.y) {
		return; // 超出纹理范围时退出
	}

	vec4 input_pixel = imageLoad(u_input_image, pixel_coord);
	
	vec4 diff = abs(input_pixel-u_buffer.target_color);
	bool match = all(lessThanEqual(diff, vec4(u_buffer.threshold)));
	vec4 final_color = match ? vec4(1.) : vec4(0.1);
	// 写入输出纹理
	imageStore(u_output_image, pixel_coord, final_color);
}
	"""
	pass
	
class FnsCaller:

	var _fns :Array[Callable]= []

	func add(fn:Callable):
		_fns.append(fn)

	func clear():
		_fns.clear()

	func call_fns():
		for fn in _fns:
			fn.call()
		clear()
