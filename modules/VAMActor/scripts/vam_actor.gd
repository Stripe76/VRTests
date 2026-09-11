@tool
class_name VAMActor extends Node3D

@export_tool_button("Generate","Add") var generate_action = generate_model

@export_range(0,5) var eyes_color : float = 0:
	set(value):
		eyes_color = value
		if _mesh:
			_mesh.eye_template.set_eye_color(eyes_color)
	get:
		return eyes_color
#@onready var _genitals := $VAMVagina

@onready var _daz_model : Daz3DMesh = load("res://modules/VAMActor/resources/Genesis2Female.dsf")

var _look_id : int = -1
var _library : LibraryManager

var _mesh : VAMMesh
var _hair : VAMHair
var _skeleton : VAMSkeleton
var _person_controller : PersonController

var _mesh_thread : Thread
var _materials_thread : Thread


func _ready() -> void:
	if Engine.is_editor_hint() and not get_parent() is Node3D:
		generate_model()


func _exit_tree():
	if _mesh_thread:
		_mesh_thread.wait_to_finish()
	if _materials_thread:
		_materials_thread.wait_to_finish()


func get_look_id( ) -> int:
	return _look_id


func get_animation_player() -> AnimationPlayer:
	return $Actor


func reset():
	if _person_controller:
		_person_controller.reset_pose()


func generate_model():
	if not _library:
		_library = LibraryManager.new()
		_library.LoadData("/mnt/data/Games/Virtamate/AddonPackages/")
	if _library:
		load_look(_library,2,Vector3()) # Barbie


func load_look(library: LibraryManager,lookID: int,spawn_position: Vector3):
	_look_id = lookID
	
	load_look_pre()
	load_look_sync(library,lookID,spawn_position)


var _mutex = Mutex.new()
var _loading_scene := false
var _loading_material := false
func load_look_async(library: LibraryManager,lookID: int,spawn_position: Vector3,signal_done: Callable = Callable()):
	_mutex.lock()
	if _loading_scene or _loading_material:
		return
	_loading_scene = true
	_mutex.unlock()
	
	_look_id = lookID
	
	if _mesh_thread:
		_mesh_thread.wait_to_finish()
	else:
		_mesh_thread = Thread.new()
	
	load_look_pre()
	
	_mesh_thread.start(load_look_sync.bind(library,lookID,spawn_position,signal_done))


func load_look_pre():
	if _mesh:
		_skeleton.remove_child(_mesh)
		_mesh.queue_free()
		_mesh = null
	if _skeleton:
		remove_child(_skeleton)
		_skeleton.queue_free()
		_skeleton = null
	if _person_controller:
		remove_child(_person_controller)
		_person_controller.queue_free()
		_person_controller = null


func load_look_sync(library: LibraryManager,lookID: int,spawn_position: Vector3,signal_done: Callable = Callable()):
	_skeleton = load_skeleton_new(_daz_model,library,lookID)
	_mesh = load_mesh_new(_daz_model,library,lookID,_skeleton.left_eye_bone_origin,_skeleton.right_eye_bone_origin)
	
	call_deferred("load_look_done",library,lookID,spawn_position,true)
	
	if signal_done:
		signal_done.call()


