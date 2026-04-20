@tool
class_name VAMHair extends Node3D

@export_tool_button("Generate","Reload") var generate = create_hair

@export var library_folder : String
@export var hair_file : String
@export var hair_material : ShaderMaterial

@export var force : Vector3:
	set(value):
		force = value
		if hair_material:
			hair_material.set_shader_parameter("force",Vector4(force.x,force.y,force.z,strentgh))
	get:
		return force
@export var strentgh : float:
	set(value):
		strentgh = value
		if hair_material:
			hair_material.set_shader_parameter("force",Vector4(force.x,force.y,force.z,strentgh))
	get:
		return strentgh
@export var force_lerp : float = 1.0:
	set(value):
		force_lerp = value
		if hair_material:
			hair_material.set_shader_parameter("lerp",force_lerp)
	get:
		return force_lerp

@export_range(0,30) var _how_many : int = 4:
	set(value):
		_how_many = value
		create_hair()
	get:
		return _how_many

@export_range(-0.5,0.5) var AB_distribution: float = -.5
@export_group("Hair colors A","a_")
@export var a_root: Color = Color(0.066, 0.034, 0.01, 1.0)
@export var a_middle: Color = Color(0.02, 0.015, 0.01, 1.0)
@export var a_tip: Color = Color(0.066, 0.034, 0.01, 1.0)
@export_range(0,10) var a_weight_root: int = 1
@export_range(0,10) var a_weight_middle: int = 10
@export_range(0,10) var a_weight_tip: int = 10
@export_range(-1.5,1.5) var a_variation: float = -0.3
@export_group("Hair colors B","b_")
@export var b_root: Color = Color(0.109, 0.049, 0.0, 1.0)
@export var b_middle: Color = Color(0.84, 0.755, 0.534, 1.0)
@export var b_tip: Color = Color(0.83, 0.736, 0.576, 1.0)
@export_range(0,10) var b_weight_root: int = 1
@export_range(0,10) var b_weight_middle: int = 10
@export_range(0,10) var b_weight_tip: int = 10
@export_range(-1.5,1.5) var b_variation: float = -0.2

var _hair_mesh : MeshInstance3D
var _hair_debug : MeshInstance3D


var _editor_owner
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			_editor_owner = owner
			owner = null
		NOTIFICATION_EDITOR_POST_SAVE:
			owner = _editor_owner
func _validate_property(property: Dictionary):
	if ["HairMesh"].has(property["name"]):
		property["usage"] = PROPERTY_USAGE_EDITOR


func _ready() -> void:
	hair_material = ShaderMaterial.new()
	hair_material.shader = load("res://modules/VAMActor/shaders/hair.gdshader")
	
	#create_skeleton($Skeleton)
	
	if Engine.is_editor_hint():
		create_hair()


var _last_position : Vector3
var _last_rotation : Quaternion
func _physics_process(delta: float) -> void:
	var head_inv_transform = global_transform.affine_inverse()
	var gravity = head_inv_transform.basis * Vector3(0, -9.8, 0)
	
	var shift : Vector3
	if not _last_position.is_zero_approx():
		shift = (global_position - _last_position)
		shift *= head_inv_transform.basis
	
	var current_rot = global_transform.basis.get_rotation_quaternion()
	var inv_delta_rot = current_rot.inverse() * _last_rotation
	
	var head_up = global_transform.basis.y
	var world_up = Vector3.UP
	# dot_alignment is 1.0 (upright), 0.0 (horizontal), -1.0 (upside down)
	var dot_alignment = head_up.dot(world_up)
	# This version hits 0.0 stiffness exactly at the horizontal (90 degrees)
	# Anything below horizontal remains 0.0
	var style_strength = clamp(dot_alignment, 0.0, 1.0)
	
	style_strength = pow(style_strength, 2.0)
	
	force_lerp = style_strength
	
	_render_process.call_deferred(true,true,shift,inv_delta_rot,gravity,delta,force_lerp,1,0.60)
	
	_last_rotation = current_rot
	_last_position = global_position


