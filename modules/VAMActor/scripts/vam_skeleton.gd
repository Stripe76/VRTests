@tool
class_name VAMSkeleton
extends Skeleton3D


#func _ready() -> void:
	#if Engine.is_editor_hint() and false:
	#	var base_model := preload("res://modules/VAMActor/resources/Genesis2Female.dsf")
	
	#	print("Load skeleton")
	#	load_skeleton(base_model)


#func _validate_property(property: Dictionary):
	#print(property["name"])


var editor_owner
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			editor_owner = owner
			owner = null
		NOTIFICATION_EDITOR_POST_SAVE:
			owner = editor_owner


func load_skeleton(base_model: Daz3DMesh):
	if base_model:
		var skeleton : Skeleton3D = self
		
		print("Skeleton creation")
		create_skeleton(skeleton,base_model.bones)


func get_bone_index(skeleton: Skeleton3D,bone_name: String) -> int:
	for i in skeleton.get_bone_count():
		if skeleton.get_bone_name(i).begins_with(bone_name):
			return i
	return -1


func get_vector_from_storables(data : Dictionary,name : String) -> Vector3:
	var value : Vector3
	var vector_data = data[name]
	value.x = str_to_var(vector_data["x"])
	value.y = str_to_var(vector_data["y"])
	value.z = str_to_var(vector_data["z"])
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


func create_skeleton(skeleton : Skeleton3D,bones : Array) -> Skeleton3D:
	skeleton.clear_bones()
	
	var bones_idx : Dictionary = {}
	var bones_origins : Dictionary = {}
	for b : Dictionary in bones:
		var name : String = b["name"]
		var idx : int = skeleton.add_bone(name)
		var origin : Vector3 = b["origin"]
		
		skeleton.set_bone_name(idx,"%s %s" % [name,idx] )
		
		if b.has("parent"):
			skeleton.set_bone_parent(idx,bones_idx[b["parent"]])
			origin -= bones_origins[b["parent"]]
		bones_idx[name] = idx
		bones_origins[name] = b["origin"]
	
		skeleton.set_bone_rest(idx,Transform3D(Basis( ),origin))
		skeleton.set_bone_pose_position(idx,origin)
		skeleton.set_bone_pose_rotation(idx,Quaternion( ))
	
	return skeleton


func get_skeleton_data(data) -> Array:
	var nodes = data["node_library"]
	var weights = data["modifier_library"]
	if nodes:
		var bones : Array
		for b : Dictionary in nodes:
			var type : String = b["type"]
			if type == "figure" or type == "bone":
				var bone : Dictionary
				bone["name"] = b["id"]
				if b.has("parent"):
					bone["parent"] = b["parent"].replace("#","")

				bone["origin"] = get_vector_from_data(b,"center_point")
				bone["end"] = get_vector_from_data(b,"end_point")
				bone["orientation"] = get_vector_from_data(b,"orientation")
				bone["rotation"] = get_vector_from_data(b,"rotation")
				bone["translation"] = get_vector_from_data(b,"translation")
				bone["scale"] = get_vector_from_data(b,"scale")
				bone["weights"] = get_bone_weights(bone["name"],weights)

				bones.append(bone)
		return bones
	return []


func get_bone_weights(bone_name: String,weights: Array) -> Array:
	var bone_weights : Array
	var joints = weights[0]["skin"]["joints"]
	if joints:
		for w in joints:
			if w["node"] == "#"+bone_name:
				var values = w["local_weights"]["x"]["values"]
				for v in values:
					bone_weights.push_back(v)
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


func get_storables(scene_data : Dictionary):
	if scene_data and scene_data.has("atoms"):
		var atoms = scene_data["atoms"]
		for a : Dictionary in atoms:
			if a["id"] == "Person" or a["type"] == "Person" and a.has("storables"):
				return a["storables"]

	if scene_data and scene_data.has("storables"):
		return scene_data["storables"]
	
	return null


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
