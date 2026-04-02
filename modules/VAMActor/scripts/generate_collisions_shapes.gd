@tool
extends Node3D

@export_tool_button("Generate","Reload") var reset_action = generate_collision_shapes

@export var skeleton_path: NodePath:
	set(value):
		skeleton_path = value
		update_configuration_warnings()
	get:
		return skeleton_path
@export var physical_simulator_path: NodePath:
	set(value):
		physical_simulator_path = value
		update_configuration_warnings()
	get:
		return physical_simulator_path

##Select path of meshes (usually Skeleton3D again), or a single mesh path
@export var mesh_instance_path: NodePath:
	set(value):
		mesh_instance_path = value
		update_configuration_warnings()
	get:
		return mesh_instance_path

#(0.0, 1.0, 0.01)
@export var weight_threshold: float = 0.25
#(1, 20, 1)
@export var min_points_for_convex: int = 6
@export var remove_existing_collision_shapes: bool = true
@export var use_capsules: bool = false:
	set(value):
		use_capsules = value
		generate_collision_shapes()
	get:
		return use_capsules


const ARRAY_VERTEX := Mesh.ARRAY_VERTEX
const ARRAY_BONES := Mesh.ARRAY_BONES
const ARRAY_WEIGHTS := Mesh.ARRAY_WEIGHTS


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not get_node_or_null(mesh_instance_path):
		warnings.append("Set mesh_instance_path.")
	if not get_node_or_null(skeleton_path):
		warnings.append("Set skeleton_path.")
	if not get_node_or_null(physical_simulator_path):
		warnings.append("Set physical_simulator_path.")
	return warnings


func _ready() -> void:
	generate_collision_shapes()


func generate_collision_shapes() -> void:
	var mesh_instance: Node3D = get_node_or_null(mesh_instance_path)
	var skeleton: Skeleton3D = get_node_or_null(skeleton_path)
	var simulator: Node3D = get_node_or_null(physical_simulator_path)

	if not mesh_instance:
		push_error("Mesh instance not found. Set mesh_instance_path.")
		return
	if not skeleton:
		push_error("Skeleton3D not found. Set skeleton_path.")
		return
	if not simulator:
		push_error("PhysicalBoneSimulator3D not found. Set physical_simulator_path.")
		return
	
	var meshs: Array = []
	if mesh_instance is MeshInstance3D:
		meshs.append(mesh_instance)
		meshs += mesh_instance.get_children().filter(func(c): return c is MeshInstance3D)
	print(meshs)

	if meshs.is_empty():
		push_error("No MeshInstance3D found under mesh_instance_path")
		return

	var bone_vertex_map := generate_bones_vertices(skeleton,meshs)
	
	var mesh_global_xform: Transform3D = mesh_instance.global_transform
	#print(bone_vertex_map)
	for bone_idx in bone_vertex_map.keys():
		print("Bone: ", bone_idx, " Name:", skeleton.get_bone_name(bone_idx), " Count:", bone_vertex_map[bone_idx].size())
		var bone_name = skeleton.get_bone_name(bone_idx)
		if bone_name == "":
			continue
		
		var physical_bone_node: PhysicalBone3D = null
		if simulator.has_node(bone_name):
			physical_bone_node = simulator.get_node(bone_name)
		else:
			var alt_name = "Physical Bone " + bone_name
			if simulator.has_node(alt_name):
				physical_bone_node = simulator.get_node(alt_name)
			else:
				for child in simulator.get_children():
					if child is Node3D and bone_name in child.name:
						physical_bone_node = child
						break
		
		if not physical_bone_node:
			continue
		
		if remove_existing_collision_shapes:
			for child in physical_bone_node.get_children():
				if child is CollisionShape3D:
					child.queue_free()
	
		var raw_points: Array = bone_vertex_map[bone_idx]
		if raw_points.is_empty():
			continue
	
		var inv_phys_xform := physical_bone_node.global_transform.affine_inverse()
		var transformed_points := []
		for v in raw_points:
			var global_v = mesh_global_xform * v
			var local_v = inv_phys_xform * global_v
			transformed_points.append(local_v)
		
		transformed_points = _unique_points(transformed_points, 0.001)		
		
		#var shape = generate_shape(transformed_points,use_capsules)
		
		var cs := CollisionShape3D.new()
		cs.shape = generate_shape(cs,transformed_points,use_capsules)
		physical_bone_node.add_child(cs)
		cs.owner = physical_bone_node.owner
		
		if physical_bone_node is VAMPhysicalBone3D:
			var spring = physical_bone_node.spring_pusher
			if spring is SpringPusher:
				spring.shape = cs
		
	print("Bone collision generation complete.")


