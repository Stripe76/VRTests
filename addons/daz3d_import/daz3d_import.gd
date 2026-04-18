 	# daz3d_plugin.gd
@tool
extends EditorImportPlugin


func _get_importer_name():
	return "mb.daz3d"


func _get_visible_name():
	return "Daz3D mesh import"	


func _get_recognized_extensions():
	return ["dsf"]


func _get_resource_type():
	return "Resource"
	

func _get_save_extension():
	return "res"
	

func _get_priority() -> float:
	return 1


func _get_import_order() -> int:
	return 1


func _get_preset_count():
	return 0


func _get_import_options(path, preset_index):
	return []


func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var file := FileAccess.open(source_file,FileAccess.READ)
	var uv_file := FileAccess.open(source_file+".uv",FileAccess.READ)
	var vam_file := FileAccess.open(source_file+".vam",FileAccess.READ)

	var data  = JSON.parse_string(file.get_as_text())
	var uv_data  = JSON.parse_string(uv_file.get_as_text())
	if not data or not uv_data:
		return ERR_PARSE_ERROR
	
	var vertices : PackedVector3Array = get_as_vertices_array(data,"geometry_library/vertices")
	var normals : PackedVector3Array = PackedVector3Array()
	var unused_indices : Dictionary
	var vam_data : Dictionary
	if vam_file:
		vam_data = load_vam_data(vam_file,vertices.size())
		
		var vam_vertices : PackedVector3Array = vam_data["vertices"]
		var vam_normals : PackedVector3Array = vam_data["normals"]
		if vam_vertices.size() >= vertices.size():
			for i in vertices.size():
				vertices[i] = vam_vertices[i]
				normals.push_back(vam_normals[i])
		unused_indices = vam_data["unused"]
	
	var uvs = get_as_uvs_array(uv_data,"uv_set_library")		
	var extra_uvs_values : PackedVector2Array
	var extra_start := vertices.size()
	while uvs.size() > vertices.size():
		extra_uvs_values.push_back(uvs[extra_start])
		uvs.remove_at(extra_start)
	
	var linked_vertices := {}
	var polylist : Array = data["geometry_library"][0]["polylist"]["values"]
	var extra_uvs : Array = get_as_extra_uvs_array(uv_data,"uv_set_library")
	replace_extra_uv_indices(vertices,normals,uvs,linked_vertices,polylist,extra_uvs,extra_uvs_values,extra_start)
	
	var indices := get_as_indexes_array(data,"geometry_library/polylist",unused_indices)
	var materials := get_as_materials_array(data,"geometry_library/polylist")
	if vam_data:
		add_vam_data(vam_data,vertices,normals,indices,uvs,materials,linked_vertices)
	
	var bones := get_as_bones_array(data,"node_library","modifier_library")
	var weights : Array
	for a in vertices.size( ):
		weights.push_back({"x":Array(),"y":Array(),"z":Array(),"s":Array()})
	var index : int = 0
	for b in bones:
		for w in b["weights"]["x"]:
			weights[w[0]]["x"].push_back(index);
			weights[w[0]]["x"].push_back(w[1]);
		for w in b["weights"]["y"]:
			weights[w[0]]["y"].push_back(index);
			weights[w[0]]["y"].push_back(w[1]);
		for w in b["weights"]["z"]:
			weights[w[0]]["z"].push_back(index);
			weights[w[0]]["z"].push_back(w[1]);
		for w in b["weights"]["s"]:
			weights[w[0]]["s"].push_back(index);
			weights[w[0]]["s"].push_back(w[1]);
		index += 1
	
	for key in linked_vertices.keys():
		for l in linked_vertices[key]:
			weights[l] = weights[key]
	
	var daz3d_mesh : Daz3DMesh = Daz3DMesh.new()
	daz3d_mesh.vertices = vertices
	daz3d_mesh.normals = normals
	daz3d_mesh.indeces = indices
	daz3d_mesh.uvs = uvs
	daz3d_mesh.materials = materials
	daz3d_mesh.linked_vertices = linked_vertices
	daz3d_mesh.bones = bones
	daz3d_mesh.weights = weights
	
	return ResourceSaver.save(daz3d_mesh, "%s.%s" % [save_path, _get_save_extension()])


