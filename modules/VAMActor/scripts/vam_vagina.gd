@tool
class_name VAMVagina extends MeshInstance3D

@export_tool_button("Generate","Reload") var generate = generate_grid

@export_range(0,1.1) var set_stretch : float = 0.0
@export var set_damping : float = 0.65

@export_group("Left side")
@export var left_size := Vector3(.10,.10,.10)
@export var left_offset := Vector3(-.05,-.05,-.05)
@export var left_particles : Vector3i = Vector3i(1,1,1)

@export_group("Right side")
@export var right_size := Vector3(.10,.10,.10)
@export var right_offset := Vector3(-.05,-.05,-.05)
@export var right_particles : Vector3i = Vector3i(1,1,1)

var _rd: RenderingDevice

var _user_mesh : Mesh
var _mesh_material : ShaderMaterial

var _shape_mesh : MeshInstance3D
var _shape_material : ShaderMaterial

var _left_labia: GridLattice
var _right_labia: GridLattice


var _editor_owner
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			_editor_owner = owner
			#owner = null
			mesh = null
		NOTIFICATION_EDITOR_POST_SAVE:
			#owner = _editor_owner
			mesh = _user_mesh


func _ready() -> void:
	_shape_mesh = MeshInstance3D.new()
	_shape_mesh.name = "ShapeMesh"
	_shape_material = ShaderMaterial.new()
	_shape_material.shader = load("res://modules/VAMActor/shaders/vagina_shape.gdshader")
	
	add_child(_shape_mesh)
	_shape_mesh.owner = self;
	
	_mesh_material = ShaderMaterial.new()
	_mesh_material.shader = load("res://modules/VAMActor/shaders/vagina.gdshader")
	
	if mesh:
		mesh.surface_set_material(0,_mesh_material)
	
	#generate_grid()


func _process(delta: float) -> void:
	if _left_labia:
		_left_labia._render_process.call_deferred(delta,set_stretch,1)
	if _right_labia:
		_right_labia._render_process.call_deferred(delta,set_stretch,1)
	
	# To update the editor view
	#global_transform = global_transform


func _exit_tree() -> void:
	# Make sure we clean up!
	if _left_labia:
		RenderingServer.call_on_render_thread(_left_labia._free_compute_resources)
	if _right_labia:
		RenderingServer.call_on_render_thread(_right_labia._free_compute_resources)


func set_genital_mesh(mesh_to_set: Mesh):
	print("set_genital_mesh")
	mesh = mesh_to_set
	
	var copy_shader = mesh.surface_get_material(0)
	if copy_shader is ShaderMaterial:
		_mesh_material.set_shader_parameter("texture_albedo",copy_shader.get_shader_parameter("texture_albedo"))
		_mesh_material.set_shader_parameter("texture_normal",copy_shader.get_shader_parameter("texture_normal"))
		_mesh_material.set_shader_parameter("standard_decal",copy_shader.get_shader_parameter("standard_decal"))
		
	mesh.surface_set_material(0,_mesh_material)
	_user_mesh = mesh
	
	if Engine.is_editor_hint():
		if is_zero_approx($Top.position.y): $Top.position.y = left_offset.y
		if is_zero_approx($Bottom.position.y): $Bottom.position.y = left_offset.y
		if is_zero_approx($Left.position.y): $Left.position.y = left_offset.y
		if is_zero_approx($Right.position.y): $Right.position.y = left_offset.y
		if is_zero_approx($Center.position.y): $Center.position.y = left_offset.y
	
	generate_grid()


func generate_grid():
	var aabb := mesh.get_aabb()
	left_size = Vector3($Right.position.x-$Center.position.x,aabb.size.y,$Top.position.z-$Bottom.position.z)
	left_offset = Vector3($Center.position.x,aabb.position.y,$Bottom.position.z)

	right_size = Vector3($Center.position.x-$Left.position.x,aabb.size.y,$Top.position.z-$Bottom.position.z)
	right_offset = Vector3($Center.position.x-right_size.x+0.0025,aabb.position.y,$Bottom.position.z)
	
	var left_data := generate_shape_data(left_size,left_offset)
	var right_data := generate_shape_data(right_size,right_offset)
	
	if Engine.is_editor_hint():
		_shape_mesh.mesh = create_mesh(right_data)
		_shape_mesh.mesh.surface_set_material(0,_shape_material)
	if mesh:
		mesh.surface_set_material(0,_mesh_material)
	
	if not _rd:
		_rd = RenderingServer.get_rendering_device()
	if not _left_labia:
		_left_labia = GridLattice.new(_rd,"res://modules/VAMActor/shaders/compute/left_labia.glsl")
	if not _right_labia:
		_right_labia = GridLattice.new(_rd,"res://modules/VAMActor/shaders/compute/right_labia.glsl")
	create_verlet_shader(right_size,right_offset,_right_labia,right_data)
	create_verlet_shader(left_size,left_offset,_left_labia,left_data)


