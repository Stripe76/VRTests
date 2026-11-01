@tool
class_name VAMCloth extends MeshInstanceEx

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
	load_mesh(_library,2,3)


func load_cloth(library: LibraryManager,look_id: int,cloth_id: int):
	load_mesh(library,look_id,cloth_id)


func load_mesh(library: LibraryManager,morph_id: int,cloth_id: int):
	var data : Dictionary = library.Clothes_GetClothMeshData(cloth_id);
	if data:
		var meshData : Dictionary = data["meshData"]
		
		if meshData and meshData.size() >= 4:
			var vertices : PackedVector3Array = meshData["vertices"]
			var surfaces : Array = meshData["surfaces"]
			var uvs : PackedVector2Array = meshData["uvs"]
			var skin_indices : PackedInt32Array = meshData["skin_indices"]
			
			var materials : Dictionary = data["materials"]
			var materials_id : Array = meshData["materials_id"]
			var mesh_materials : Array = generate_materials(library,cloth_id,materials,materials_id)
			
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
					
			#if library and morph_id >= 0:
				#prints("morph_vertices",morph_vertices.size())
				#var morphs : Array = library.Looks_GetMorphs(morph_id)
				#for morph in morphs:
					#if morph["type"] != "genitalia":
						##print("Applying body deltas: ",morph["meshFile"])
						#var value : float =  morph["value"]
						#apply_deltas(morph_vertices,vertices,{},morph["meshData"],value)
			
			mesh = create_mesh_surfaces(vertices,surfaces,uvs,bones,weights,mesh_materials,8)


func generate_materials(library: LibraryManager,cloth_id: int,materials: Dictionary,materials_id: Array ) -> Array:
	var std_materials : Array = []
	for m in materials_id:
		if materials.has(m):
			var mat : Dictionary = materials[m]
			var std : StandardMaterial3D = StandardMaterial3D.new()
			var image = library.Clothes_GetTextureImage(cloth_id,mat["main_texture"])
			if not image.is_empty():
				std.albedo_texture = ImageTexture.create_from_image(image)
			if mat.has("diffuse_color"):
				std.albedo_color = mat["diffuse_color"]
			if mat.has("tile_x") and mat.has("tile_y"):
				std.uv1_scale = Vector3(mat["tile_x"],mat["tile_y"],1)
			std_materials.push_back(std)
	return std_materials


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