func add_vam_data(vam_data: Dictionary,vertices: PackedVector3Array,normals: PackedVector3Array,indices: PackedInt32Array,uvs: PackedVector2Array,materials: PackedInt32Array,linked_vertices: Dictionary):
	var vam_normals : PackedVector3Array = vam_data["normals"]
	var vam_uvs : PackedVector2Array = vam_data["uvs"]
	
	var gen_vertices : PackedVector3Array = vam_data["gen_vertices"]
	var gen_normals : PackedVector3Array = vam_data["gen_normals"]
	var gen_indices : PackedInt32Array = vam_data["gen_indices"]
	var gen_uvs : PackedVector2Array = vam_data["gen_uvs"]
	var gen_materials : PackedInt32Array = vam_data["gen_materials"]
	
	print("vertices: ",vertices.size())
	print("normals: ",vam_normals.size())

	print("gen vertices: ",gen_vertices.size())
	print("gen indices: ",gen_indices.size())
	
	var tris := 0
	var vertices_start := vertices.size()
	for i in gen_vertices.size( ):
		vertices.push_back(gen_vertices[i])
		normals.push_back(gen_normals[i])
		uvs.push_back(gen_uvs[i])
		
	for m in gen_materials:
		materials.push_back(m)
		
		#print(gen_indices[tris],",",gen_indices[tris+1],",",gen_indices[tris+2])	
		var index = gen_indices[tris]
		indices.push_back(vertices_start+index)
		tris += 1
		
		index = gen_indices[tris]
		indices.push_back(vertices_start+index)
		tris += 1
		
		index = gen_indices[tris]
		indices.push_back(vertices_start+index)
		tris += 1
	
	var missing := []
	var first := -1
	for i in gen_vertices.size():
		var v : Vector3 = gen_vertices[i]
		
		var found := false
		for c in vertices_start:
			if v.is_equal_approx(vertices[c]):
				found = true
				if first < 0:
					first = c
				#print("found: ",i,",",c)
				if not linked_vertices.has(c):
					linked_vertices[c] = []
				linked_vertices[c].push_back(vertices_start+i)
				break
		if not found:
			missing.push_back(i)
	for i in missing:
		#print("missing: ",i)
		linked_vertices[first].push_back(vertices_start+i)


func load_vam_data(vam_file: FileAccess,max_vertices: int)-> Dictionary:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var unused_indexes := {}
	
	for i in max_vertices:
		unused_indexes[i] = 0
	
	var gen_vertices := PackedVector3Array()
	var gen_normals := PackedVector3Array()
	var gen_vertices_map := {}
	var gen_indices := PackedInt32Array()
	var gen_uvs := PackedVector2Array()
	var gen_materials := PackedInt32Array()
	
	var material := -1
	var material_name : String
	while not vam_file.eof_reached():
		var line : String = vam_file.get_line()
		if line.begins_with("v "):
			var floats : PackedFloat64Array = line.substr(2).split_floats(" ")
			if floats.size() >= 3:
				vertices.push_back(Vector3(floats[0],floats[1],floats[2]))
		if line.begins_with("vn "):
			var floats : PackedFloat64Array = line.substr(3).split_floats(" ")
			if floats.size() >= 3:
				normals.push_back(Vector3(floats[0],floats[1],floats[2]).normalized())
		if line.begins_with("vt "):
			var floats : PackedFloat64Array = line.substr(3).split_floats(" ")
			if floats.size() >= 2:
				uvs.push_back(Vector2(floats[0],1-floats[1]))
		if line.begins_with("usemtl "):
			material += 1
			material_name = line.substr(7)
		if line.begins_with("f "):
			var values : PackedStringArray = line.substr(2).split(" ")
			if values.size() > 3:
				print("Out of size line: ",line)
			if values.size() >= 3:				
				var v1 := int(values[2].get_slice("/",0))-1
				var v2 := int(values[1].get_slice("/",0))-1
				var v3 := int(values[0].get_slice("/",0))-1
				
				if unused_indexes.has(v1): unused_indexes.erase(v1)
				if unused_indexes.has(v2): unused_indexes.erase(v2)
				if unused_indexes.has(v3): unused_indexes.erase(v3)
				
				if material_name == "defaultMat":
					if not gen_vertices_map.has(v1):
						gen_vertices_map[v1] = gen_vertices.size()
						gen_vertices.push_back(vertices[v1])
						gen_normals.push_back(normals[v1])
						gen_uvs.push_back(uvs[v1])
					if not gen_vertices_map.has(v2):
						gen_vertices_map[v2] = gen_vertices.size()
						gen_vertices.push_back(vertices[v2])
						gen_normals.push_back(normals[v2])
						gen_uvs.push_back(uvs[v2])
					if not gen_vertices_map.has(v3):
						gen_vertices_map[v3] = gen_vertices.size()
						gen_vertices.push_back(vertices[v3])
						gen_normals.push_back(normals[v3])
						gen_uvs.push_back(uvs[v3])
					
					gen_indices.push_back(gen_vertices_map[v1])
					gen_indices.push_back(gen_vertices_map[v2])
					gen_indices.push_back(gen_vertices_map[v3])
					
					gen_materials.push_back(30)
	
	print("gen_vertices: ",gen_vertices.size())
	print("gen_indices: ",gen_indices.size())
	print("gen_materials: ",gen_materials.size())
	
	return {
		"vertices" : vertices,
		"normals" : normals,
		"uvs" : uvs,
		"unused" : unused_indexes,
		"gen_vertices" : gen_vertices,
		"gen_normals" : gen_normals,
		"gen_indices" : gen_indices,
		"gen_uvs" : gen_uvs,
		"gen_materials" : gen_materials,		
	}


