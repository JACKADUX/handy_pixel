#[compute]

#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set=0, binding=0, std430) buffer MyDataBuffer {
    int data[];
} my_data_buffer;


layout(set=0, binding=1) uniform sampler2D tex;

void main() {
    // 获取纹理尺寸
    //ivec2 tex_size = textureSize(tex, 0);
    
    // 计算归一化UV坐标
    //vec2 uv = vec2(gl_GlobalInvocationID.xy) / vec2(tex_size);

    vec2 uv = vec2(gl_GlobalInvocationID.xy);

    vec4 color = texture(tex, uv);
    if (color.a > 0.0) {
        atomicAdd(my_data_buffer.data[0], 1);
    }

    if (color.a == 0.0) {
        atomicAdd(my_data_buffer.data[1], 1);
    }
    
}