uniform vec3 lattice_size_A = vec3(0.1,0.1,0.1);
uniform vec3 lattice_offset_A = vec3(0.0,0.0,0.0);

uniform sampler3D lattice_A : filter_linear, repeat_disable;

vec3 lattice_vertex_A(vec3 mesh_vertex)
{
	vec3 vertex = mesh_vertex - lattice_offset_A;
	if( vertex.x > 0.0 && vertex.x < lattice_size_A.x &&
	    vertex.z > 0.0 && vertex.z < lattice_size_A.z &&
	    vertex.y > 0.0 && vertex.y < lattice_size_A.y )
	{
		vec3 uvw = vertex / lattice_size_A;
	    uvw = (uvw * (8.0 - 1.0) + 0.50) / 8.0;
		vec4 lattice_data = textureLod(lattice_A,uvw,0.0);
		
		return lattice_data.xyz;
	}
	return mesh_vertex;
}