func replace_extra_uv_indices(vertices: PackedVector3Array,normals: PackedVector3Array,uvs: PackedVector2Array,linked_vertices: Dictionary,polylist: Array,extra_uvs: Array,extra_uvs_values: PackedVector2Array,extra_uvs_start: int):
	for e in extra_uvs:
		var idx : int = e[1]
		var p : Array = polylist[e[0]]
		for i in p.size()-2:
			if p[2+i] == idx:
				p[2+i] = vertices.size()
				vertices.push_back(vertices[idx])
				normals.push_back(normals[idx])
				uvs.push_back(extra_uvs_values[e[2]-extra_uvs_start])
				if not linked_vertices.has(idx):
					linked_vertices[idx] = []
				linked_vertices[idx].push_back(p[2+i])


func create_skeleton(bones : Array) -> Skeleton3D:
	var skeleton : Skeleton3D = Skeleton3D.new()
	var bones_idx : Dictionary = {}
	var bones_origins : Dictionary = {}
	var bones_orientations : Dictionary = {}
	
	for b : Dictionary in bones:
		var name : String = b["name"]
		var idx : int = skeleton.add_bone(name)
		var origin : Vector3 = b["origin"]
		var orientation : Vector3 = b["orientation"]

		if b.has("parent"):
			skeleton.set_bone_parent(idx,bones_idx[b["parent"]])
			origin -= bones_origins[b["parent"]]
			orientation -= bones_orientations[b["parent"]]
		bones_idx[name] = idx
		bones_origins[name] = b["origin"]
		bones_orientations[name] = b["orientation"]
		
		var basis : Basis = Basis.from_euler(orientation)
		var transform : Transform3D = Transform3D(basis,origin) 		
		skeleton.set_bone_rest(idx,transform)
		skeleton.set_bone_enabled(idx,false)
	return skeleton


func generate_extra_uvs(indices : PackedInt32Array,extra_uvs : Array,polylist : Array) -> PackedInt32Array:
	var extra : PackedInt32Array
	for e in extra_uvs:
		var p : Array = polylist[e[0]]
		if p.size() > 6:
			var idx = p[6]
			for i in 3:
				if indices[idx+i] == e[1]:
					extra.push_back(idx+i)
					extra.push_back(e[2])
		if p.size() > 7:
			var idx = p[7]
			for i in 3:
				if indices[idx+i] == e[1]:
					extra.push_back(idx+i)
					extra.push_back(e[2])
	return extra


func get_as_bones_array(data,bones_name : String,weights_name : String) -> Array:
	var nodes = data[bones_name]
	var weights = data[weights_name]
	if nodes:
		var bones : Array
		for b : Dictionary in nodes:
			var type : String = b["type"]
			if type == "figure" or type == "bone":
			#if type == "bone":
				var bone : Dictionary
				bone["name"] = b["id"]
				if b.has("parent"):# and b["parent"] != "#GenesisFemale":
					bone["parent"] = b["parent"].replace("#","")

				bone["origin"] = get_vector_from_data(b,"center_point")
				bone["end"] = get_vector_from_data(b,"end_point")
				bone["orientation"] = get_vector_from_data(b,"orientation")
				bone["rotation"] = get_vector_from_data(b,"rotation")
				bone["translation"] = get_vector_from_data(b,"translation")
				bone["weights"] = get_bone_weights(bone["name"],weights)

				bones.append(bone)
		return bones
	return []


func get_bone_weights(bone_name: String,weights: Array) -> Dictionary:
	var bone_weights : Dictionary
	bone_weights["x"] = Array()
	bone_weights["y"] = Array()
	bone_weights["z"] = Array()
	bone_weights["s"] = Array()
	
	var joints = weights[0]["skin"]["joints"]
	if joints:
		for w in joints:
			if w["node"] == "#"+bone_name:
				var values = w["local_weights"]["x"]["values"]
				for v in values:
					bone_weights["x"].push_back(v)
				values = w["local_weights"]["y"]["values"]
				for v in values:
					bone_weights["y"].push_back(v)
				values = w["local_weights"]["z"]["values"]
				for v in values:
					bone_weights["z"].push_back(v)
				values = w["scale_weights"]["values"]
				for v in values:
					bone_weights["s"].push_back(v)
	return bone_weights