func load_look_done(library: LibraryManager,lookID: int,spawn_position: Vector3,async: bool):
	add_child(_skeleton)
	_skeleton.add_child(_mesh)
	
	_person_controller = add_person_controller(_skeleton,_mesh)
	
	_skeleton.owner = self
	_mesh.owner = self
	_person_controller.owner = self
	
	_hair = load("res://modules/VAMActor/vam_hair.tscn").instantiate( )
	_hair.name = "Hair"
	
	#_hair = VAMHair.new()
	#_hair.name = "Hair"
	#_hair._how_many = 4
	#_hair.a_root = Color(0.539, 0.295, 0.046, 1.0)
	#_hair.a_middle = Color(0.539, 0.295, 0.046, 1.0)
	#_hair.a_tip = Color(0.539, 0.295, 0.046, 1.0)
	#_hair.b_root = Color(0.539, 0.295, 0.046, 1.0)
	#_hair.b_middle = Color(0.539, 0.295, 0.046, 1.0)
	#_hair.b_tip = Color(0.539, 0.295, 0.046, 1.0)
	#_hair.a_weight_root = 1
	#_hair.a_weight_middle = 1
	#_hair.a_weight_tip = 1
	#_hair.b_weight_root = 1
	#_hair.b_weight_middle = 1
	#_hair.b_weight_tip = 1
	#_hair.AB_distribution = -0.5
	var hair_file = "/mnt/data/Projects/Godot/library/Barbie/Custom/Hair/Female/RenVR/Barbie.vab"
	load_hair(hair_file,_mesh.head_tris)
	
	position = spawn_position
	
	if async:
		load_materials_async(library,lookID)
	else:
		load_materials(library,lookID)
	
	#_mutex.lock()
	_loading_scene = false
	#_mutex.unlock()


func load_materials(library: LibraryManager,lookID: int):
	_mesh.load_materials_new(library,lookID)
	
	#if _genitals and _genitals._mesh_material:
		#_genitals._mesh_material.set_shader_parameter("texture_albedo",_mesh.genitals_material.get_shader_parameter("texture_albedo"))
		#_genitals._mesh_material.set_shader_parameter("texture_normal",_mesh.genitals_material.get_shader_parameter("texture_normal"))
		#_genitals._mesh_material.set_shader_parameter("standard_decal",_mesh.genitals_material.get_shader_parameter("standard_decal"))
	
	#_mutex.lock()
	_loading_material = false
	#_mutex.unlock()


func load_materials_async(library: LibraryManager,lookID: int):
	_mutex.lock()
	if _loading_material:
		return
	_loading_material = true
	_mutex.unlock()
	
	if _materials_thread:
		_materials_thread.wait_to_finish()
	else:
		_materials_thread = Thread.new()
	_materials_thread.start(load_materials.bind(library,lookID))


func add_person_controller(skeleton: VAMSkeleton,mesh: VAMMesh )-> PersonController:
	var person_controller = PersonController.new(skeleton)
	person_controller.name = "PersonController"
	
	person_controller._left_eye_aabb = mesh.left_eye_aabb
	person_controller._right_eye_aabb = mesh.right_eye_aabb

	add_child(person_controller)
	person_controller.owner = self
	
	person_controller.initialize(self,skeleton)
	
	#if $Movements and $PersonController:
	#	$Movements.person_controller = $PersonController
	return person_controller


func load_skeleton_new(base_model: Daz3DMesh,library: LibraryManager,lookID: int) -> VAMSkeleton:
	var skeleton := VAMSkeleton.new()
	skeleton.name = "VAMSkeleton"
	
	skeleton.load_skeleton_new(base_model,library,lookID)
	
	return skeleton


func load_mesh_new(daz_model: Daz3DMesh,library: LibraryManager,lookID: int,left_eye_bone_origin: Vector3,right_eye_bone_origin: Vector3) -> VAMMesh:
	var vam_mesh = VAMMesh.new()
	vam_mesh.name = "VAMMesh"
	
	vam_mesh.left_eye_bone = left_eye_bone_origin + Vector3(0,0,-0.005)
	vam_mesh.right_eye_bone = right_eye_bone_origin+ Vector3(0,0,-0.005)
	
	vam_mesh.load_mesh_new(daz_model,library,lookID)
	vam_mesh.mesh = vam_mesh.full_body
	
	return vam_mesh


func load_hair(hair_file: String,head_tris: Dictionary):
	var parent : Node3D = _skeleton.find_child("head")
	if not parent:
		parent = self
	
	parent.add_child(_hair)
	_hair.owner = self
	
	head_tris["Origin"] = parent.position
	print("Parent position: ",parent.position)
	
	_hair.generate_hair(hair_file,head_tris)
