@tool
class_name VAMSkeleton
extends Skeleton3D

var left_eye_bone_origin : Vector3
var right_eye_bone_origin : Vector3

var editor_owner
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			editor_owner = owner
			owner = null
		NOTIFICATION_EDITOR_POST_SAVE:
			owner = editor_owner


func load_skeleton(base_model: Daz3DMesh,scene_folder: String,scene_file: String = ""):
	if base_model:
		var skeleton : Skeleton3D = self
		
		var morphs := {}
		if scene_file != "":
			var file := FileAccess.open(scene_folder+scene_file,FileAccess.READ)
			if file:
				var scene_data : Dictionary = JSON.parse_string(file.get_as_text())
				if scene_data:
					morphs = load_morphs(scene_data,scene_folder)
				file.close()
		
		create_skeleton(skeleton,base_model.bones,morphs)
		
		left_eye_bone_origin = skeleton.get_bone_global_rest(Bones.EYE_LEFT_BONE).origin
		right_eye_bone_origin = skeleton.get_bone_global_rest(Bones.EYE_RIGHT_BONE).origin


func load_morphs(scene_data: Dictionary,scene_folder: String) -> Dictionary:
	var bones_morphs := {}
	var storables = get_storables(scene_data)
	if storables:
		for s : Dictionary in storables:
			if s["id"] == "geometry" and s.has("morphs"):
				var morphs = s["morphs"]
				for m in morphs:
					var uid : String = m["uid"]
					if uid.begins_with("SELF:"):
						var path = scene_folder + uid.substr(6)
						if not path.contains("genitalia"):
							print("Applying skeleton deltas: ",path)
							var file := FileAccess.open(path,FileAccess.READ)
							if file:
								var morph_data : Dictionary = JSON.parse_string(file.get_as_text())
								for f in morph_data["formulas"]:
									var bone_name = f["target"]
									if not bones_morphs.has(bone_name):
										bones_morphs[bone_name] = []
									bones_morphs[bone_name].push_back({f["targetType"]: float(f["multiplier"]) * 0.2 }) 
								#print(bones_morphs)
								file.close()
	return bones_morphs


func load_skeleton_new(base_model: Daz3DMesh,library: LibraryManager,looksID: int):
	if base_model:
		var skeleton : Skeleton3D = self
		
		var morphs := {}
		if looksID >=  0:
			morphs = load_morphs_new(library,looksID)
		
		create_skeleton(skeleton,base_model.bones,morphs)
		
		left_eye_bone_origin = skeleton.get_bone_global_rest(Bones.EYE_LEFT_BONE).origin
		right_eye_bone_origin = skeleton.get_bone_global_rest(Bones.EYE_RIGHT_BONE).origin


func load_morphs_new(library: LibraryManager,looksID: int) -> Dictionary:
	var bones_morphs := {}
	var morphs : Array = library.Looks_GetMorphs(looksID)
	for morph in morphs:
		if morph["type"] != "genitalia":
			for bone_name in morph["bonesData"]:
				if not bones_morphs.has(bone_name):
					bones_morphs[bone_name] = []
				bones_morphs[bone_name].append_array(morph["bonesData"][bone_name])
	return bones_morphs


func create_skeleton(skeleton: Skeleton3D,bones: Array,morphs: Dictionary) -> Skeleton3D:
	skeleton.clear_bones()
	
	var bones_idx : Dictionary = {}
	var bones_origins : Dictionary = {}
	for b : Dictionary in bones:
		var bone_name : String = b["name"]
		var idx : int = skeleton.add_bone(bone_name)
		var origin : Vector3 = b["origin"]
		var orientation : Vector3 = b["orientation"]
		
		if morphs.has(bone_name):
			for m : Dictionary in morphs[bone_name]:
				if m.keys()[0] == "BoneCenterX":
					origin.x = origin.x + m.values()[0]
				elif m.keys()[0] == "BoneCenterY":
					origin.y = origin.y + m.values()[0]
				elif m.keys()[0] == "BoneCenterZ":
					origin.z = origin.z + m.values()[0]
		
		#skeleton.set_bone_name(idx,"%s %s" % [name,idx] )
		
		if b.has("parent"):
			skeleton.set_bone_parent(idx,bones_idx[b["parent"]])
			origin -= bones_origins[b["parent"]]
		bones_idx[bone_name] = idx
		bones_origins[bone_name] = b["origin"]
		
		var orient_rad = Vector3(deg_to_rad(orientation.x),deg_to_rad(orientation.y),deg_to_rad(orientation.z))
		# 2. Create the Basis (DAZ orientation is typically XYZ order)
		# This defines the "Roll" and local axis directions
		var bone_basis = Basis.from_euler(orientation,EULER_ORDER_XYZ)
		
		#skeleton.set_bone_rest(idx,Transform3D(bone_basis,origin))
		skeleton.set_bone_rest(idx,Transform3D(Basis(),origin))
		skeleton.reset_bone_pose(idx)
		#skeleton.set_bone_pose_position(idx,origin)
		#skeleton.set_bone_pose_rotation(idx,Quaternion( ))
	
	return skeleton


func get_bone_index(skeleton: Skeleton3D,bone_name: String) -> int:
	for i in skeleton.get_bone_count():
		if skeleton.get_bone_name(i).begins_with(bone_name):
			return i
	return -1


func get_vector_from_storables(data: Dictionary,name: String) -> Vector3:
	var value : Vector3
	var vector_data = data[name]
	value.x = float(vector_data["x"])
	value.y = float(vector_data["y"])
	value.z = float(vector_data["z"])
	return value


func set_pose(skeleton: Skeleton3D,scene_data: Dictionary):
	var storables = get_storables(scene_data)
	
	if storables:
		for s : Dictionary in storables:
			var i := get_bone_index(skeleton,s["id"])
			if i >= 0 and s.has("position"):
				var p := get_vector_from_storables(s,"position")
				p.x = -p.x
				p.z = p.z
				#p += skeleton.get_bone_rest()
				#skeleton.set_bone_pose_position(i,p)
				
				var r = get_vector_from_storables(s,"rotation")
				r.x = (r.x / 360.0) * (2 * PI)
				r.y = (r.y / 360.0) * (2 * PI)
				r.z = (r.z / 360.0) * (2 * PI)
				#r.x *= -1;
				r.x = 0;
				r.y *= -1;
				r.y = 0;
				r.z *= -1;
				#r.z = 0;
				#skeleton.set_bone_pose_rotation(i,Quaternion.from_euler( r ))


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


func get_storables(scene_data : Dictionary):
	if scene_data and scene_data.has("atoms"):
		var atoms = scene_data["atoms"]
		for a : Dictionary in atoms:
			if a["id"] == "Person" or a["type"] == "Person" and a.has("storables"):
				return a["storables"]

	if scene_data and scene_data.has("storables"):
		return scene_data["storables"]
	
	return null