func create_hair():
	if _loaded_strands and _loaded_strands.size() > 0 and _head_tris:
		var arrays_data = generate_hair_strands(_loaded_strands,_head_tris,_how_many,0.015)
		
		var surface_tool := SurfaceTool.new()
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_INDEX] = arrays_data["Indices"]
		arrays[Mesh.ARRAY_VERTEX] = arrays_data["Vertices"]
		arrays[Mesh.ARRAY_NORMAL] = arrays_data["Normals"]
		arrays[Mesh.ARRAY_COLOR] = arrays_data["Colors"]
		arrays[Mesh.ARRAY_CUSTOM0] = arrays_data["Customs0"]
		arrays[Mesh.ARRAY_CUSTOM1] = arrays_data["Customs1"]
		arrays[Mesh.ARRAY_TEX_UV] = arrays_data["UVs"]
		
		surface_tool.create_from_arrays(arrays,Mesh.PRIMITIVE_LINES)
		_hair_mesh.mesh =  surface_tool.commit()
		for i in _hair_mesh.mesh.get_surface_count():
			_hair_mesh.set_surface_override_material(i,hair_material)


var _head_tris: Dictionary
func generate_hair(filename: String,head_tris: Dictionary):
	_head_tris = head_tris
	var file := FileAccess.open(filename,FileAccess.READ)
	if not file:
		return
	
	if not _hair_mesh:
		_hair_mesh = MeshInstance3D.new()
		_hair_mesh.name = "HairMesh"
		add_child(_hair_mesh)
		_hair_mesh.owner = owner
		
	if not _hair_debug and Engine.is_editor_hint():
		_hair_debug = MeshInstance3D.new()
		_hair_debug.name = "HairDebug"
		add_child(_hair_debug)
		_hair_debug.owner = owner
	
	_hair_mesh.mesh = generate_hair_from_file(file,head_tris,_how_many)
	for i in _hair_mesh.mesh.get_surface_count():
		_hair_mesh.set_surface_override_material(i,hair_material)
	
	if _hair_debug and Engine.is_editor_hint():
		generate_hair_debug(file,head_tris)
		#generate_hair_debug(file,{})


var _loaded_strands : Array
var input_bytes : PackedByteArray
func generate_hair_from_file(file: FileAccess,head_tris: Dictionary,how_many: int) -> ArrayMesh:
	_loaded_strands = load_hair_strands(file)
	if _loaded_strands.size() <= 0:
		return
	
	var arrays_data := generate_hair_strands(_loaded_strands,head_tris,how_many,0.015)
	
	create_verlet_shader( arrays_data )
	
	return create_mesh( arrays_data )


func create_verlet_shader(arrays_data: Dictionary):
	var texture_size : Vector2i = arrays_data["ImageSize"]
	var image_data : PackedByteArray = arrays_data["ImageData"]
	
	# TODO: should wait somehow?
	RenderingServer.call_on_render_thread(_initialize_compute_code.bind(texture_size,image_data))


func verlet_shader_initialized():
	print("verlet_shader_initialized")
	var image : Texture2DRD = hair_material.get_shader_parameter("data_points")
	if not image:
		image = Texture2DRD.new()
		image.texture_rd_rid = _curr_pose_rid
		hair_material.set_shader_parameter("data_points",image)
		print("texture_rid: ",_curr_pose_rid)


