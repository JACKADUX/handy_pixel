#[compute]

#version 450

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
    //imageStore(u_output_image, pixel_coord+ivec2(img_size.x, 0), final_color);
}