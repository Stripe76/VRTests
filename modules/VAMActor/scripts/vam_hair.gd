@tool
extends Node3D

@export var library_folder : String
@export var hair_file : String


func _ready() -> void:
	create_skeleton($Skeleton)
	update_mesh()


func _validate_property(property: Dictionary):
	#print(property["name"])
	if ["mesh"].has(property["name"]):
		property["usage"] = PROPERTY_USAGE_EDITOR


func update_mesh():
	if hair_file == "":
		return
	hair_file = hair_file.replace("\\","/")
	
	var file := FileAccess.open(library_folder+hair_file,FileAccess.READ)
	if not file:
		return
	
	var strands : Array = load_hair_strands(file)
	if strands.size() <= 0:
		return
	
	var vertices := PackedVector3Array()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	
	for s : PackedVector3Array in strands:
		var l : float = s.size()
		for i : float in s.size():
			vertices.push_back(s[i])
			bones.push_back(1)
			weights.push_back(i/l)
			bones.push_back(2)
			weights.push_back(1-i/l)
			bones.push_back(0)
			weights.push_back(0)
			bones.push_back(0)
			weights.push_back(0)
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	
	var surface_tool := SurfaceTool.new()
	surface_tool.create_from_arrays(arrays,Mesh.PRIMITIVE_LINES)
	
	var array_mesh := surface_tool.commit()	
	
	$Skeleton/HairMesh.mesh = array_mesh
	
	self.remove_child($HairMesh)
	#$Skeleton.add_child($HairMesh)
	#$HairMesh.owner = $Skeleton


func load_hair_strands(file: FileAccess)-> Array:
	var strands := []

	file.seek(996)

	var how_many := file.get_32()
	file.get_32()
	for s in how_many:
		var vertices : PackedVector3Array = []
		var count := file.get_32()
		file.get_32()

		var last : Vector3
		for c in range(count):
			var x = file.get_float()
			var z = file.get_float()
			var y = file.get_float()
			
			var current := Vector3(y,x,z)
			if last:
				vertices.push_back(last)
				vertices.push_back(current)
			last = current
		if vertices.size() > 1:
			vertices.remove_at(vertices.size()-1)
			vertices.remove_at(vertices.size()-1)
		
		strands.push_back(vertices)
	
	return strands


func create_skeleton(skeleton: Skeleton3D):
	skeleton.clear_bones()
	
	var origin := Vector3(0,0,0)
	var idx := skeleton.add_bone("bone")	
	skeleton.set_bone_name(idx,str(idx))
	skeleton.set_bone_rest(idx,Transform3D(Basis( ),origin))
	#skeleton.set_bone_pose_position(idx,origin)
	#skeleton.set_bone_pose_rotation(idx,Quaternion( ))
	
	var parent := idx
	origin = Vector3(0,.2,0)
	idx = skeleton.add_bone("bone")
	skeleton.set_bone_name(idx,str(idx))
	skeleton.set_bone_parent(idx,parent)
	skeleton.set_bone_rest(idx,Transform3D(Basis( ),origin))
	#skeleton.set_bone_pose_position(idx,origin)
	#skeleton.set_bone_pose_rotation(idx,Quaternion( ))
	
	parent = idx
	idx = skeleton.add_bone("bone")
	skeleton.set_bone_name(idx,str(idx))
	skeleton.set_bone_parent(idx,parent)
	skeleton.set_bone_rest(idx,Transform3D(Basis( ),origin))
	#skeleton.set_bone_pose_position(idx,origin)
	#skeleton.set_bone_pose_rotation(idx,Quaternion( ))
	
	parent = idx
	idx = skeleton.add_bone("bone")
	skeleton.set_bone_name(idx,str(idx))
	skeleton.set_bone_parent(idx,parent)
	skeleton.set_bone_rest(idx,Transform3D(Basis( ),origin))
	#skeleton.set_bone_pose_position(idx,origin)
	#skeleton.set_bone_pose_rotation(idx,Quaternion( ))
	
	#add_spring(skeleton,2,0,0.2,0.1)


func add_spring(skeleton: Skeleton3D,bone: int,chain_length: int,stiffness: float,drag: float):
	var spring := SpringBoneSimulator3D.new()
	spring.setting_count = 1
	spring.set_root_bone(0,bone)
	spring.set_end_bone(0,bone+chain_length)
	if chain_length == 0:
		spring.set_extend_end_bone(0,true)
		spring.set_end_bone_length(0,0.2)
		spring.set_end_bone_direction(0,SpringBoneSimulator3D.BONE_DIRECTION_FROM_PARENT)
	spring.set_radius(0,0.02)
	spring.set_stiffness(0,stiffness)
	spring.set_drag(0,drag)
	spring.active = true;
	
	skeleton.add_child(spring)
	spring.owner = self
