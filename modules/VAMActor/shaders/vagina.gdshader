shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#include "includes/lattice_vertex_a.gdshaderinc"
#include "includes/lattice_vertex_b.gdshaderinc"

void vertex()
{
	if(COLOR.r > 0.0)
		VERTEX = lattice_vertex_A(VERTEX);
	if(COLOR.g > 0.0)
		VERTEX = lattice_vertex_B(VERTEX);
}

#include "includes/skin_fragment.gdshaderinc"

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
