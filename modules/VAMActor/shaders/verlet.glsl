#[compute]
#version 450

layout(local_size_x = 32) in;

layout(rgba32f, set = 0, binding = 0) uniform restrict image2D rest_pose;
layout(rgba32f, set = 1, binding = 0) uniform restrict image2D curr_pose;
layout(rgba32f, set = 2, binding = 0) uniform restrict image2D prev_pose;

layout(push_constant, std430) uniform Params
{
	float dt;
	float lerp;
	float lerp_multi;
	float damping;
	float particles;
	bool do_shift;
	bool do_rotate;
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
	uint s = gl_GlobalInvocationID.x;
	//uint v = gl_GlobalInvocationID.x;
	float particles = params.particles;

	for (uint v = 1; v < uint(particles); v++)
	{
		ivec2 coord = ivec2(v,s);

		vec4 curr_frame = imageLoad(curr_pose,coord);
		float rest_length = curr_frame.a;
		if(rest_length < 0.0)
			return;
		vec4 rest_frame = imageLoad(rest_pose,coord);
		vec4 prev_frame = imageLoad(prev_pose,coord);

		vec3 curr = curr_frame.xyz;
		vec3 prev = prev_frame.xyz;
		vec3 to_store = curr;

        if(params.do_rotate)
        {
			curr = rotate_vector( curr,params.rotate );
			prev = rotate_vector( prev.xyz,params.rotate );
		}
		bool update = true;
		if (params.do_shift)
		{
			curr -= params.shift * (v / particles) * 0.5;
			to_store = curr - params.shift * ((particles-v) / particles) * 0.2;
		}
		vec3 velocity = (curr - prev);
		vec3 new_pos = curr + velocity*params.damping + params.gravity*params.dt*params.dt;

		int prev_v = int(v) - 1;
		vec3 parent_rest = imageLoad(rest_pose,ivec2(prev_v,s)).rgb;
		vec3 parent_vertex = imageLoad(curr_pose,ivec2(prev_v,s)).rgb;

		parent_vertex = mix(parent_vertex,parent_rest,params.lerp * (1-(float(v)/particles)*params.lerp) );

		vec3 diff = new_pos - parent_vertex;
		float d = length(diff);

		if (d > 0.0001)
		{
			float difference = (d - rest_length) / d;

			new_pos -= diff * difference;
		}
		if (new_pos != curr)
		{
			imageStore(prev_pose,coord,vec4(to_store,rest_length));
			imageStore(curr_pose,coord,vec4(new_pos,rest_length));
		}
	}
}
