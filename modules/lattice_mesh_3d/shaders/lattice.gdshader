shader_type spatial;

uniform float lerp : hint_range(0.0, 1.0) = 1.0;

uniform float grid_res = 16.0;
uniform vec3 grid_offset = vec3(-.175,-.175,-.175);
uniform vec3 grid_size_meters = vec3(.35, .35, .35);

uniform sampler3D data_points : filter_linear, repeat_disable;

void vertex()
 {
	if(false)
	{
		vec3 xyz = texelFetch(data_points,ivec3(int(CUSTOM0.x),int(CUSTOM0.y),int(CUSTOM0.z)),0).xyz;
		VERTEX = xyz;
	}
	else
	{
		vec3 uvw = ( (VERTEX - grid_offset) / grid_size_meters) + 0.5;
		
	    uvw = (uvw * (grid_res - 1.0) + 0.5) / grid_res;
		
		vec4 grid_data = textureLod(data_points,uvw,0.0);

		VERTEX = mix(VERTEX,grid_data.xyz,lerp).xyz;
	}
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = COLOR.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