func create_mesh(arrays_data: Dictionary) -> ArrayMesh:
	var surface_tool := SurfaceTool.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_INDEX] = arrays_data["Indices"]
	arrays[Mesh.ARRAY_VERTEX] = arrays_data["Vertices"]
	arrays[Mesh.ARRAY_NORMAL] = arrays_data["Normals"]
	arrays[Mesh.ARRAY_COLOR] = arrays_data["Colors"]
	arrays[Mesh.ARRAY_CUSTOM0] = arrays_data["Customs0"]
	arrays[Mesh.ARRAY_CUSTOM1] = arrays_data["Customs1"]
	arrays[Mesh.ARRAY_TEX_UV] = arrays_data["UVs"]
	
	surface_tool.create_from_arrays(arrays,Mesh.PRIMITIVE_LINES)
	return surface_tool.commit()

####################################
# Hair generation
###################################
func generate_hair_strands(strands: Array,head_tris: Dictionary,how_many: int,spacing: float) -> Dictionary:
	var head_origin : Vector3
	var normalized : PackedVector3Array
	if head_tris:
		head_origin = head_tris["Origin"]
		normalized = PackedVector3Array()
		
		for v : Vector3 in head_tris["Vertices"]:
			normalized.push_back((v-head_origin).normalized())
		head_tris["Normalized"] = normalized
	
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var customs0 := PackedFloat32Array()
	var customs1 := PackedFloat32Array()
	var uvs := PackedVector2Array()
	
	var count := 0 
	@warning_ignore("integer_division")
	var column := (strands.size() / 8+1)*8
	for s : PackedVector3Array in strands:
		if s.size() > count:
			count = s.size()
	@warning_ignore("integer_division")
	count = (count/8+1)*8
	
	var image_size := Vector2i(count,column)
	var image_data := PackedVector4Array( )
	
	var col := 0
	var index := 0
	var inc_spacing = spacing / how_many
	for s : PackedVector3Array in strands:
		var size : float = s.size()
		var sizei : int = s.size()
		var offset : Vector3
		var last_vertex : Vector3
		var direction : Vector3
		
		if s.size() > 0:
			direction = s[1].normalized()
		
		var strand_origin = s[0]
		last_vertex = strand_origin
		
		if head_tris:
			offset = find_offset(head_origin,head_tris,strand_origin)
		
		var select_a = true if randf() > 0.5 + AB_distribution else false
		var root_color := a_root if select_a else b_root
		var middle_color := a_middle if select_a else b_middle
		var tip_color := a_tip if select_a else b_tip

		var weight_root : float
		var weight_middle : float
		if select_a:
			weight_root = a_weight_root as float / (a_weight_root + a_weight_middle + a_weight_tip)
			weight_middle = a_weight_middle as float / (a_weight_middle + a_weight_tip)
		else:
			weight_root = b_weight_root as float / (b_weight_root + b_weight_middle + b_weight_tip)
			weight_middle = b_weight_middle as float / (b_weight_middle + b_weight_tip)
		
		var variation := 1.0+randf_range(0,a_variation if select_a else b_variation)
		root_color *= variation
		middle_color *= variation
		tip_color *= variation
		
		var x_sign : float = 1 if strand_origin.x+spacing > 0 else -1
		var y_sign : float = 1 if strand_origin.z+spacing < 0 else -1
		for x in how_many:
			for y in how_many:
				var length : float = 0.0
				var inc : Vector3 = Vector3(x*x_sign*inc_spacing,0,y*y_sign*inc_spacing)
				var parts := sizei
				if x > 0 or y > 0:
					parts = sizei - randi_range(0,4) 
				for i in parts:
					var vertex : Vector3 = s[i] - strand_origin + offset
					var vertex_offset := (inc + Vector3(randf_range(-0.001,0.001),0.0,randf_range(-0.001,0.001))) * (1.0-(i as float / (size-1)))
					vertex += vertex_offset
					
					if i == 5:
						length = 0
					else:
						length += (vertex-last_vertex).length()
					
					vertices.push_back(vertex)
					normals.push_back((last_vertex-vertex).normalized())
					uvs.push_back(Vector2(i,col))
					colors.push_back(root_color)
				
					var v := i / size
					if v < weight_root:
						colors.push_back(lerp(root_color,middle_color,v/weight_root))
					else:
						v = (i-(weight_root*size)) / (size-(weight_root*size))
						if v < weight_middle:
							colors.push_back(middle_color)
						else:
							colors.push_back(lerp(middle_color,tip_color,(v-weight_middle)/(1.0-weight_middle)))
							
					customs0.push_back(vertex_offset.x)
					customs0.push_back(vertex_offset.y)
					customs0.push_back(vertex_offset.z)
					customs0.push_back(0)
					customs1.push_back(direction.x)
					customs1.push_back(direction.y)
					customs1.push_back(direction.z)
					customs1.push_back(length)
					
					if i > 0:
						indices.push_back(index-1)
						indices.push_back(index)
					
					if x == 0 and y == 0:
						image_data.push_back(Vector4(vertex.x,vertex.y,vertex.z,(vertex-last_vertex).length()))
					
					index += 1
					last_vertex = vertex
				
				if x == 0 and y == 0:
					for i in count - s.size():
						image_data.push_back(Vector4(0,0,0,-1))
		col += 1
	for i in column - strands.size():
		for c in count:
			image_data.push_back(Vector4(0,0,0,-1))
	
	print("Hair vertices: ",index)
	print("Image size: ",image_size)
	print("Image buffer length: ",image_data.size())
	#for i in 10:
	#	print(image_data[i])
	
	return {
		"Vertices":vertices,
		"Normals":normals,
		"Colors":colors,
		"Indices": indices,
		"Customs0": customs0,
		"Customs1": customs1,
		"UVs" : uvs,
		"ImageSize" : image_size,
		"ImageData" : image_data.to_byte_array(),
		}