func create_verlet_shader(size: Vector3,offset: Vector3,lattice: GridLattice,arrays_data: Dictionary):
	print("create_verlet_shader")
	var texture_size : Vector3i = arrays_data["DataSize"]
	var base_data : PackedByteArray = arrays_data["BaseData"]
	var pose_data : PackedByteArray = arrays_data["PoseData"]
	var grid_data : PackedByteArray = arrays_data["GridData"]
	
	# TODO: should wait somehow?
	#RenderingServer.call_on_render_thread(_initialize_compute_code.bind(texture_size,pose_data,image_data))
	lattice._initialize_compute_code(size,offset,texture_size,base_data,pose_data,grid_data,verlet_shader_initialized)


func verlet_shader_initialized(lattice: GridLattice):
	print("verlet_shader_initialized")
	if lattice == _right_labia:
		var image : Texture3DRD = _shape_material.get_shader_parameter("data_points")
		if not image:
			image = Texture3DRD.new()
		image.texture_rd_rid = lattice._buffers[VERTEX]
		_shape_material.set_shader_parameter("data_points",image)
	
	if lattice == _left_labia:
		print("_left_labia")
		var image = _mesh_material.get_shader_parameter("lattice_A")
		if not image:
			image = Texture3DRD.new()
		image.texture_rd_rid = lattice._buffers[VERTEX]
		print("Size: ",lattice._size)
		print("Offset: ",lattice._offset)
		_mesh_material.set_shader_parameter("lattice_size_A",lattice._size)
		_mesh_material.set_shader_parameter("lattice_offset_A",lattice._offset)
		_mesh_material.set_shader_parameter("lattice_A",image)
	if lattice == _right_labia:
		print("_right_labia")
		var image = _mesh_material.get_shader_parameter("lattice_B")
		if not image:
			image = Texture3DRD.new()
		image.texture_rd_rid = lattice._buffers[VERTEX]
		print("Size: ",lattice._size)
		print("Offset: ",lattice._offset)
		_mesh_material.set_shader_parameter("lattice_size_B",lattice._size)
		_mesh_material.set_shader_parameter("lattice_offset_B",lattice._offset)
		_mesh_material.set_shader_parameter("lattice_B",image)


func generate_shape_data(size: Vector3,offset: Vector3) -> Dictionary:
	print("generate_shape_data")
	
	var indices := PackedInt32Array( )
	var vertices := PackedVector3Array( )
	var normals := PackedVector3Array( )
	var colors := PackedColorArray()
	var customs0 := PackedFloat32Array()
	var base_data := PackedVector4Array()
	var pose_data := PackedVector4Array()
	var grid_data := PackedVector4Array()
	
	var parts := [
		Vector4(.02,.10,0,0),
		Vector4(.005,.005,0.1,-.02),
		Vector4(.005,.005,0.2,.0),
		Vector4(.005,.005,0.3,.0),
		
		Vector4(.005,.005,0.4,.0),
		Vector4(.005,.005,0.6,.0),
		Vector4(.005,.005,0.8,.0),
		Vector4(.005,.005,1.0,.0),
	]
	var width = 8
	var depth = 8
	var height = parts.size()
	
	for z in depth:
		for y in height:
			var vertex := Vector3(0,(y as float / (height-1)) * size.y,(z as float / (depth-1)) * size.z )
			
			for x in width:
				vertices.push_back(offset + vertex + Vector3((x as float / (width-1))*size.x,0,0))
				#print(offset + vertex + w * Vector3((size.x) / width,0,0))
				normals.push_back(-vertex.normalized())
			
				customs0.push_back(x)
				customs0.push_back(y)
				customs0.push_back(z)
				customs0.push_back(0)
			#print("-------------------------")
	
	for y in height:
		for z in depth:
			var a : float = (z as float / (depth-1)) * (PI)
			#print(z,": ",a*(180/PI))
			var base := Vector3(0,(y as float / (height-1)) * size.y,(z as float / (depth-1)) * size.z )
			var pose := Vector3( sin(a),0,-cos(a) )
			
			base_data.push_back(Vector4(base.x,base.y,base.z,abs(sin(a))))
			pose_data.push_back(Vector4(pose.x,pose.y,pose.z,abs(sin(a))))
	
	for z in depth:
		for y in height:
			for x in width:
				var v := Vector3(vertices[z*(height*width)+(y*width+x)]);
				grid_data.push_back(Vector4(v.x,v.y,v.z,0))
				indices.push_back(z*(height*width)+(y*width+x))
	
	return {
		"Vertices": vertices,
		"Normals": normals,
		"Colors": colors,
		"Indices": indices,
		"Customs0": customs0,
		#"Customs1": customs1,
		#"UVs" : uvs,
		"DataSize" : Vector3i(width,height,depth),
		"BaseData" : base_data.to_byte_array(),
		"PoseData" : pose_data.to_byte_array(),
		"GridData" : grid_data.to_byte_array(),
		}


