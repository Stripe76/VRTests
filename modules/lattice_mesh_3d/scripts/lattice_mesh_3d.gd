@tool
extends MeshInstance3D

@export_tool_button("Generate","Reload") var generate = generate_grid
@export_tool_button("Switch meshes","Reload") var switch = switch_meshes

@export var set_spring : float = 0.5
@export var set_damping : float = 0.65

@export_group("Grid configuration")
@export var _size := Vector3(.10,.10,.10)
@export var _offset := Vector3(-.05,-.05,-.05)
@export var _particles : Vector3i = Vector3i(1,1,1)

var _user_mesh : Mesh
var _grid_mesh : Mesh
var _mesh_material : ShaderMaterial

func _ready() -> void:
	_mesh_material = ShaderMaterial.new()
	_mesh_material.shader = load("res://modules/lattice_mesh_3d/shaders/lattice.gdshader")
	
	if mesh:
		generate_grid()


var _last_position : Vector3
var _last_rotation : Quaternion
func _process(delta: float) -> void:
	# Gravity vector for current mesh rotation
	var mesh_inv_transform = global_transform.affine_inverse()
	var gravity = mesh_inv_transform.basis * Vector3(0, -9.8, 0)
	
	# Movement vector
	var shift : Vector3
	var do_shift := false
	if _last_position != global_position and not _last_position.is_zero_approx():
		do_shift = true
		shift = (global_position - _last_position)
		shift = mesh_inv_transform.basis * shift
	_last_position = global_position
	
	# Rotation vector
	var do_rotate := true
	var current_rot = global_transform.basis.get_rotation_quaternion()
	var delta_rotate = current_rot.inverse() * _last_rotation
	_last_rotation = current_rot
	
	_render_process.call_deferred(delta,do_shift,do_rotate,gravity,shift,delta_rotate,set_spring,set_damping,1)
	
	# To update the editor view
	global_transform = global_transform


func switch_meshes():
	if mesh != _grid_mesh:
		_user_mesh = mesh
		mesh = _grid_mesh
	else:
		mesh = _user_mesh


func generate_grid():
	if mesh:
		var aabb := mesh.get_aabb()
		_size = aabb.size
		_offset = aabb.get_center()
		var data := generate_mesh(_size,_offset,_particles)
		
		if Engine.is_editor_hint():
			_grid_mesh = create_mesh(data)
			_grid_mesh.surface_set_material(0,_mesh_material)
		
		for i in mesh.get_surface_count():
			print("material")
			mesh.surface_set_material(i,_mesh_material)
		
		create_verlet_shader(data)


func create_verlet_shader(arrays_data: Dictionary):
	print("create_verlet_shader")
	var texture_size : Vector3i = arrays_data["ImageSize"]
	var image_data : PackedByteArray = arrays_data["ImageData"]
	
	# TODO: should wait somehow?
	RenderingServer.call_on_render_thread(_initialize_compute_code.bind(texture_size,image_data))


func verlet_shader_initialized():
	print("verlet_shader_initialized")
	var image : Texture3DRD = _mesh_material.get_shader_parameter("data_points")
	if not image:
		image = Texture3DRD.new()
	image.texture_rd_rid = _buffers[CURRENT]
	_mesh_material.set_shader_parameter("grid_res",_particles.x*4)
	_mesh_material.set_shader_parameter("grid_offset",_offset)
	_mesh_material.set_shader_parameter("grid_size_meters",_size)
	_mesh_material.set_shader_parameter("data_points",image)


