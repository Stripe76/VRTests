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

#include "includes/skin_fragment.gdshaderinc"
