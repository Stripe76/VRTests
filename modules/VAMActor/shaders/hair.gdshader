shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley,specular_schlick_ggx;

uniform float lerp : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D data_points : hint_normal;

uniform float shininess : hint_range(1.0, 200.0) = 25.0;

void vertex() 
{
	vec3 dest = texelFetch(data_points,ivec2(int(floor(UV.x)),int(floor(UV.y))),0).xyz;
	//VERTEX = mix(VERTEX,dest,lerp*(UV.x/24.0) ).xyz;
	VERTEX = dest + CUSTOM0.xyz;
}

void fragment() 
{
	ALBEDO = COLOR.rgb;
}

void light() 
{
	vec3 V = VIEW;
	vec3 L = LIGHT;
	vec3 T = NORMAL;

	float diff = max(dot(NORMAL, L), 0.0);
	diff = 0.0;
	
	float spec = pow(1.0-abs(dot(V*L,T)),shininess) / shininess * 4.0;
	spec *= 1.0-abs(dot(T,L));

	DIFFUSE_LIGHT += diff * LIGHT_COLOR * ATTENUATION;
	SPECULAR_LIGHT += spec * LIGHT_COLOR * ATTENUATION * .2;
}
