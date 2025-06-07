#[compute]

#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set=0, binding = 0, rgba8) uniform readonly image2D u_input_image;
layout(set=0, binding = 1) buffer Params {
    vec4 target_color;  
    float tolerance; 
};
layout(set=0, binding = 2, rgba8) uniform writeonly image2D u_output_image;

bool color_match(vec4 a, vec4 b) {
    vec4 diff = abs(a-b);
    return all(lessThanEqual(diff, vec4(tolerance)));
}

void main() {
    ivec2 pixel_coord = ivec2(gl_GlobalInvocationID.xy);
    ivec2 img_size = imageSize(u_input_image);
    if (pixel_coord.x >= img_size.x || pixel_coord.y >= img_size.y) {
        return; // 超出纹理范围时退出
    }
    vec4 input_pixel = imageLoad(u_input_image, pixel_coord);
    bool match = color_match(input_pixel, target_color);
    vec4 final_color = match ? vec4(1.) : vec4(0);
    imageStore(u_output_image, pixel_coord, final_color);
}