func create_mesh(arrays_data: Dictionary) -> ArrayMesh:
	var surface_tool := SurfaceTool.new( )
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_INDEX] = arrays_data["Indices"]
	arrays[Mesh.ARRAY_VERTEX] = arrays_data["Vertices"]
	arrays[Mesh.ARRAY_NORMAL] = arrays_data["Normals"]
	arrays[Mesh.ARRAY_COLOR] = arrays_data["Colors"]
	arrays[Mesh.ARRAY_CUSTOM0] = arrays_data["Customs0"]
	#arrays[Mesh.ARRAY_CUSTOM1] = arrays_data["Customs1"]
	#arrays[Mesh.ARRAY_TEX_UV] = arrays_data["UVs"]
	
	surface_tool.create_from_arrays(arrays,Mesh.PRIMITIVE_POINTS)
	return surface_tool.commit( )

###############################################################################
# Verlet compute shader
###############################################################################

const SHADER := 0
const PIPELINE := 1
const TEXTURE_SIZE := 2
const BASE := 3
const POSE := 4
const VERTEX := 5


class GridLattice:
	var _rd : RenderingDevice
	var _shader_file : String
	
	var _shader : Dictionary
	var _buffers : Dictionary

	var _size: Vector3
	var _offset: Vector3
	
	func _init(rd : RenderingDevice,shader_file: String) -> void:
		_rd = rd
		_shader_file = shader_file
		
		
	func _initialize_compute_code(size: Vector3,offset: Vector3,texture_size: Vector3i,base_data: PackedByteArray,pose_data: PackedByteArray,grid_data: PackedByteArray,shader_initialized: Callable) -> void:
		print("_initialize_compute_code")
		# As this becomes part of our normal frame rendering,
		# we use our main rendering device here.
		#if not _rd:
		#	_rd = RenderingServer.get_rendering_device()
		
		_size = size
		_offset = offset
		
		if not _shader:
			_shader = load_shader(_shader_file);
			#_shader = load_shader("res://modules/VAMActor/shaders/compute/vagina_shape.glsl");
		_shader[TEXTURE_SIZE] = texture_size
		
		var base_size = Vector2i(texture_size.z,texture_size.y)
		_buffers[BASE] = create_shader_texture_2d(base_size,base_data,_buffers[BASE] if _buffers.has(BASE) else RID())
		_buffers[POSE] = create_shader_texture_2d(base_size,pose_data,_buffers[POSE] if _buffers.has(POSE) else RID())
		
		#var vertex_size = Vector3i(20,texture_size.x,texture_size.y)
		_buffers[VERTEX] = create_shader_texture_3d(texture_size,grid_data,_buffers[VERTEX] if _buffers.has(VERTEX) else RID())
		
		_shader[BASE] = _create_uniform_set(_shader[SHADER],_buffers[BASE],0)
		_shader[POSE] = _create_uniform_set(_shader[SHADER],_buffers[POSE],1)
		_shader[VERTEX] = _create_uniform_set(_shader[SHADER],_buffers[VERTEX],2)
		
		#call_deferred("verlet_shader_initialized")
		shader_initialized.call(self)
		#verlet_shader_initialized( )
	
	
	func _render_process(delta: float,stretch:float,iterations: int) -> void:
		var texture_size : Vector3i = _shader[TEXTURE_SIZE]
		@warning_ignore("integer_division")
		var workgroups := texture_size
		
		var push_constant := PackedFloat32Array()
		push_constant.push_back(stretch)
		push_constant.push_back(0)
		push_constant.push_back(0)
		push_constant.push_back(0)
		#print("_size: ",_size)
		add_push_constant(push_constant,_size)
		#print("_offset: ",_offset)
		add_push_constant(push_constant,_offset)
		
		# Run our compute shader.
		var compute_list := _rd.compute_list_begin()
		_rd.compute_list_bind_compute_pipeline(compute_list,_shader[PIPELINE])
		_rd.compute_list_bind_uniform_set(compute_list,_shader[BASE],0)
		_rd.compute_list_bind_uniform_set(compute_list,_shader[POSE],1)
		_rd.compute_list_bind_uniform_set(compute_list,_shader[VERTEX],2)
		_rd.compute_list_set_push_constant(compute_list,push_constant.to_byte_array(),push_constant.size() * 4)
		_rd.compute_list_dispatch(compute_list,8,8,1)
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
	
	
	func create_shader_texture_2d(texture_size: Vector2i,buffer_data: PackedByteArray,free_rid: RID = RID()) -> RID:
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
		tf.depth = 0
		tf.array_layers = 1
		tf.mipmaps = 1
		tf.usage_bits = (
				RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
				RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
				RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT |
				RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
			)
		return _rd.texture_create(tf,RDTextureView.new(),[buffer_data])


	func create_shader_texture_3d(texture_size: Vector3i,buffer_data: PackedByteArray,free_rid: RID = RID()) -> RID:
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
				RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
				RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
				RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT |
				RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
			)
		return _rd.texture_create(tf,RDTextureView.new(),[buffer_data] if buffer_data.size() > 0 else [])


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
		for b in _buffers:
			_rd.free_rid(b)
		
		if _shader and _shader[SHADER]: _rd.free_rid(_shader[SHADER])
	
	
	func add_push_constant(constants: PackedFloat32Array,value):
		if value is Vector2i:
			constants.push_back(value.x)
			constants.push_back(value.y)
			#constants.push_back(0)
			#constants.push_back(0)
		elif value is Vector3:
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