func load_hair_strands(file: FileAccess)-> Array:
	var strands := []

	file.seek(996)

	var how_many := file.get_32()
	file.get_32()
	
	for s in how_many:
		var vertices : PackedVector3Array = []
		var count := file.get_32()
		file.get_32()
		
		for c in range(count):
			var x = file.get_float()
			var z = file.get_float()
			var y = file.get_float()
			
			vertices.push_back(Vector3(y,x,z))
		
		if vertices.size() > 1:
			vertices.remove_at(vertices.size()-1)
			#vertices.remove_at(vertices.size()-1)
			strands.push_back(vertices)
	
	var origin = find_origin(strands) + Vector3(0,-0.06,-0.01)
	
	for s : PackedVector3Array in strands:
		for i in s.size():
			s[i] = s[i] - origin
	
	return strands


func find_origin(strands: Array)-> Vector3:
	var roots := PackedVector3Array()
	for s : PackedVector3Array in strands:
		if s.size() > 0:
			roots.append(s[0])
	return _points_aabb(roots).get_center()


func find_offset(head_origin: Vector3,head_tris: Dictionary,root: Vector3)-> Vector3:
	var normalized = root.normalized()
	
	var idx = 0
	var max1 : int
	var max_d1 : float = 0.0
	var max2 : int
	var max_d2 : float = 0.0
	var max3 : int
	var max_d3 : float = 0.0
	
	for v : Vector3 in head_tris["Normalized"]:
		var d := v.dot(normalized)
		if d > max_d1:
			max3 = max2
			max_d3 = max_d2
			max2 = max1
			max_d2 = max_d1
			max1 = idx
			max_d1 = d
		elif d > max_d2:
			max3 = max2
			max_d3 = max_d2
			max2 = idx
			max_d2 = d
		elif d > max_d3:
			max3 = idx
			max_d3 = d
		idx += 1
	
	var distance : float = ((head_tris["Vertices"][max1]-head_origin).length() + \
		(head_tris["Vertices"][max2]-head_origin).length() + \
		(head_tris["Vertices"][max3]-head_origin).length()) / 3.0
	return normalized * distance


