class_name MeshInstanceEx extends MeshInstance3D


func create_mesh(data: Dictionary) -> ArrayMesh:
	var arrays := []
	var surface_tool := SurfaceTool.new()
	
	arrays.resize(Mesh.ARRAY_MAX)
	if data.has("Indices"):
		arrays[Mesh.ARRAY_INDEX] = data["Indices"]
	if data.has("Vertices"):
		arrays[Mesh.ARRAY_VERTEX] = data["Vertices"]
	if data.has("Normals"):
		arrays[Mesh.ARRAY_NORMAL] = data["Normals"]
	if data.has("Colors"):
		arrays[Mesh.ARRAY_COLOR] = data["Colors"]
	if data.has("Customs0"):
		arrays[Mesh.ARRAY_CUSTOM0] = data["Customs0"]
	if data.has("Customs1"):
		arrays[Mesh.ARRAY_CUSTOM1] = data["Customs1"]
	if data.has("UVs"):
		arrays[Mesh.ARRAY_TEX_UV] = data["UVs"]
	
	surface_tool.create_from_arrays(arrays,Mesh.PRIMITIVE_LINES)
	return surface_tool.commit()


func create_mesh_surfaces(	vertices: PackedVector3Array,
							surfaces: Array,
							uvs: PackedVector2Array,
							bones: PackedInt32Array,
							weights: PackedFloat32Array,
							materials : Array,
							bones_number = 4) -> ArrayMesh:
	var arrays := []
	var surface_tool := SurfaceTool.new()
	
	arrays.resize(Mesh.ARRAY_MAX)
	var array_mesh := ArrayMesh.new()
	for surface in surfaces:
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_INDEX] = surface
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		
		surface_tool.create_from_arrays(arrays,Mesh.PRIMITIVE_TRIANGLES)
		if uvs:
			surface_tool.generate_normals()
			surface_tool.generate_tangents()
		if bones_number == 8:
			surface_tool.set_skin_weight_count(SurfaceTool.SKIN_8_WEIGHTS)
		
		surface_tool.commit(array_mesh)
	
	if materials.size() >= surfaces.size():
		for s in surfaces.size():
			array_mesh.surface_set_material(s,materials[s])
	return array_mesh
