@tool
class_name VAMMesh
extends MeshInstance3D

@export_group("Meshes")
@export var full_body : Mesh
@export var left_eye : Mesh
@export var right_eye : Mesh

@export_group("Materials")
@export var head_material := ShaderMaterial.new()
@export var body_material := ShaderMaterial.new()
@export var limbs_material := ShaderMaterial.new()
@export var eyes_material := Material.new()
@export var genitals_material := ShaderMaterial.new()
@export var hair_material := Material.new()

@export_group("Surfaces")
var mesh_surfaces : Array

enum {MESH_BODY = 0, MESH_LEFT_EYE = 1, MESH_RIGHT_EYE = 2}
enum {MATERIAL_HEAD = 0, MATERIAL_BODY = 1, MATERIAL_LIMBS = 2, MATERIAL_GENITALS = 3, MATERIAL_LEFT_EYE = 4, MATERIAL_RIGHT_EYE = 5, MATERIAL_OTHER = -1}


func _ready() -> void:
	var SKIN_SHADER = load("res://modules/VAMActor/shaders/skin.gdshader")
	#var SKIN_SHADER : Shader = load("res://modules/VAMActor/shaders/human_shaders/skin_shader.gdshader")	
	#var EYES_SHADER = load("res://modules/VAMActor/shaders/digital_human/shaders/eye_colorized.gdshader")
	
	head_material.shader = SKIN_SHADER
	body_material.shader = SKIN_SHADER
	limbs_material.shader = SKIN_SHADER
	genitals_material.shader = SKIN_SHADER
	
	head_material.set_shader_parameter("use_micro_detail",true)
	head_material.set_shader_parameter("use_ambient_occlusion",true)
	#head_material.set_shader_parameter("use_noise",false)

	if Engine.is_editor_hint() and false:
		var base_model := load("res://modules/VAMActor/resources/Genesis2Female.dsf")
		var genitals_model := load("res://modules/VAMActor/resources/female_genitals.res")
	
		load_mesh(base_model,genitals_model,"/mnt/data/Projects/Godot/library/Anita/","Saves/scene/Anita.json")
		self.mesh = full_body
		load_materials("/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Anita/","Saves/scene/Anita.json")


func _validate_property(property: Dictionary):
	#print(property["name"])
	if ["mesh","head_material","body_material","limbs_material","eyes_material","genitals_material","hair_material"].has(property["name"]):
		property["usage"] = PROPERTY_USAGE_EDITOR


func load_mesh(base_model: Daz3DMesh,genitals_model: Mesh,vam_scene_folder: String,vam_scene_file: String):
	if not base_model:
		return
	var model_vertices : PackedVector3Array = base_model.vertices.duplicate()
	var model_normals : PackedVector3Array = base_model.normals
	var model_indices : Array = base_model.indeces
	var model_uvs : PackedVector2Array = base_model.uvs
	var model_weights : Array = base_model.weights
	var model_linked : Dictionary = base_model.linked_vertices
	
	if vam_scene_file != "":
		print("Scene loading",)
		var file := FileAccess.open(vam_scene_folder+vam_scene_file,FileAccess.READ)
		if file:
			var scene_data : Dictionary = JSON.parse_string(file.get_as_text())
			if scene_data:
				print("Morphs application",)
				add_morphs(model_vertices,model_linked,scene_data,vam_scene_folder)
	
	print("Weights padding")
	weights_padding(model_weights)
	
	print("Meshes creation")
	var meshes : Array = create_meshes(base_model,genitals_model,model_vertices,model_normals,model_indices,model_uvs,model_weights)
	
	print("Materials settings")
	set_materials(meshes[MESH_BODY])
	
	full_body = meshes[MESH_BODY]
	left_eye  = meshes[MESH_LEFT_EYE]
	right_eye = meshes[MESH_RIGHT_EYE]


func load_materials(library_folder: String,vam_scene_folder: String,vam_scene_file: String):
	if self.mesh and vam_scene_file != "" || true:
		var file := FileAccess.open(vam_scene_folder+vam_scene_file,FileAccess.READ)
		if file:
			var scene_data : Dictionary = JSON.parse_string(file.get_as_text())
			if scene_data:
				print("Textures loading")
				var textures = load_textures(scene_data,library_folder,vam_scene_folder)
	
				textures["faceMicroDetailUrl"] = "/mnt/data/Projects/Godot/VRTests/modules/VAMActor/shaders/human_shaders/Resources/MicroDetail/skin_micro_nrm_ao.png"
	
				print("Material textures setting")
				set_materials_textures(self.mesh,textures)	


