#[compute]
#version 450
layout(local_size_x = 8, local_size_y = 8) in;

layout(set=0, binding = 0, rgba8) uniform readonly image2D u_input_image;
layout(set=0, binding = 1, rgba8) uniform writeonly image2D u_output_image;
layout(set=0, binding = 2, r8) uniform image2D u_visited_mask;

layout(set=0, binding = 3) buffer WorkQueue { int segments[]; };
layout(set=0, binding = 4) buffer AtomicCounter { int queue_count; };
layout(set=0, binding = 5) buffer Params {
    vec4 target_color; 
    vec4 fill_color; 
    float tolerance; 
};

bool color_match(vec4 a, vec4 b) {
    vec4 diff = abs(a-b);
    return all(lessThanEqual(diff, vec4(tolerance)));
}

void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    ivec2 tex_size = imageSize(u_input_image);
    if (coord.x >= tex_size.x || coord.y >= tex_size.y) return;

    int total_segments = queue_count;
    if (total_segments <= 0) return;

    for (int idx = 0; idx < total_segments; idx++) {
        if (idx % int(gl_WorkGroupSize.x * gl_NumWorkGroups.x) != int(gl_LocalInvocationIndex)) continue;


        int base = idx * 3;
        int x_start = segments[base];
        int x_end = segments[base + 1];
        int y = segments[base + 2];

        for (int x = x_start; x <= x_end; x++) {
            ivec2 pos = ivec2(x, y);
            if (pos.x < 0 || pos.x >= tex_size.x || pos.y < 0 || pos.y >= tex_size.y) continue;

            float visited = imageLoad(u_visited_mask, pos).r;
            if (visited > 0.5) continue;

            imageStore(u_visited_mask, pos, vec4(1.0));

            imageStore(u_output_image, pos, fill_color);

            int left = x;
            while (left > 0 && color_match(imageLoad(u_input_image, ivec2(left-1, y)), target_color)) {
                left--;
            }

            int right = x;
            while (right < tex_size.x-1 && color_match(imageLoad(u_input_image, ivec2(right+1, y)), target_color)) {
                right++;
            }

            for (int dy = -1; dy <= 1; dy += 2) {
                int new_y = y + dy;
                if (new_y < 0 || new_y >= tex_size.y) continue;

                int prev_count = atomicAdd(queue_count, 1);
                if (prev_count * 3 + 2 >= segments.length()) {
                    atomicAdd(queue_count, -1);
                    continue;
                }

                int new_base = prev_count * 3;
                segments[new_base] = left;
                segments[new_base + 1] = right;
                segments[new_base + 2] = new_y;
            }
        }
    }
}