func generate_mesh(size: Vector3,offset: Vector3,particles: Vector3i) -> Dictionary:
	print("generate_mesh")
	print(size)
	print(offset)
	print(particles)
	
	particles *= 4
	
	var indices := PackedInt32Array( )
	var vertices := PackedVector3Array( )
	var colors := PackedColorArray()
	var customs0 := PackedFloat32Array()
	var image_data := PackedVector4Array()
	
	var index := 0
	@warning_ignore("integer_division")
	var half_x := particles.x / 2
	@warning_ignore("integer_division")
	var half_y := particles.y / 2
	@warning_ignore("integer_division")
	var half_z := particles.z / 2
	for z in particles.z:
		for y in particles.y:
			for x in particles.x:
				var vertex = offset + Vector3((x-half_x) as float / particles.x * size.x,(y-half_y) as float / particles.y * size.y,(z-half_z) as float / particles.z * size.z)
				vertices.push_back(vertex)
				
				if x > 0:
					indices.push_back(index-1)
					indices.push_back(index)
				if y > 0:
					indices.push_back(index-particles.x)
					indices.push_back(index)
				if z > 0:
					indices.push_back(index-particles.x*particles.y)
					indices.push_back(index)
				
				colors.append(Color(x as float / particles.x,y as float / particles.y,z as float / particles.z))
				
				customs0.push_back(x)
				customs0.push_back(y)
				customs0.push_back(z)
				customs0.push_back(0)
				
				image_data.push_back(Vector4(vertex.x,vertex.y,vertex.z,size.x / particles.x))
				index += 1
	
	return {
		"Vertices":vertices,
		#"Normals":normals,
		"Colors":colors,
		"Indices": indices,
		"Customs0": customs0,
		#"Customs1": customs1,
		#"UVs" : uvs,
		"ImageSize" : particles,
		"ImageData" : image_data.to_byte_array(),
		}


func create_mesh(arrays_data: Dictionary) -> ArrayMesh:
	var surface_tool := SurfaceTool.new( )
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_INDEX] = arrays_data["Indices"]
	arrays[Mesh.ARRAY_VERTEX] = arrays_data["Vertices"]
	#arrays[Mesh.ARRAY_NORMAL] = arrays_data["Normals"]
	arrays[Mesh.ARRAY_COLOR] = arrays_data["Colors"]
	arrays[Mesh.ARRAY_CUSTOM0] = arrays_data["Customs0"]
	#arrays[Mesh.ARRAY_CUSTOM1] = arrays_data["Customs1"]
	#arrays[Mesh.ARRAY_TEX_UV] = arrays_data["UVs"]
	
	surface_tool.create_from_arrays(arrays,Mesh.PRIMITIVE_LINES)
	return surface_tool.commit( )

###############################################################################
# Verlet compute shader
###############################################################################

const SHADER := 0
const PIPELINE := 1
const CURRENT := 2
const PREVIOUS := 3
const TEXTURE_SIZE := 4

func _exit_tree() -> void:
	# Make sure we clean up!
	RenderingServer.call_on_render_thread(_free_compute_resources)

var _rd: RenderingDevice

var _buffers : Dictionary
var _verlet_shader : Dictionary
var _constraints_shader : Dictionary


func _initialize_compute_code(texture_size: Vector3i,buffer_data: PackedByteArray) -> void:
	print("_initialize_compute_code")
	# As this becomes part of our normal frame rendering,
	# we use our main rendering device here.
	if not _rd:
		_rd = RenderingServer.get_rendering_device()
	
	if texture_size % 4 != Vector3i():
		push_error("Texture size not multiple of 4")
	if not _verlet_shader:
		_verlet_shader = load_shader("res://modules/lattice_mesh_3d/shaders/verlet.glsl")
	_verlet_shader[TEXTURE_SIZE] = texture_size
	if not _constraints_shader:
		_constraints_shader = load_shader("res://modules/lattice_mesh_3d/shaders/constraints.glsl")
	_constraints_shader[TEXTURE_SIZE] = texture_size
	
	#_buffers[CURRENT] = RID()
	#_buffers[PREVIOUS] = RID()
	
	_buffers[CURRENT] = create_shader_texture(texture_size,buffer_data,_buffers[CURRENT] if _buffers.has(CURRENT) else RID())
	_buffers[PREVIOUS] = create_shader_texture(texture_size,buffer_data,_buffers[PREVIOUS] if _buffers.has(PREVIOUS) else RID())
	
	_verlet_shader[CURRENT] = _create_uniform_set(_verlet_shader[SHADER],_buffers[CURRENT],0)
	_verlet_shader[PREVIOUS] = _create_uniform_set(_verlet_shader[SHADER],_buffers[PREVIOUS],0)
	_constraints_shader[CURRENT] = _create_uniform_set(_constraints_shader[SHADER],_buffers[CURRENT],0)
	_constraints_shader[PREVIOUS] = _create_uniform_set(_constraints_shader[SHADER],_buffers[PREVIOUS],0)
	
	#call_deferred("verlet_shader_initialized")
	verlet_shader_initialized( )


