#[compute]
#version 450

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(rgba32f, set = 0, binding = 0) uniform restrict image2D base_image;
layout(rgba32f, set = 1, binding = 0) uniform restrict image2D pose_image;
layout(rgba32f, set = 2, binding = 0) uniform restrict image3D vertex_image;

layout(push_constant, std430) uniform Params
{
    float stretch;
    vec3 size;
    vec3 offset;
} params;


void main()
{
    uint x = gl_GlobalInvocationID.x;
    uint y = gl_GlobalInvocationID.y;
    uint size = 8;

    // 13-21
    for (int z = 0; z < 8; z++ )
    {
        vec4 base = imageLoad(base_image,ivec2(z,y));
        vec4 pose = imageLoad(pose_image,ivec2(z,y));
        vec3 normal = pose.xyz;
        vec3 vertex = base.xyz;

        //float stretch = base.w * (params.stretch / 10.0);
        float stretch = params.stretch;
        if (stretch < 2.0)
        {
            float x_var = base.w * 0.02 * stretch;
            //vertex.x += x_var + (float(x) / 8) * (0.0691 - x_var);
            vertex.x += x_var + (float(x) / 8) * (params.size.x - x_var);
        }
        else
        {
            vec3 center = (imageLoad(base_image,ivec2(13,y)).xyz + imageLoad(base_image,ivec2(21,y)).xyz) / 2.0;
            //stretch -= 1;
            vec3 v = center + 0.022 * stretch * normal;
            if (x > 0)
                vertex.x += v.x + x * 0.0025;
            else
                vertex = v;
        }
        vertex += params.offset;

        imageStore(vertex_image,ivec3(x,y,z),vec4(vertex,0));
        //imageStore(vertex_image,ivec3(x,y,z),vec4(vec3(0,0,0),0));
    }
}




























