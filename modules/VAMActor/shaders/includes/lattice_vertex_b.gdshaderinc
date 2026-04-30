uniform vec3 lattice_size_B = vec3(0.1,0.1,0.1);
uniform vec3 lattice_offset_B = vec3(0.0,0.0,0.0);

uniform sampler3D lattice_B : filter_linear, repeat_disable;

vec3 lattice_vertex_B(vec3 mesh_vertex)
{
	vec3 vertex = mesh_vertex - lattice_offset_B;
	if( vertex.x > 0.0 && vertex.x < lattice_size_B.x &&
	    vertex.z > 0.0 && vertex.z < lattice_size_B.z &&
	    vertex.y > 0.0 && vertex.y < lattice_size_B.y )
	{
		vec3 uvw = vertex / lattice_size_B;
	    uvw = (uvw * (8.0 - 1.0) + 0.50) / 8.0;
		vec4 lattice_data = textureLod(lattice_B,uvw,0.0);
		
		return lattice_data.xyz;
	}
	return mesh_vertex;
}