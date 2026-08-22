#[compute]
#version 450

layout(set = 0, r8, binding = 0) uniform image2D tex;

struct UpdateCommand {
	uint x;
	uint y;
	uint color;
};

layout(set = 0, std430, binding = 1) readonly buffer UpdateBuffer {
	UpdateCommand commands[];
};

layout(set = 0, std430, binding = 2) readonly buffer CountBuffer {
	uint count;
};

layout(local_size_x = 1024, local_size_y = 1, local_size_z = 1) in;

void main() {
	uint idx = gl_GlobalInvocationID.x;
	if (idx >= count) return;
	
	UpdateCommand cmd = commands[idx];
	imageStore(tex, ivec2(cmd.x, cmd.y), vec4(float(cmd.color) * (1.0 / 255.0)));
}
