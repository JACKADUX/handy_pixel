#[compute]

#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set=0, binding = 0, rgba8) uniform readonly image2D u_input_image;
layout(set=0, binding = 1, rgba8) uniform writeonly image2D u_output_image;
layout(set=0, binding = 2) buffer Params {
    float params[9];
};

ivec2 pos_list[9] = ivec2[](ivec2(-1,-1),ivec2(0,-1),ivec2(1,-1),
                        ivec2(-1, 0),ivec2(0, 0),ivec2(1, 0),
                        ivec2(-1, 1),ivec2(0, 1),ivec2(1, 1)
                        );

void main(){
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    ivec2 tex_size = imageSize(u_input_image);
    if (coord.x >= tex_size.x || coord.y >= tex_size.y) return;
    vec4 color = imageLoad(u_input_image, coord);
    if (color.a < 0.0001) return;
    
    for(int i=0; i<9; i++){
        ivec2 offset_coord = coord +pos_list[i];
        if (imageLoad(u_input_image, offset_coord).a < 0.0001 && params[i] > 0.5 ){
            imageStore(u_output_image, offset_coord, vec4(1.,1.,1.,1.));
        }
    }

    
}