func get_vector_from_data(data : Dictionary,name : String) -> Vector3:
	var value : Vector3
	var vector_data = data[name]
	for v in vector_data:
		if v["id"] == "x":
			value.x = v["value"] / 100.0
		elif v["id"] == "y":
			value.y = v["value"] / 100.0
		elif v["id"] == "z":
			value.z = v["value"] / 100.0
	return value


func get_as_vertices_array(data,path : String) -> PackedVector3Array:
	var splits := path.split("/")
	if splits.size() == 1:
		data = data[path]
		if data:
			var values = data["values"]
			var vertices : PackedVector3Array
			for i in values:
				vertices.push_back(Vector3(i[0]/100.0, i[1]/100.0, i[2]/100.0))
			return vertices
		return []
	else:
		return get_as_vertices_array(data[splits[0]][0],path.substr(splits[0].length()+1))


func get_as_indexes_array(data,path : String,unused_indices: Dictionary) -> PackedInt32Array:
	var splits := path.split("/")
	if splits.size() == 1:
		data = data[path]
		if data:
			var indeces = PackedInt32Array()
			var arr = data["values"]
			for i : PackedInt32Array in arr:
				if (unused_indices.has(i[4]) or 
					unused_indices.has(i[3]) or
					unused_indices.has(i[2])):
					indeces.push_back(0)
					indeces.push_back(0)
					indeces.push_back(0)
				else:
					indeces.push_back(i[4])
					indeces.push_back(i[3])
					indeces.push_back(i[2])
				if i.size() > 5 and i[5] >= 0:
					if (unused_indices.has(i[2]) or 
						unused_indices.has(i[5]) or
						unused_indices.has(i[4])):
						indeces.push_back(0)
						indeces.push_back(0)
						indeces.push_back(0)
					else:
						indeces.push_back(i[2])
						indeces.push_back(i[5])
						indeces.push_back(i[4])
			return indeces
		return []
	else:
		return get_as_indexes_array(data[splits[0]][0],path.substr(splits[0].length()+1),unused_indices)


func get_as_uvs_array(data,path : String) -> PackedVector2Array:
	var splits := path.split("/")
	if splits.size() == 1:
		data = data[path][0]
		if data:
			var uvs = PackedVector2Array()
			var arr = data["uvs"]["values"]
			for i in arr:
				uvs.push_back(Vector2(i[0], 1-i[1]))
			return uvs
		return []
	else:
		return get_as_uvs_array(data[splits[0]][0],path.substr(splits[0].length()+1))


func get_as_extra_uvs_array(data,path : String) -> Array:
	var splits := path.split("/")
	if splits.size() == 1:
		data = data[path][0]
		if data:
			var extras = Array()
			var arr = data["polygon_vertex_indices"]
			for i in arr:
				var array := PackedInt32Array()
				array.push_back(i[0])
				array.push_back(i[1])
				array.push_back(i[2])
				extras.push_back(array)
			return extras
		return []
	else:
		return get_as_extra_uvs_array(data[splits[0]][0],path.substr(splits[0].length()+1))


func get_as_groups_array(data,path : String) -> PackedInt32Array:
	var splits := path.split("/")
	if splits.size() == 1:
		data = data[path]
		if data:
			var indexes = PackedInt32Array()
			var arr = data["values"]
			for i in arr:
				indexes.push_back(i[0])
				if i.size() > 5:
					indexes.push_back(i[0])
			return indexes
		return []
	else:
		return get_as_groups_array(data[splits[0]][0],path.substr(splits[0].length()+1))


func get_as_materials_array(data,path : String) -> PackedInt32Array:
	var splits := path.split("/")
	if splits.size() == 1:
		data = data[path]
		if data:
			var indexes = PackedInt32Array()
			var arr = data["values"]
			for i in arr:
				if i[1] == 13:
					if i[0] == 4: # Left eye
						indexes.push_back(28)
						if i.size() > 5:
							indexes.push_back(28)
					elif i[0] == 5: # Right eye
						indexes.push_back(29)
						if i.size() > 5:
							indexes.push_back(29)
				else:
					indexes.push_back(i[1])
					if i.size() > 5:
						indexes.push_back(i[1])
			return indexes
		return []
	else:
		return get_as_materials_array(data[splits[0]][0],path.substr(splits[0].length()+1))