func set_materials(mesh: ArrayMesh)-> void:
	mesh.surface_set_material(MATERIAL_HEAD,head_material)
	mesh.surface_set_material(MATERIAL_BODY,body_material)
	mesh.surface_set_material(MATERIAL_LIMBS,limbs_material)
	mesh.surface_set_material(MATERIAL_GENITALS,genitals_material)


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


func set_weight_pixel( bones: Image,weights: Image,w: Array,i: int,o: int):
	bones.set_pixel(i,o,Color(w[0]/255.0,w[2]/255.0,w[4]/255.0,w[6])/255.0)
	bones.set_pixel(i,o+1,Color(w[8]/255.0,w[10]/255.0,w[12]/255.0,w[14]/255.0))
	
	weights.set_pixel(i,o,Color(w[1],w[3],w[5],w[7]))
	weights.set_pixel(i,o+1,Color(w[9],w[11],w[13],w[15]))


func set_weights(model_weights: Array):
	var bones := Image.create(model_weights.size(),8,false,Image.FORMAT_RGBAF)
	var weights := Image.create(model_weights.size(),8,false,Image.FORMAT_RGBAF)
	
	var i := 0
	for w in model_weights:
		set_weight_pixel(bones,weights,w["s"],i,0)
		set_weight_pixel(bones,weights,w["x"],i,2)
		set_weight_pixel(bones,weights,w["y"],i,4)
		set_weight_pixel(bones,weights,w["z"],i,6)	
		i += 1
	
	var bones_tex := ImageTexture.create_from_image(bones)
	var weight_tex := ImageTexture.create_from_image(weights)
	
	limbs_material.set_shader_parameter("bones",bones_tex)
	limbs_material.set_shader_parameter("weights",weight_tex)
	
	#body_material.set_shader_parameter("x_bones",ImageTexture.create_from_image(bones))
	#body_material.set_shader_parameter("x_weights",ImageTexture.create_from_image(weights))


