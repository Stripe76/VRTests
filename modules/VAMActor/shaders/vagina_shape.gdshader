shader_type spatial;
render_mode cull_disabled;

uniform sampler3D data_points : filter_nearest, repeat_disable;

void vertex()
 {
	//if(false)
	{
		vec3 xyz = texelFetch(data_points,ivec3(int(floor(CUSTOM0.x)),int(floor(CUSTOM0.y)),int(floor(CUSTOM0.z))),0).xyz;
		VERTEX = xyz;
		//COLOR.xyz = xyz;
	}
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = vec3(1.0,0.0,0.0);
}

void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
	DIFFUSE_LIGHT = 1.0 * LIGHT_COLOR;
}
