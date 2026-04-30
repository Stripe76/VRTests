group_uniforms Standard_maps;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_normal : hint_normal;
uniform sampler2D standard_decal : source_color, filter_linear_mipmap, repeat_enable;
group_uniforms;

void fragment() {
	vec3 color = vec3(1.0,1.0,1.0);
	if( texture(standard_decal,UV).a > 0.0 )
		//ALBEDO = mix(color.rgb * texture(standard_diffuse,UV).rgb,texture(standard_decal,UV).rgb,texture(standard_decal,UV).a*1.5);
		ALBEDO = mix(color.rgb * texture(texture_albedo,UV).rgb,texture(standard_decal,UV).rgb,texture(standard_decal,UV).a*1.4);
	else
		ALBEDO = texture(texture_albedo,UV).rgb;
	
	NORMAL_MAP_DEPTH = 0.15;
	NORMAL_MAP = texture(texture_normal,UV).rgb;
	
	//float sss_strength_value = 0.2;
	//float smooth_depth = 1.0;
	//SSS_STRENGTH = sss_strength_value * NORMAL_MAP.r * smooth_depth;

	ROUGHNESS = .65;
	//CLEARCOAT = texture(noise_img,vertexPos.xy).r;
	//AO = 1.0;
	METALLIC = .25;
	//SSS_STRENGTH = .15;
	//SSS_TRANSMITTANCE_COLOR = large_noise;
	//SSS_TRANSMITTANCE_DEPTH = 1.5;
}