func _points_aabb(points: PackedVector3Array) -> AABB:
	if points.is_empty():
		return AABB()
	var minp = points[0]
	var maxp = points[0]
	for p in points:
		minp = Vector3(min(minp.x, p.x), min(minp.y, p.y), min(minp.z, p.z))
		maxp = Vector3(max(maxp.x, p.x), max(maxp.y, p.y), max(maxp.z, p.z))
	return AABB(minp, maxp - minp)


func generate_hair_debug(file: FileAccess,head_tris: Dictionary):
	var strands := load_hair_strands(file)
	if strands.size() <= 0:
		return
	
	var head_origin : Vector3
	var normalized : PackedVector3Array
	if head_tris:
		head_origin = head_tris["Origin"]
		normalized = PackedVector3Array()
		
		for v : Vector3 in head_tris["Vertices"]:
			normalized.push_back((v-head_origin).normalized())
		head_tris["Normalized"] = normalized
	
	var vertices := PackedVector3Array()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
		
	for s : PackedVector3Array in strands:
		if s.size() > 0:
			var offset : Vector3
			
			var strand_origin = s[0]
			if head_tris:
				offset = find_offset(head_origin,head_tris,strand_origin)
				vertices.push_back(offset)
			else:
				vertices.push_back(s[0])
	
	var surface_tool := SurfaceTool.new()
	surface_tool.create_from_arrays(arrays,Mesh.PRIMITIVE_POINTS)	
	_hair_debug.mesh = surface_tool.commit()
	
	if head_tris:
		vertices.clear()
		for v in head_tris["Vertices"]:
			vertices.push_back(v-head_origin)
		surface_tool.create_from_arrays(arrays,Mesh.PRIMITIVE_POINTS)
	
		_hair_debug.mesh = surface_tool.commit(_hair_debug.mesh)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1,1,1)
	_hair_debug.set_surface_override_material(0,mat)
	_hair_debug.visible = false
	
	if _hair_debug.get_surface_override_material_count() > 1:
		mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1,0,0)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_hair_debug.set_surface_override_material(1,mat)


###############################################################################
# Verlet compute shader
###############################################################################


func _exit_tree() -> void:
	# Make sure we clean up!
	RenderingServer.call_on_render_thread(_free_compute_resources)

var _rd: RenderingDevice

var _process_shader: RID
var _process_pipeline: RID

var _rest_pose_rid: RID
var _rest_pose_set: RID
var _curr_pose_rid: RID
var _curr_pose_set: RID
var _prev_pose_rid: RID
var _prev_pose_set: RID

func _initialize_compute_code(texture_size: Vector2i,buffer_data: PackedByteArray) -> void:
	print("_initialize_compute_code")
	# As this becomes part of our normal frame rendering,
	# we use our main rendering device here.
	if not _rd:
		_rd = RenderingServer.get_rendering_device()
	
	# Create our shader.
	if not _process_shader: 
		var dt := load_shader("res://modules/VAMActor/shaders/verlet.glsl")
		_process_shader = dt["Shader"]
		_process_pipeline = dt["Pipeline"]
	
	_rest_pose_rid = create_shader_texture(texture_size,buffer_data,_rest_pose_rid)
	_rest_pose_set = _create_uniform_set(_process_shader,_rest_pose_rid,0,_rest_pose_set)
	
	_curr_pose_rid = create_shader_texture(texture_size,buffer_data,_curr_pose_rid)
	_curr_pose_set = _create_uniform_set(_process_shader,_curr_pose_rid,1,_curr_pose_set)
	
	_prev_pose_rid = create_shader_texture(texture_size,buffer_data,_prev_pose_rid)
	_prev_pose_set = _create_uniform_set(_process_shader,_prev_pose_rid,2,_prev_pose_set)
	
	call_deferred("verlet_shader_initialized")