func _render_process(delta: float,
					do_shift:bool,
					do_rotate:bool,
					gravity: Vector3,
					shift: Vector3,
					delta_rotate: Quaternion,
					spring: float,
					damping: float,
					iterations: int) -> void:
	var texture_size : Vector3i = _verlet_shader[TEXTURE_SIZE]
	@warning_ignore("integer_division")
	var workgroups := texture_size / 4
	
	var push_constant := PackedFloat32Array()
	push_constant.push_back(delta)
	push_constant.push_back(spring)
	push_constant.push_back(damping)
	push_constant.push_back(do_shift)

	push_constant.push_back(do_rotate)
	push_constant.push_back(0.0)
	push_constant.push_back(0.0)
	push_constant.push_back(0.0)
	
	add_push_constant(push_constant,texture_size)
	add_push_constant(push_constant,shift)
	add_push_constant(push_constant,delta_rotate)
	add_push_constant(push_constant,gravity)
	
	# Run our compute shader.
	var compute_list := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(compute_list,_verlet_shader[PIPELINE])
	_rd.compute_list_bind_uniform_set(compute_list,_verlet_shader[CURRENT],0)
	_rd.compute_list_bind_uniform_set(compute_list,_verlet_shader[PREVIOUS],1)
	_rd.compute_list_set_push_constant(compute_list,push_constant.to_byte_array(),push_constant.size() * 4)
	for i in iterations:
		_rd.compute_list_dispatch(compute_list,workgroups.x,workgroups.y,workgroups.z)
	_rd.compute_list_end()
	
	compute_list = _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(compute_list,_constraints_shader[PIPELINE])
	_rd.compute_list_bind_uniform_set(compute_list,_constraints_shader[CURRENT],0)
	_rd.compute_list_bind_uniform_set(compute_list,_constraints_shader[PREVIOUS],1)
	_rd.compute_list_set_push_constant(compute_list,push_constant.to_byte_array(),push_constant.size() * 4)
	for i in iterations:
		_rd.compute_list_dispatch(compute_list,workgroups.x,workgroups.y,workgroups.z)
	_rd.compute_list_end()
	
	# We don't need to sync up here, Godots default barriers will do the trick.
	# If you want the output of a compute shader to be used as input of
	# another computer shader you'll need to add a barrier:


func load_shader(file_name: String) -> Dictionary:
	var shader_file := load(file_name)
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := _rd.shader_create_from_spirv(shader_spirv)
	var pipeline = _rd.compute_pipeline_create(shader)
	
	return {PIPELINE:pipeline,SHADER:shader}


func create_shader_texture(texture_size: Vector3i,buffer_data: PackedByteArray,free_rid: RID = RID()) -> RID:
	print("create_shader_texture")
	print(texture_size)
	print(buffer_data.size())
	
	if free_rid and free_rid.is_valid():
		_rd.free_rid(free_rid)
	
	var tf: RDTextureFormat = RDTextureFormat.new()
	tf.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	tf.texture_type = RenderingDevice.TEXTURE_TYPE_3D
	tf.width = texture_size.x
	tf.height = texture_size.y
	tf.depth = texture_size.z
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
	print("_free_compute_resources")
	if _buffers[CURRENT]: _rd.free_rid(_buffers[CURRENT])
	if _buffers[PREVIOUS]: _rd.free_rid(_buffers[PREVIOUS])
	
	if _verlet_shader and _verlet_shader[SHADER]: _rd.free_rid(_verlet_shader[SHADER])
	if _constraints_shader and _constraints_shader[SHADER]: _rd.free_rid(_constraints_shader[SHADER])


func add_push_constant(constants: PackedFloat32Array,value):
	if value is Vector3:
		constants.push_back(value.x)
		constants.push_back(value.y)
		constants.push_back(value.z)
		constants.push_back(0.0)
	elif value is Vector3i:
		constants.push_back(value.x)
		constants.push_back(value.y)
		constants.push_back(value.z)
		constants.push_back(0)
	elif value is Vector4:
		constants.push_back(value.x)
		constants.push_back(value.y)
		constants.push_back(value.z)
		constants.push_back(value.w)
	elif value is Quaternion:
		constants.push_back(value.x)
		constants.push_back(value.y)
		constants.push_back(value.z)
		constants.push_back(value.w)
	else:
		constants.push_back(value)
