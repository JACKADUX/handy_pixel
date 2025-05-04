#[compute]

#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set=0, binding = 0, rgba8) uniform readonly image2D u_input_image;
layout(set=0, binding = 1, rgba8) uniform writeonly image2D u_output_image;
layout(set=0, binding = 2) buffer Params {
    vec4 fill_color; 
    float width;
};

shared ivec2 check_list[];

void main(){

    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    ivec2 tex_size = imageSize(u_input_image);
    if (coord.x >= tex_size.x || coord.y >= tex_size.y) return;
    vec4 color = imageLoad(u_input_image, coord);
    if (color.a < 0.5) return;

    ivec2 list[4] = ivec2[](ivec2(0,-width),ivec2(-width, 0),ivec2(width, 0),ivec2(0, width));
    int c = 0;
    for(int i=0; i<4; i++){
        ivec2 offset_coord = coord+list[i];
        if (imageLoad(u_input_image, offset_coord).a < 0.5 ){
            c++;
            break;
        }
    }
    if (c == 0) return;
    imageStore(u_output_image, coord, fill_color);
}




