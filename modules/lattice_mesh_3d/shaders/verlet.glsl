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


vec4 qmul(in vec4 q1,in vec4 q2)
{
    return vec4(q2.xyz * q1.w + q1.xyz * q2.w + cross(q1.xyz, q2.xyz), q1.w * q2.w - dot(q1.xyz, q2.xyz)	);
}

vec3 rotate_vector(vec3 v, vec4 r)
{
    vec4 r_c = r * vec4(-1, -1, -1, 1);
    return qmul(r, qmul(vec4(v, 0), r_c)).xyz;
}


void main()
{
    uint x = gl_GlobalInvocationID.x;
    uint y = gl_GlobalInvocationID.y;
    uint z = gl_GlobalInvocationID.z;

    ivec3 coord = ivec3(x,y,z);

    vec4 curr_frame = imageLoad(current,coord);
    vec4 prev_frame = imageLoad(previous,coord);

    vec3 curr = curr_frame.xyz;
    vec3 prev = prev_frame.xyz;
    float rest_length = curr_frame.w;

    if (x > 0)
    {
        if (params.do_shift)
        {
            curr -= params.shift*.5;
            prev -= params.shift*.5;
        }
        vec3 velocity = (curr - prev);
        vec3 new_pos = curr + velocity*params.damping + params.gravity*params.dt*params.dt;

        //if (new_pos != curr)
        {
            imageStore(previous,coord,vec4(curr,curr_frame.w));
            imageStore(current,coord,vec4(new_pos,rest_length));
        }
    }
}




























