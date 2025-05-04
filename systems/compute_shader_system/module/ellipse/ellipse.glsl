#[compute]

#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set=0, binding = 0, rgba8) uniform writeonly image2D u_output_image;
layout(set=0, binding = 1) buffer Params {
    vec4 fill_color; 
};

bool isPointInEllipse(int x, int y, vec2 rect_size) {
    // 计算椭圆中心 (a, b) 和半轴
    float a = rect_size.x * 0.5;
    float b = rect_size.y * 0.5;
    
    // 计算点相对于椭圆中心的偏移
    float dx = float(x) - a +1.;  // 补偿中心偏移 这样就方便裁切末端的空像素
    float dy = float(y) - b +1.;
    
    // 避免浮点精度问题的整数形式椭圆方程
    float lhs = (dx * dx) * (b * b) + (dy * dy) * (a * a);
    float rhs = (a * a) * (b * b);
    
    return lhs <= rhs;
}

void main(){
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    ivec2 tex_size = imageSize(u_output_image);
    if (coord.x >= tex_size.x || coord.y >= tex_size.y) return;
  
   if (!isPointInEllipse(coord.x, coord.y,tex_size)) return;

    ivec2 list[4] = ivec2[](ivec2(0,-1),ivec2(-1, 0),ivec2(1, 0),ivec2(0, 1));
    int c = 0;
    for(int i=0; i<4; i++){
        ivec2 offset_coord = coord+list[i];
        if (!isPointInEllipse(offset_coord.x, offset_coord.y, tex_size)){
            c++;
        }

    }
    if (c >= 2) return;

    imageStore(u_output_image, coord, fill_color);
}


