# vam_obj_plugin.gd
@tool
extends EditorImportPlugin


func _get_importer_name():
	return "mb.vam_obj"


func _get_visible_name():
	return "VAM obj mesh import"	


func _get_recognized_extensions():
	return ["vam"]


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
	if not file:
		return FileAccess.get_open_error()
	
	print("VAM mesh import plugin: ",source_file)
	
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var materials := PackedInt32Array()
	
	var material = -1
	while not file.eof_reached():
		var line : String = file.get_line()
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
		if line.begins_with("f "):
			var values : PackedStringArray = line.substr(2).split(" ")
			if values.size() >= 3:
				if values.size() > 3:
					print(line)
				
				var v1 := int(values[2].get_slice("/",0))-1
				var v2 := int(values[1].get_slice("/",0))-1
				var v3 := int(values[0].get_slice("/",0))-1
				
				if (v1 < vertices.size() and v2 < vertices.size() and v3 < vertices.size()):
					indices.push_back(v1)
					indices.push_back(v2)
					indices.push_back(v3)
					
					materials.push_back(material if material >= 0 else 0)
				
				#if v1 != int(values[2].get_slice("/",1))-1:
					#print("TEX different")
				#if v2 != int(values[1].get_slice("/",1))-1:
					#print("TEX different")
				#if v3 != int(values[0].get_slice("/",1))-1:
					#print("TEX different")
				#if v1 != int(values[2].get_slice("/",2))-1:
					#print("TEX different")
				#if v2 != int(values[1].get_slice("/",2))-1:
					#print("TEX different")
				#if v3 != int(values[0].get_slice("/",2))-1:
					#print("TEX different")
	
	var vam_mesh : VAMOBJMesh = VAMOBJMesh .new()
	vam_mesh.vertices = vertices
	vam_mesh.indeces = indices
	vam_mesh.normals = normals
	vam_mesh.materials = materials
	vam_mesh.uvs = uvs
	
	return ResourceSaver.save(vam_mesh, "%s.%s" % [save_path, _get_save_extension()])
