@tool
class_name VAMCloth extends MeshInstance3D

@export_tool_button("Generate","Reload") var generate = debug_generate_mesh

@export var path : String = "/mnt/data/Projects/Godot/library/"
@export var file_name : String = "_sweater.vab"

@export var material : StandardMaterial3D

var _daz_model : Daz3DMesh = load("res://modules/VAMActor/resources/Genesis2Female.dsf")

const BONES_NUMBER := 8

# Debug
var _library : LibraryManager


func _ready() -> void:
	if Engine.is_editor_hint():
		debug_generate_mesh()


func _validate_property(property: Dictionary):
	if ["mesh",].has(property["name"]):
		property["usage"] = PROPERTY_USAGE_EDITOR


func debug_generate_mesh():
	if not _library:
		_library = LibraryManager.new()
		#_library.LoadData("/mnt/data/Games/Virtamate/AddonPackages/")
		_library.LoadData("/mnt/data/Projects/Godot/library/")
	load_mesh_new(_library,2,3)


func load_cloth(library: LibraryManager,look_id: int,cloth_id: int):
	load_mesh_new(library,look_id,cloth_id)


func load_mesh_new(library: LibraryManager,morph_id: int,cloth_id: int):
	var data : Dictionary = library.Clothes_GetClothMeshData(cloth_id);
	if data:
		var meshData : Dictionary = data["meshData"]
		
		if meshData and meshData.size() >= 4:
			var vertices : PackedVector3Array = meshData["vertices"]
			var indices : PackedInt32Array = meshData["indices"]
			var uvs : PackedVector2Array = meshData["uvs"]
			var skin_indices : PackedInt32Array = meshData["skin_indices"]
			
			var max_index : int = 21556 # Vartices in the base Genesis 2 model
			var bones := PackedInt32Array()
			var weights := PackedFloat32Array()
			
			var model_weights = _daz_model.weights
			weights_padding(model_weights)
			
			var morph_vertices := {}
			for skn in vertices.size():
				var a := skin_indices[skn*4]
				var b := skin_indices[skn*4+1]
				var c := skin_indices[skn*4+2]
				var d := skin_indices[skn*4+3]
				
				var index : int = -1
				if a < max_index:index = a
				elif b < max_index:index = b
				elif c < max_index:index = c
				elif d < max_index:index = d
				
				if index < max_index:
					for bone in BONES_NUMBER:
						bones.push_back(model_weights[index]["s"][bone*2])
						weights.push_back(model_weights[index]["s"][bone*2+1])
						
					if not morph_vertices.has(index):
						morph_vertices[index] = []
					morph_vertices[index].push_back(skn)
					
			if library and morph_id >= 0:
				prints("morph_vertices",morph_vertices.size())
				var morphs : Array = library.Looks_GetMorphs(morph_id)
				for morph in morphs:
					if morph["type"] != "genitalia":
						#print("Applying body deltas: ",morph["meshFile"])
						var value : float =  morph["value"]
						apply_deltas(morph_vertices,vertices,{},morph["meshData"],value)
			
			var surface_tool := SurfaceTool.new()
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_INDEX] = indices
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_BONES] = bones
			arrays[Mesh.ARRAY_WEIGHTS] = weights
			arrays[Mesh.ARRAY_TEX_UV] = uvs
			
			surface_tool.create_from_arrays(arrays,Mesh.PRIMITIVE_TRIANGLES)
			surface_tool.generate_normals()
			surface_tool.generate_tangents()
			surface_tool.set_skin_weight_count(SurfaceTool.SKIN_8_WEIGHTS)
			
			mesh = surface_tool.commit()

			var materials : Dictionary = data["materials"]
			if materials:
				var first_material = materials.values()[0]
				
				if first_material.has("main_tex"):
					var image = library.Clothes_GetTextureImage(cloth_id,first_material["main_tex"])
					material.albedo_texture = ImageTexture.create_from_image(image)
			
			set_surface_override_material(0,material)


