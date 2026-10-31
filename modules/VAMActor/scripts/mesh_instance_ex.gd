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
