@tool
class_name VAMCloth extends MeshInstanceEx

@export_tool_button("Generate","Reload") var generate = debug_generate_mesh

@export var material : StandardMaterial3D

var _daz_model : Daz3DMesh = load("res://modules/VAMActor/resources/Genesis2Female.dsf")
var _cloth_thread : Thread

const BONES_NUMBER := 8

# Debug
var _library : LibraryManager


func _ready() -> void:
	if Engine.is_editor_hint():
		debug_generate_mesh()


func _validate_property(property: Dictionary):
	if ["mesh"].has(property["name"]):
		property["usage"] = PROPERTY_USAGE_EDITOR


func debug_generate_mesh():
	if not _library:
		_library = LibraryManager.new()
		#_library.LoadData("/mnt/data/Games/Virtamate/AddonPackages/")
		_library.LoadData("/mnt/data/Projects/Godot/library/")
	load_mesh(_library,2,3)


func load_cloth(library: LibraryManager,look_id: int,cloth_id: int):
	load_mesh(library,look_id,cloth_id)


func load_cloth_async(library: LibraryManager,look_id: int,cloth_id: int):
	if _cloth_thread:
		_cloth_thread.wait_to_finish()
	else:
		_cloth_thread = Thread.new()
	_cloth_thread.start(load_cloth.bind(library,look_id,cloth_id))


func load_mesh(library: LibraryManager,morph_id: int,cloth_id: int):
	var data : Dictionary = library.Clothes_GetClothMeshData(cloth_id);
	if data:
		var meshData : Dictionary = data["meshData"]
		
		if meshData and meshData.size() >= 4:
			var vertices : PackedVector3Array = meshData["vertices"]
			var surfaces : Array = meshData["surfaces"]
			var uvs : PackedVector2Array = meshData["uvs"]
			var skin_wraps : Array = meshData["skin_wraps"]
			
			var materials : Dictionary = data["materials"]
			var materials_id : Array = meshData["materials_id"]
			var mesh_materials : Array = generate_materials(library,cloth_id,materials,materials_id)
			
			var max_index : int = 21556 # Vartices in the base Genesis 2 model
			var bones := PackedInt32Array()
			var weights := PackedFloat32Array()
			
			var model_vertices = _daz_model.vertices
			var model_linkeds = _daz_model.linked_vertices
			var model_weights = _daz_model.weights
			
			weights_padding(model_weights)
			
			#var linkeds : Dictionary = {}
			#for k in model_linkeds.keys():
				#for v in model_linkeds[k]:
					#linkeds[v] = k
			
			var surfaceOffset := 0.0003
			var morph_vertices := {}
			for w in vertices.size():
				var wrap : Dictionary = skin_wraps[w]
				
				var v1 : int = wrap["v1"]
				#var v2 : int = wrap["v2"]
				#var v3 : int = wrap["v3"]
				#
				#var p1 = model_vertices[v1]
				#var p2 = model_vertices[v2]
				#var p3 = model_vertices[v3]
				#
				#var edge1 = p2 - p1
				#var edge2 = p3 - p1
				#var body_normal = edge1.cross(edge2).normalized()    # La perpendicolare alla pelle
				#
				#var np = wrap["np"] / 100.0
				#var t1p = wrap["t1p"] / 100.0
				#var t2p = wrap["t2p"] / 100.0
#
				#var nw = wrap["nw"] / 100.0
				#var t1w = wrap["t1w"] / 100.0
				#var t2w = wrap["t2w"] / 100.0
#
				#var center : Vector3 = (p1 + p2 + p3) * 0.33333;
				#var vector3 : Vector3 = (center - p1) * 1;
				#var vector5 : Vector3 = vector3.cross(body_normal)
				#var offset = p1 + vector3 * (t1p + t1w) + vector5 * (t2p + t2w) + body_normal * (np + surfaceOffset + nw)
				
				#if w < 10:
					#prints(np,nw)
				#vertices[w] = vertices[w] + offset
				
				# "Temporary" hack
				if v1 > max_index:
					v1 = model_vertices.size()-1
				
				for bone in BONES_NUMBER:
					bones.push_back(model_weights[v1]["s"][bone*2])
					weights.push_back(model_weights[v1]["s"][bone*2+1])
				
				if not morph_vertices.has(v1):
					morph_vertices[v1] = []
				morph_vertices[v1].push_back(w)
				
			if library and morph_id >= 0:
				var morphs : Array = library.Looks_GetMorphs(morph_id)
				for morph in morphs:
					if morph["type"] != "genitalia":
						var value : float =  morph["value"]
						apply_deltas(morph_vertices,vertices,{},morph["meshData"],value)
			
			var new_mesh = create_mesh_surfaces(vertices,surfaces,uvs,bones,weights,mesh_materials,8)
			
			call_deferred("set_mesh_safe",new_mesh)


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
		#if linked_vertices.has(deltaID):
			#for c in linked_vertices[deltaID]:
				#vertices[c] += deltas[i].delta*value
		else:
			#push_warning("Delta ID too high: ",deltaID)
			continue


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
