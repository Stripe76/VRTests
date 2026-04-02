shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

group_uniforms Base_skin;
uniform vec4 base_skin : source_color = vec4(1.0);
uniform float base_value;
group_uniforms;

uniform vec4 light_noise : source_color = vec4(1.0);
uniform float light_value;
uniform float light_scale;

uniform vec4 dark_noise : source_color = vec4(1.0);
uniform float dark_value;
uniform float dark_scale;

uniform vec4 large_noise : source_color = vec4(1.0);
uniform float large_value;
uniform float large_scale;

uniform float skin_scale;
uniform float skin_depth;

uniform float blemish_value;
uniform vec4 blemish_color : source_color = vec4(1.0);

group_uniforms Standard_maps;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_normal : hint_normal;
uniform sampler2D standard_decal : source_color, filter_linear_mipmap, repeat_enable;
group_uniforms;

group_uniforms Shader_maps;
uniform sampler2D diffuse_map;// : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D noise_img : source_color, filter_nearest_mipmap;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap;
uniform sampler2D blemish_map;
group_uniforms;

uniform bool use_ambient_occlusion = true;
uniform float ao_strength : hint_range(0.0, 2.0) = 0.5;

varying vec3 vertexPos;

uniform mat4 skin_matrices[82]; // Matrici dei bones

uniform sampler2D bones : filter_nearest;
uniform sampler2D weights : filter_nearest;

float get_offset_x(int bone,float weight,vec3 vertex) {
	if (bone >= 81)
		return 0.0;

	mat4 bone_matrix = skin_matrices[bone];
	vec3 transformed = (bone_matrix * vec4(vertex,1.0)).xyz;

	return transformed.x * weight;
}
float get_offset_y(int bone,float weight,vec3 vertex) {
	if (bone >= 81)
		return 0.0;

	mat4 bone_matrix = skin_matrices[bone];
	vec3 transformed = (bone_matrix * vec4(vertex,1.0)).xyz;

	return transformed.y * weight;
}
float get_offset_z(int bone,float weight,vec3 vertex) {
	if (bone >= 81)
		return 0.0;

	mat4 bone_matrix = skin_matrices[bone];
	vec3 transformed = (bone_matrix * vec4(vertex,1.0)).xyz;

	return transformed.z * weight;
}

void vertex() {
	int index = int(COLOR.r * 255.0) + int(COLOR.g * 255.0) * 256;
	//index = 1;
	//vec3 skinned_pos = VERTEX;
	vec3 skinned_pos = vec3(0);

	mat4 transformed = mat4(0);
	for (int i = 0; i < 2; i++) {
	    // --- Coordinata Z ---
	    vec4 b = texelFetch(bones,ivec2(index,i+0),0);
	    vec4 w = texelFetch(weights,ivec2(index,i+0),0);

	    for (int j = 0; j < 4; j++) {
	        int bone_index = int(b[j] * 255.0);
	        float weight = w[j];
	        transformed += skin_matrices[bone_index] * weight;
	    }
	}
	VERTEX += (transformed * vec4(vec3(0), 0.0)).xyz;
}

void fragment() {
	float noiseLight = texture(noise_img,UV*20.0*light_scale).g * light_value;
	float noiseDark = texture(noise_img,UV*20.0*dark_scale).r * dark_value;
	float noiseLarge = texture(noise_img,vertexPos.xy*(0.2*large_scale)).g * large_value;

	vec3 color = mix(texture(diffuse_map,UV).rgb,base_skin.rgb,base_value);
	//color = mix(color.rgb,large_noise.rgb,vec3(noiseLarge,noiseLarge,noiseLarge));
	color = mix(color.rgb,light_noise.rgb,vec3(noiseLight,noiseLight,noiseLight));
	color = mix(color.rgb,dark_noise.rgb,vec3(noiseDark,noiseDark,noiseDark));

	if( texture(standard_decal,UV).a > 0.0 )
		//ALBEDO = mix(color.rgb * texture(standard_diffuse,UV).rgb,texture(standard_decal,UV).rgb,texture(standard_decal,UV).a*1.5);
		ALBEDO = mix(color.rgb * texture(texture_albedo,UV).rgb,texture(standard_decal,UV).rgb,texture(standard_decal,UV).a);
	else
		ALBEDO = color.rgb * texture(texture_albedo,UV).rgb;
	//ALBEDO = vec3(0.5,0.5,0.5);
	//vec3 nm = texture(normal_map,vec2(UV.x*20.0*skin_scale,UV.y*20.0*skin_scale)).rgb;
	//nm.x = 1.0 - nm.x;
	//float d = texture(blemish_map,UV).r;
	//NORMAL_MAP_DEPTH = d * skin_depth;
	//NORMAL_MAP_DEPTH = skin_depth;
	NORMAL_MAP_DEPTH = 0.5;
	NORMAL_MAP = texture(texture_normal,UV).rgb;
	
	float sss_strength_value = 0.2;
	float smooth_depth = 1.0;
	//SSS_STRENGTH = sss_strength_value * NORMAL_MAP.r * smooth_depth;

	ROUGHNESS = .65;
	//CLEARCOAT = texture(noise_img,vertexPos.xy).r;
	//AO = 1.0;
	METALLIC = .1;
	//SSS_STRENGTH = .15;
	//SSS_TRANSMITTANCE_COLOR = large_noise;
	//SSS_TRANSMITTANCE_DEPTH = 1.5;
}
