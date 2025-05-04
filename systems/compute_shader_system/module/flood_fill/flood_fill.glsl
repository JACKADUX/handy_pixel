#[compute]

#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set=0, binding = 0, rgba8) uniform readonly image2D u_input_image;
layout(set=0, binding = 1, rgba8) uniform writeonly image2D u_output_image;
layout(set=0, binding = 2, rgba8) uniform image2D u_visited_mask;
layout(set=0, binding = 3) buffer Params {
    vec4 target_color; 
    vec4 fill_color; 
    float tolerance; 
};
layout(set=0, binding = 4) buffer Counter {
    int counter; 
    int hv_pass;
};

bool color_match(vec4 a, vec4 b) {
    vec4 diff = abs(a-b);
    return all(lessThanEqual(diff, vec4(tolerance)));
}

void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    ivec2 tex_size = imageSize(u_input_image);
    if (coord.x >= tex_size.x || coord.y >= tex_size.y) return;

    vec4 mask = imageLoad(u_visited_mask, coord);
    // 已用 或者 未标记
    if (mask.r > 0.5 || mask.g < 0.5) return;
    
    counter += 1;
    imageStore(u_visited_mask, coord, vec4(1.0, 0., 0., 1.));
    imageStore(u_output_image, coord, fill_color);

    if (hv_pass ==0) {  // hv_pass 在手机上会造成偶尔不完整的填充， 但不知道为什么会这样
        int left = coord.x;
        while (true) {
            left--;
            if (left < 0) break;
            ivec2 l_pos = ivec2(left, coord.y);
            vec4 l_mask = imageLoad(u_visited_mask, l_pos);
            // 已用 或者 已标记
            if (l_mask.r > 0.5 || l_mask.g > 0.5) break;
            if (!color_match(imageLoad(u_input_image, l_pos), target_color)){
                imageStore(u_visited_mask, l_pos, vec4(1.0, 0., 0., 1.));
                break;
            }
            imageStore(u_visited_mask, l_pos, vec4(0.0, 1., 0., 1.));     
        }
        int right = coord.x;
        while (true) {
            right++;
            if (right >= tex_size.x) break;
            ivec2 r_pos = ivec2(right, coord.y);
            vec4 r_mask = imageLoad(u_visited_mask, r_pos);
            if (r_mask.r > 0.5 || r_mask.g > 0.5) break;
            if (!color_match(imageLoad(u_input_image, r_pos), target_color)){
                imageStore(u_visited_mask, r_pos, vec4(1.0, 0., 0., 1.));
                break;
            }
            imageStore(u_visited_mask, r_pos, vec4(0.0, 1., 0., 1.));     
        }
    }else{
        int top = coord.y;
        while (true) {
            top--;
            if (top < 0) break;
            ivec2 t_pos = ivec2(coord.x, top);
            vec4 t_mask = imageLoad(u_visited_mask, t_pos);
            if (t_mask.r > 0.5 || t_mask.g > 0.5) break;
            if (!color_match(imageLoad(u_input_image, t_pos), target_color)){
                imageStore(u_visited_mask, t_pos, vec4(1.0, 0., 0., 1.));
                break;
            }
            imageStore(u_visited_mask, t_pos, vec4(0.0, 1., 0., 1.));    
        }
        int bottom = coord.y;
        while (true) {
            bottom++;
            if (bottom >= tex_size.y) break;
            ivec2 b_pos = ivec2(coord.x, bottom);
            vec4 b_mask = imageLoad(u_visited_mask, b_pos);
            if (b_mask.r > 0.5 || b_mask.g > 0.5) break;
            if (!color_match(imageLoad(u_input_image, b_pos), target_color)){
                imageStore(u_visited_mask, b_pos, vec4(1.0, 0., 0., 1.));
                break;
            }
            imageStore(u_visited_mask, b_pos, vec4(0.0, 1., 0., 1.));    
        }
    }

    
}