func load_mesh(library: LibraryManager,morph_id: int,filename: String):
	var file := FileAccess.open(filename,FileAccess.READ)
	if file:
		skip_strings(file,8)
		
		var vertices_count := file.get_32()
		prints("Vertices:",vertices_count)
		
		var vertices : PackedVector3Array = []
		for v in vertices_count:
			var x = file.get_float()
			var y = file.get_float()
			var z = file.get_float()
			
			vertices.push_back(Vector3(-x,y,z))
		
		skip_strings(file)

		var indices_count = file.get_32()
		prints("Indices",indices_count)

		var mx : int = 0
		var indices : PackedInt32Array = []
		for v in indices_count:
			file.get_32()
			file.get_32()
			var c = file.get_32()
			var d = file.get_32()
			var e = file.get_32()
			var f = file.get_32()
			
			indices.push_back(c)
			indices.push_back(e)
			indices.push_back(d)
			
			indices.push_back(f)
			indices.push_back(e)
			indices.push_back(c)
			
			mx = max(mx,c,d,e,f)
		prints("Max",mx)
		
		#return
		mx = 0
		for v in indices_count:
			file.get_32()
			file.get_32()
			var c = file.get_32()
			var d = file.get_32()
			var e = file.get_32()
			var f = file.get_32()
		
			mx = max(mx,c,d,e,f)
		prints("Max2",mx)
		
		var uv_count = file.get_32()
		prints("UVs",uv_count)
		
		var uvs : PackedVector2Array = []
		for d in vertices_count:
			var u = file.get_float()
			var v = file.get_float()
			
			uvs.push_back(Vector2(u,-v))
		for d in uv_count-vertices_count:
			file.get_float()
			file.get_float()
		
		#var l = file.get_32()
		for d in file.get_32():
			file.get_32()
			file.get_32()
			file.get_32()
		
		skip_strings(file,5)
		
		var max_index : int = 21556 # Vartices in the base Genesis 2 model
		var skn_number = file.get_32()
		var debug_vertices := PackedVector3Array()
		
		var bones := PackedInt32Array()
		var weights := PackedFloat32Array()
		
		var model_weights = _daz_model.weights
		weights_padding(model_weights)
		
		var morph_vertices := {}
		
		var last_valid_index := -1
		prints("Skins",skn_number)
		for skn in vertices_count:
			var a := file.get_32()
			var b := file.get_32()
			var c := file.get_32()
			var d := file.get_32()
			
			var wa := file.get_float()
			var wb := file.get_float()
			var wc := file.get_float()
			var wd := file.get_float()
			
			var index : int = -1
			if a < max_index:index = a
			elif b < max_index:index = b
			elif c < max_index:index = c
			elif d < max_index:index = d
			
			if index < max_index:
				for bone in BONES_NUMBER:
					bones.push_back(model_weights[index]["s"][bone*2])
					weights.push_back(model_weights[index]["s"][bone*2+1])
					
				if not morph_vertices.has(index):
					morph_vertices[index] = []
				morph_vertices[index].push_back(skn)
			
			file.get_float()
			file.get_float()
		
		if library and morph_id >= 0:
			prints("morph_vertices",morph_vertices.size())
			var morphs : Array = library.Looks_GetMorphs(morph_id)
			for morph in morphs:
				if morph["type"] != "genitalia":
					#print("Applying body deltas: ",morph["meshFile"])
					var value : float =  morph["value"]
					apply_deltas(morph_vertices,vertices,{},morph["meshData"],value)
		
		
		var surface_tool := SurfaceTool.new()
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_INDEX] = indices
		arrays[Mesh.ARRAY_VERTEX] = vertices
		#arrays[Mesh.ARRAY_NORMAL] = arrays_data["Normals"]
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
		#arrays[Mesh.ARRAY_COLOR] = arrays_data["Colors"]
		#arrays[Mesh.ARRAY_CUSTOM0] = arrays_data["Customs0"]
		#arrays[Mesh.ARRAY_CUSTOM1] = arrays_data["Customs1"]
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		
		surface_tool.create_from_arrays(arrays,Mesh.PRIMITIVE_TRIANGLES)
		
		surface_tool.generate_normals()
		surface_tool.generate_tangents()
		
		surface_tool.set_skin_weight_count(SurfaceTool.SKIN_8_WEIGHTS)
		
		mesh = surface_tool.commit()
		
		set_surface_override_material(0,material)
		
		if Engine.is_editor_hint() and false:
			surface_tool = SurfaceTool.new()
			arrays = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = debug_vertices
			
			surface_tool.create_from_arrays(arrays,Mesh.PRIMITIVE_POINTS)
			
			$DebugMesh.mesh = surface_tool.commit()


func apply_deltas(morph_vertices: Dictionary,vertices: PackedVector3Array,linked_vertices: Dictionary,deltas: Array,value: float):
	for d in deltas:
		var deltaID = d["id"]
		if morph_vertices.has(deltaID):
			for i in morph_vertices[deltaID]:
				#prints(deltaID,":",i)
				vertices[i] += d["delta"] * value
		else:
			#push_warning("Delta ID too high: ",deltaID)
			continue


func skip_strings(file: FileAccess,how_many: int = 0):
	if how_many == 0:
		how_many = file.get_32()
	for i in how_many:
		#var n = file.get_8()
		var s = file.get_buffer(file.get_8())
		prints(" - ",s.get_string_from_ascii())


func weights_padding(model_weights: Array):
	for x in model_weights:
		for c in 8-x["x"].size()/2:
			x["x"].push_back(0)
			x["x"].push_back(0.0)
		for c in 8-x["y"].size()/2:
			x["y"].push_back(0)
			x["y"].push_back(0.0)
		for c in 8-x["z"].size()/2:
			x["z"].push_back(0)
			x["z"].push_back(0.0)
		for c in 8-x["s"].size()/2:
			x["s"].push_back(0)
			x["s"].push_back(0.0)