func create_meshes(daz_model: Daz3DMesh,genitals_model: Mesh,model_vertices: PackedVector3Array,model_normals: PackedVector3Array,model_indices: Array,model_uvs: PackedVector2Array,model_weights: Array) -> Array:
	#var full_mesh_normals := generate_normals(daz_model,model_vertices,model_indices,model_uvs,model_weights)
	
	var surfaces := []
	for i in 6:
		surfaces.push_back({ 
			"vertices" : PackedVector3Array(),
			"indices" : PackedInt32Array(),
			"normals" : PackedVector3Array(),
			"uvs" : PackedVector2Array(),
			"bones" : PackedInt32Array(),
			"weights" : PackedFloat32Array(),
			"colors" : PackedColorArray(),
			} )
	
	var tris : int = 0
	var actual_tris : int = 0
	var bones_number := 8
	for material in daz_model.materials:
		var map : int = map_material(material)
		if map >= 0 and map < surfaces.size():
			var surface = surfaces[map]
			var mesh_vertices : PackedVector3Array = surface["vertices"]
			var mesh_normals : PackedVector3Array = surface["normals"]
			var mesh_uvs : PackedVector2Array = surface["uvs"]
			var mesh_bones : PackedInt32Array = surface["bones"]
			var mesh_weights : PackedFloat32Array = surface["weights"]
			var mesh_colors : PackedColorArray = surface["colors"]
			
			var index = model_indices[tris]
	
			mesh_vertices.push_back(model_vertices[index])
			mesh_uvs.push_back(model_uvs[index])
			#mesh_normals.push_back(full_mesh_normals[actual_tris])
			mesh_normals.push_back(model_normals[index])			
			for c in bones_number:
				mesh_bones.push_back(model_weights[index]["s"][c*2])
				mesh_weights.push_back(model_weights[index]["s"][c*2+1])
			
			mesh_colors.push_back(int_to_color(index))
			tris += 1
			actual_tris += 1
		
			index = model_indices[tris]
			mesh_uvs.push_back(model_uvs[index])
			mesh_vertices.push_back(model_vertices[index])
			#mesh_normals.push_back(full_mesh_normals[actual_tris])
			mesh_normals.push_back(model_normals[index])			
			for c in bones_number:
				mesh_bones.push_back(model_weights[index]["s"][c*2])
				mesh_weights.push_back(model_weights[index]["s"][c*2+1])
			
			mesh_colors.push_back(int_to_color(index))
			tris += 1
			actual_tris += 1
		
			index = model_indices[tris]
			mesh_uvs.push_back(model_uvs[index])
			mesh_vertices.push_back(model_vertices[index])
			#mesh_normals.push_back(full_mesh_normals[actual_tris])
			mesh_normals.push_back(model_normals[index])
			for c in bones_number:
				mesh_bones.push_back(model_weights[index]["s"][c*2])
				mesh_weights.push_back(model_weights[index]["s"][c*2+1])
			mesh_colors.push_back(int_to_color(index))
			tris += 1
			actual_tris += 1
		else:
			tris += 3
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var surface_tool = SurfaceTool.new()
	var body_mesh := ProceduralMesh.new()
	var left_eye_mesh := ProceduralMesh.new()
	var right_eye_mesh := ProceduralMesh.new()
	
	for i in surfaces.size():
		var surface = surfaces[i]
		if surface["vertices"].size() > 0:
			arrays[Mesh.ARRAY_VERTEX] = surface["vertices"]
			#arrays[Mesh.ARRAY_INDEX] = surface["indices"]
			arrays[Mesh.ARRAY_NORMAL] = surface["normals"]
			arrays[Mesh.ARRAY_TEX_UV] = surface["uvs"]
			arrays[Mesh.ARRAY_BONES] = surface["bones"]
			arrays[Mesh.ARRAY_WEIGHTS] = surface["weights"]
			#arrays[Mesh.ARRAY_COLOR] = surface["colors"]
			
			var array_mesh := body_mesh
			if i == MATERIAL_LEFT_EYE:
				array_mesh = left_eye_mesh
			elif i == MATERIAL_RIGHT_EYE:
				array_mesh = right_eye_mesh
			
			surface_tool.create_from_arrays(arrays)
			surface_tool.generate_tangents( )
			
			if bones_number == 8:
				surface_tool.set_skin_weight_count(SurfaceTool.SKIN_8_WEIGHTS)
				surface_tool.commit(array_mesh,Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
			else:
				surface_tool.commit(array_mesh)
	
	mesh_surfaces = surfaces
	
	return [body_mesh,left_eye_mesh,right_eye_mesh]


func generate_normals(base_model: Daz3DMesh,model_vertices: PackedVector3Array,model_indices: Array,model_uvs: PackedVector2Array,model_weights: Array) -> PackedVector3Array:
	var surfaces := {}
	var tris : int = 0
	for material in base_model.materials:
		var map : int = map_material(material)
		if map >= 0:
			map = 0
			
			if not surfaces.has(map):
				surfaces[map] = {}
				surfaces[map]["vertexes"] = PackedVector3Array()
				surfaces[map]["uvs"] = PackedVector2Array()
			
			var surface = surfaces[map]
			var mesh_vertices : PackedVector3Array = surface["vertexes"]
			var mesh_uvs : PackedVector2Array = surface["uvs"]
			
			var index = model_indices[tris]
			
			mesh_uvs.push_back(model_uvs[index])
			mesh_vertices.push_back(model_vertices[index])
			tris += 1
		
			index = model_indices[tris]
			mesh_uvs.push_back(model_uvs[index])
			mesh_vertices.push_back(model_vertices[index])
			tris += 1
		
			index = model_indices[tris]
			mesh_uvs.push_back(model_uvs[index])
			mesh_vertices.push_back(model_vertices[index])
			tris += 1
		else:
			tris += 3
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var surface_tool = SurfaceTool.new()
	for key in surfaces.keys():
		var surface = surfaces[key]
		arrays[Mesh.ARRAY_VERTEX] = surface["vertexes"]
		arrays[Mesh.ARRAY_TEX_UV] = surface["uvs"]
		
		surface_tool.create_from_arrays(arrays)
	
	surface_tool.generate_normals( )
	surface_tool.generate_tangents( )
	
	var mesh_arrays := surface_tool.commit_to_arrays()
	
	return mesh_arrays[Mesh.ARRAY_NORMAL]


func int_to_color(value: int) -> Color:
	var color := Color();
	color.r8 = value & 0xFF
	color.g8 = (value >> 8) & 0xFF
	color.b8 = (value >> 16) & 0xFF
	color.a8 = (value >> 24) & 0xFF
	return color


func get_storables(scene_data : Dictionary):
	if scene_data and scene_data.has("atoms"):
		var atoms = scene_data["atoms"]
		for a : Dictionary in atoms:
			if a["id"] == "Person" or a["type"] == "Person" and a.has("storables"):
				return a["storables"]
	
	if scene_data and scene_data.has("storables"):
		return scene_data["storables"]
	
	return null


func add_morphs(vertices : PackedVector3Array,linked_vertices: Dictionary,scene_data: Dictionary,scene_folder: String):
	var storables = get_storables(scene_data)
	if storables:
		for s : Dictionary in storables:
			if s["id"] == "geometry" and s.has("morphs"):
				var morphs = s["morphs"]
				for m in morphs:
					var uid : String = m["uid"]
					if uid.begins_with("SELF:"):
						var path = scene_folder + uid.substr(6)
						var value : float =  m["value"].to_float( )
						if path.contains("genitalia"):
							print("Applying genitals deltas: ",path)
							#apply_deltas(vertices,linked_vertices,read_binary_file(path.replace(".vmi",".vmb")),value,24759)
						else:
							print("Applying body deltas: ",path)
							apply_deltas(vertices,linked_vertices,read_binary_file(path.replace(".vmi",".vmb")),value)


func apply_deltas(vertices: PackedVector3Array, linked_vertices: Dictionary,deltas: Array,value: float,offset: int = 0):
	var mesh_count : int = vertices.size()
	var deltas_count : int = deltas.size()
	
	print(" - Mesh vertices: ",mesh_count)
	print(" - Delta vertices: ",deltas_count)
	
	#deltas_count = 0
	var minID : int = 65535
	var maxID : int = 0
	var linked : int = 0
	
	for i in deltas_count:
		var delta : MeshDelta = deltas[i]
		if delta.id < vertices.size( ):
			vertices[offset+delta.id] += deltas[i].delta*value
			if linked_vertices.has(delta.id):
				for c in linked_vertices[delta.id]:
					vertices[c] += deltas[i].delta*value
					linked += 1
			
			if delta.id < minID: minID = delta.id
			if delta.id > maxID: maxID = delta.id
		else:
			print("Delta ID too high: ",delta.id)
	
	print(" - ID min: ",minID)
	print(" - ID max: ",maxID)
	print(" - Linked: ",linked)


func set_materials_textures(array_mesh: ArrayMesh, textures : Dictionary):
	var enable_decal := true
	#var diffuse := "standard_diffuse"
	#var normal := "standard_normal"
	var decal := "standard_decal"
	var diffuse := "texture_albedo"
	var normal := "texture_normal"
	
	load_material_texture(head_material,textures,"faceDiffuseUrl",diffuse)
	load_material_texture(head_material,textures,"faceNormalUrl",normal)
	if textures.has("faceDecalUrl") && enable_decal:
		load_material_texture(head_material,textures,"faceDecalUrl",decal)
	else:
		load_material_texture(head_material,textures,"white",decal)
	if textures.has("faceMicroDetailUrl"):
		load_material_texture(head_material,textures,"faceMicroDetailUrl","texture_micro_detail")
	
	load_material_texture(body_material,textures,"torsoDiffuseUrl",diffuse)
	load_material_texture(body_material,textures,"torsoNormalUrl",normal)
	if textures.has("torsoDecalUrl") && enable_decal:
		load_material_texture(body_material,textures,"torsoDecalUrl",decal)
	else:
		load_material_texture(body_material,textures,"white",decal)
	
	load_material_texture(limbs_material,textures,"limbsDiffuseUrl",diffuse)
	load_material_texture(limbs_material,textures,"limbsNormalUrl",normal)
	if textures.has("limbsDecalUrl") && enable_decal:
		load_material_texture(limbs_material,textures,"limbsDecalUrl",decal)
	else:
		load_material_texture(limbs_material,textures,"white",decal)
	
	load_material_texture(genitals_material,textures,"genitalsDiffuseUrl",diffuse)
	load_material_texture(genitals_material,textures,"genitalsNormalUrl",normal)
	load_material_texture(genitals_material,textures,"genitalsDiffuseUrl",decal)


func load_material_texture(material: Material,textures : Dictionary,field: String,param_name: String):
	if field == "white":
		material.set_shader_parameter(param_name,ResourceLoader.load("res://modules/VAMActor/resources/white.png"))
	elif textures.has(field):
		var image = Image.load_from_file(textures.get(field))
		material.set_shader_parameter(param_name,ImageTexture.create_from_image(image))


func load_textures(scene_data : Dictionary,library_path : String,scene_path : String) -> Dictionary:
	var storables = get_storables(scene_data)	
	if storables:
		var textures := {}
		for s : Dictionary in storables:
			if s["id"] == "textures":
				for t in s.keys():
					var value : String = s[t]
					if value.begins_with("SELF:"):
						textures[t] = scene_path + value.substr(6)
					else:
						textures[t] = library_path + value.replace(".latest:",".1")
				#textures["white"] = "modules/VAMActor/resources/white.png"
				return textures
	return {}


	#"lShin",
	#"lThigh",
	#"rShin",
	#"rThigh",
	#"lEye",
	#"rEye",
	#"head",
	#"lowerJaw",
	#"upperJaw",
	#"lToe",
	#"rToe",
	#"lMid3",
	#"lPinky3",
	#"lRing3",
	#"lIndex3",
	#"lThumb3",
	#"rMid3",
	#"rPinky3",
	#"rRing3",
	#"rIndex3",
	#"rThumb3",
	#"neck",
	#"lHand",
	#"lThumb1",
	#"lThumb2",
	#"lIndex1",
	#"lIndex2",
	#"lMid1",
	#"lMid2",
	#"lPinky1",
	#"lPinky2",
	#"lRing1",
	#"lRing2",
	#"rHand",
	#"rThumb1",
	#"rThumb2",
	#"rIndex1",
	#"rIndex2",
	#"rMid1",
	#"rMid2",
	#"rPinky1",
	#"rPinky2",
	#"rRing1",
	#"rRing2",
	#"lCollar",
	#"lShldr",
	#"rCollar",
	#"rShldr",
	#"hip",
	#"abdomen",
	#"chest",
	#"abdomen2",
	#"lForeArm",
	#"rForeArm",
	#"lFoot",
	#"rFoot",
	#"lPectoral",
	#"rPectoral",
	#"tongue"

static var mappings = [
					MATERIAL_LIMBS, #"Legs",
					-1, #"EyeReflection",
					MATERIAL_HEAD, #"Nostrils",
					MATERIAL_HEAD, #"Lacrimals",
					-1, #"Pupils",
					MATERIAL_HEAD, #"Lips",
					-1, #"Tear",
					MATERIAL_HEAD, #"Gums",
					-1, #"Irises",
					MATERIAL_HEAD, #"Teeth",
					-1, #"Cornea",
					MATERIAL_HEAD, #"Face",
					MATERIAL_LIMBS, #"Toenails",
					-1, #"Sclera",
					MATERIAL_LIMBS, #"Fingernails",
					MATERIAL_HEAD, #"Head",
					MATERIAL_LIMBS, #"Hands",
					MATERIAL_LIMBS, #"Shoulders",
					MATERIAL_BODY, #"Neck",
					MATERIAL_BODY, #"Hips",
					MATERIAL_BODY, #"Torso",
					MATERIAL_BODY, #"Nipples",
					MATERIAL_LIMBS, #"Forearms",
					MATERIAL_LIMBS, #"Feet",
					-1, #"Eyelashes",
					MATERIAL_HEAD, #"Tongue",
					MATERIAL_HEAD, #"InnerMouth",
					MATERIAL_HEAD, #"Ears"
					MATERIAL_LEFT_EYE, #"LeftSclera"
					MATERIAL_RIGHT_EYE, #"RightSclera"
					MATERIAL_GENITALS, #"Genitals"
					]


func map_material(material : int) -> int:
	return mappings[material];


func read_binary_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Failed to open file: ", file_path)
		print("Error: ",error_string( FileAccess.get_open_error() ) )
		return
	
	var data_points = []
	var count : int = file.get_32()
	for i in count:
		var id : int = file.get_32()
		var x = file.get_float()
		var y = file.get_float()
		var z = file.get_float()
		data_points.append(MeshDelta._create(id,Vector3(-x,y,z)))
	
	file.close()
	
	return data_points


class MeshDelta:
	var id : int
	var delta : Vector3

	static func _create(id,delta) -> MeshDelta:
		var obj : MeshDelta = MeshDelta.new()
		obj.id = id
		obj.delta = delta
		return obj