func _render_process(do_shift:bool,do_rotate:bool,shift: Vector3,rotate: Quaternion,gravity: Vector3,delta: float,leerp: float,lerp_multi: float,damping: float) -> void:
	if not (_process_pipeline.is_valid() and _curr_pose_set.is_valid() and _prev_pose_set.is_valid()):
		return
	
	var push_constant := PackedFloat32Array()
	push_constant.push_back(delta)
	push_constant.push_back(leerp)
	push_constant.push_back(lerp_multi)
	push_constant.push_back(damping)

	push_constant.push_back(24.0)
	push_constant.push_back(do_shift)
	push_constant.push_back(do_rotate)
	push_constant.push_back(0.0)
	
	push_constant.push_back(shift.x)
	push_constant.push_back(shift.y)
	push_constant.push_back(shift.z)
	push_constant.push_back(0.0)
	
	push_constant.push_back(rotate.x)
	push_constant.push_back(rotate.y)
	push_constant.push_back(rotate.z)
	push_constant.push_back(rotate.w)
	
	push_constant.push_back(gravity.x)
	push_constant.push_back(gravity.y)
	push_constant.push_back(gravity.z)
	push_constant.push_back(0.0)

	
	# Run our compute shader.
	var compute_list := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(compute_list,_process_pipeline)
	_rd.compute_list_bind_uniform_set(compute_list,_rest_pose_set,0)
	_rd.compute_list_bind_uniform_set(compute_list,_curr_pose_set,1)
	_rd.compute_list_bind_uniform_set(compute_list,_prev_pose_set,2)
	_rd.compute_list_set_push_constant(compute_list,push_constant.to_byte_array(),push_constant.size() * 4)
	_rd.compute_list_dispatch(compute_list,792,1,1)
	_rd.compute_list_end()
	
	# We don't need to sync up here, Godots default barriers will do the trick.
	# If you want the output of a compute shader to be used as input of
	# another computer shader you'll need to add a barrier:
	#rd.barrier(RenderingDevice.BARRIER_MASK_COMPUTE)


func load_shader(file_name: String) -> Dictionary:
	var shader_file := load(file_name)
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := _rd.shader_create_from_spirv(shader_spirv)
	var pipeline = _rd.compute_pipeline_create(shader)
	
	return {"Pipeline":pipeline,"Shader":shader}


func create_shader_texture(texture_size: Vector2i,buffer_data: PackedByteArray,free_rid: RID = RID()) -> RID:
	print("create_shader_texture")
	print(texture_size)
	print(buffer_data.size())
	
	if free_rid and free_rid.is_valid():
		_rd.free_rid(free_rid)
	
	var tf: RDTextureFormat = RDTextureFormat.new()
	tf.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	tf.width = texture_size.x
	tf.height = texture_size.y
	tf.depth = 1
	tf.array_layers = 1
	tf.mipmaps = 1
	tf.usage_bits = (
			RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
			RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
			RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT
		)
	return _rd.texture_create(tf,RDTextureView.new(),[buffer_data])


func _create_uniform_set(shader: RID,texture_rd: RID,uniform_set: int,free_rid: RID = RID()) -> RID:
	if free_rid:
		_rd.free_rid(free_rid)
	
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 0
	uniform.add_id(texture_rd)
	
	return _rd.uniform_set_create([uniform], shader, uniform_set)


func _free_compute_resources() -> void:
	# Note that our sets and pipeline are cleaned up automatically as they are dependencies :P
	if _rest_pose_rid: _rd.free_rid(_rest_pose_rid)
	#if _rest_pose_set and _rest_pose_set.is_valid(): _rd.free_rid(_rest_pose_set)
	if _curr_pose_rid: _rd.free_rid(_curr_pose_rid)
	#if _curr_pose_set and _curr_pose_set.is_valid(): _rd.free_rid(_curr_pose_set)
	if _prev_pose_rid: _rd.free_rid(_prev_pose_rid)
	#if _prev_pose_set and _prev_pose_set.is_valid(): _rd.free_rid(_prev_pose_set)
	
	if _process_shader: _rd.free_rid(_process_shader)
