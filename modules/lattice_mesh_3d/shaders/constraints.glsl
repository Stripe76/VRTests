#[compute]
#version 450

layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

layout(rgba32f, set = 0, binding = 0) uniform restrict image3D current;
layout(rgba32f, set = 1, binding = 0) uniform restrict image3D previous;

layout(push_constant, std430) uniform Params
{
    float dt;
    float spring;
    float damping;
    bool do_shift;
    bool do_rotate;
    ivec3 size;
    vec3 shift;
    vec4 rotate;
    vec3 gravity;
} params;


void main()
{
    uint x = gl_GlobalInvocationID.x;
    uint y = gl_GlobalInvocationID.y;
    uint z = gl_GlobalInvocationID.z;

    ivec3 coord = ivec3(x,y,z);

    vec4 curr_frame = imageLoad(current,coord);
    vec3 position = curr_frame.xyz;

    if (x > 0)
    {
        int prev_x = int(x) - 1;
        vec3 parent_position = imageLoad(previous,ivec3(prev_x,y,z)).rgb;

        parent_position.x += 0.05;

        vec3 difference = parent_position - position;
        float dist = length(difference);

        if (dist > 0.000001)
        {
            vec3 delta = params.spring * dist * normalize(difference);

            position += delta;

            imageStore(current,coord,vec4(position,0.0));
        }
    }
}



