func generate_shape(cs: CollisionShape3D,transformed_points : Array,capsules: bool) -> Shape3D:
	var shape
	if capsules:
		var aabb := _points_aabb(transformed_points)
		
		var shrink_factor := 0.85
		var center = aabb.get_center()
		var size = aabb.size * shrink_factor
		
		shape = CapsuleShape3D.new()
		var longest_axis = 0 # 0:X, 1:Y, 2:Z
		if size.y > size.x and size.y > size.z: longest_axis = 1
		elif size.z > size.x: longest_axis = 2
		
		var height = size[longest_axis]
		var radius = (min(size.x, size.z) if longest_axis == 1 else min(size.x, size.y)) * 0.5
		
		shape.radius = clamp(radius, 0.01, height * 0.4)
		shape.height = height
		#capsule.height = max(0.1, height - (capsule.radius * 2.0))
		
		cs.position = center
		
		if longest_axis == 0: # X
			cs.rotation_degrees = Vector3(0, 0, 90)
		elif longest_axis == 2: # Z
			cs.rotation_degrees = Vector3(90, 0, 0)
	else:
		if transformed_points.size() >= min_points_for_convex:
			shape = ConvexPolygonShape3D.new()
			var pva := PackedVector3Array()
			for p in transformed_points:
				pva.append(p *0.85)
			shape.points = pva
		else:
			var aabb := _points_aabb(transformed_points)
			var radius = max(aabb.size.x, aabb.size.y, aabb.size.z) * 0.5
			if radius <= 0.001:
				radius = 0.05
			shape = SphereShape3D.new()
			shape.radius = radius
	return shape


func generate_bones_vertices(skeleton: Skeleton3D,meshs: Array)-> Dictionary:
	var bone_vertex_map := {}
	var bone_count := skeleton.get_bone_count()
	for i in bone_count:
		bone_vertex_map[i] = []
		
	for m in meshs:
		var mesh: Mesh = m.mesh
		var surface_count := mesh.get_surface_count()
		for s in surface_count:
			var arrays := mesh.surface_get_arrays(s)
			if arrays.size() == 0:
				continue
			if ARRAY_VERTEX >= arrays.size():
				continue
			var verts: PackedVector3Array = arrays[ARRAY_VERTEX]
			if verts.is_empty():
				continue
			
			if ARRAY_BONES >= arrays.size() or ARRAY_WEIGHTS >= arrays.size():
				continue
			var bones_arr = arrays[ARRAY_BONES]
			var weights_arr = arrays[ARRAY_WEIGHTS]
			
			if bones_arr.size() < verts.size() * 4 or weights_arr.size() < verts.size() * 4:
				continue
			
			print("Surface: ", s, " Verts: ", verts.size(), " Bones_length: ", bones_arr.size(), " Weights_length: ", weights_arr.size())

			for vi in verts.size():
				var v: Vector3 = verts[vi]
				var base_idx := vi * 8
				for j in 8:
					var bidx := int(bones_arr[base_idx + j])
					var w := float(weights_arr[base_idx + j])
					if w >= weight_threshold and bidx >= 0 and bidx < bone_count:
						bone_vertex_map[bidx].append(v)	
	
	return bone_vertex_map


func _unique_points(points: Array, eps: float) -> Array:
	var unique = {}
	for p in points:
	# Quantize the vector to snap nearby points together
		var snapped = p.snapped(Vector3(eps, eps, eps))
		unique[snapped] = p
	return unique.values()


func _points_aabb(points: Array) -> AABB:
	if points.is_empty():
		return AABB()
	var minp = points[0]
	var maxp = points[0]
	for p in points:
		minp = Vector3(min(minp.x, p.x), min(minp.y, p.y), min(minp.z, p.z))
		maxp = Vector3(max(maxp.x, p.x), max(maxp.y, p.y), max(maxp.z, p.z))
	return AABB(minp, maxp - minp)
