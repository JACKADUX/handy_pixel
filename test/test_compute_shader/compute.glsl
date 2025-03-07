#[compute]

#version 450

layout(local_size_x = 16, local_size_y = 1, local_size_z = 1) in;

layout(set=0, binding=0, std430) buffer Floats {
    float data[];
} floats;

void main() {
    //floats.data[gl_LocalInvocationID.x] += 100;
    floats.data[gl_GlobalInvocationID.x] += 100;
}