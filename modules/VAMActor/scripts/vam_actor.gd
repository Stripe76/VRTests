@tool
class_name VAMActor extends Node3D

@export_group("Debug")
@export_tool_button("Generate","Reload") var generate_action = debug_generate_model
@export_tool_button("Load texture","Reload") var set_textures = debug_set_textures
@export var test_look_id := 2
@export var texture_id := 2

@export_group("")
@export_range(0,5) var eyes_color : float = 0:
	set(value):
		eyes_color = value
		if _mesh:
			_mesh.eye_template.set_eye_color(eyes_color)
	get:
		return eyes_color
#@onready var _genitals := $VAMVagina

@onready var target := $Target
@onready var _daz_model : Daz3DMesh = load("res://modules/VAMActor/resources/Genesis2Female.dsf")

var _look_id : int = -1
var _library : LibraryManager

var _mesh : VAMMesh
var _hair : VAMHair
var _skeleton : VAMSkeleton
var _person_controller : PersonController

var _mesh_thread : Thread
var _materials_thread : Thread
var _load_hair := false


func _ready() -> void:
	if Engine.is_editor_hint() and not get_parent() is Node3D:
		debug_generate_model()


func _process(delta: float) -> void:
	if _skeleton and false:
		var distance = (target.position - _skeleton.position).length()
		#print(distance)
		var ap : AnimationPlayer = $Actor
		if distance > 1.5 and not ap.is_playing():
			_skeleton.look_at(target.position)
			_skeleton.rotate(Vector3.UP,-PI)
			
			ap.play("walking_ik")
		if distance < 1.0 and ap.is_playing():
			ap.stop()


func _exit_tree():
	if _mesh_thread:
		_mesh_thread.wait_to_finish()
	if _materials_thread:
		_materials_thread.wait_to_finish()


func get_look_id( ) -> int:
	return _look_id


func get_animation_player() -> AnimationPlayer:
	return $Actor


func get_person_controller() -> PersonController:
	return _person_controller


func reset():
	if _person_controller:
		_person_controller.reset_pose()


func debug_generate_model():
	if not _library:
		_library = LibraryManager.new()
		_library.LoadData("/mnt/data/Games/Virtamate/AddonPackages/")
	if _library:
		load_look(_library,test_look_id,Vector3())


func debug_set_textures():
	if _library:
		load_materials_async(_library,texture_id)


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
	_skeleton = load_skeleton(_daz_model,library,lookID)
	_mesh = load_mesh(_daz_model,library,lookID,_skeleton.left_eye_bone_origin,_skeleton.right_eye_bone_origin)
	
	call_deferred("load_look_done",library,lookID,spawn_position,true)
	
	if signal_done:
		signal_done.call()


func load_look_done(library: LibraryManager,lookID: int,spawn_position: Vector3,async: bool):
	_person_controller = add_person_controller(_skeleton,_mesh)
	
	$Movements.person_controller = _person_controller
	
	#_skeleton.owner = self
	#_mesh.owner = self
	#_person_controller.owner = self
	
	if _load_hair:
		_hair = load("res://modules/VAMActor/vam_hair.tscn").instantiate( )
		_hair.name = "Hair"
		_hair._how_many = 4
		_hair.force_lerp = 0.5
		
		_hair.a_root = Color(0.326, 0.165, 0.0, 1.0)
		_hair.a_middle = Color(0.451, 0.214, 0.0, 1.0)
		_hair.a_tip = Color(0.808, 0.425, 0.0, 1.0)
		
		_hair.b_root = Color(0.0, 0.0, 0.0, 1.0)
		_hair.b_middle = Color(0.0, 0.0, 0.0, 1.0)
		_hair.b_tip = Color(0.0, 0.0, 0.0, 1.0)
		
		_hair.a_weight_root = 1
		_hair.a_weight_middle = 1
		_hair.a_weight_tip = 1
		
		_hair.b_weight_root = 1
		_hair.b_weight_middle = 1
		_hair.b_weight_tip = 1
		
		_hair.AB_distribution = -0.5
	
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
	
	add_child(skeleton)
	skeleton.owner = self
	skeleton.add_child(mesh)
	mesh.owner = self
	
	person_controller.initialize(self,skeleton,mesh)
	
	#if $Movements and $PersonController:
	#	$Movements.person_controller = $PersonController
	return person_controller


func load_skeleton(base_model: Daz3DMesh,library: LibraryManager,lookID: int) -> VAMSkeleton:
	var skeleton := VAMSkeleton.new()
	skeleton.name = "VAMSkeleton"
	
	skeleton.load_skeleton_new(base_model,library,lookID)
	
	return skeleton


func load_mesh(daz_model: Daz3DMesh,library: LibraryManager,lookID: int,left_eye_bone_origin: Vector3,right_eye_bone_origin: Vector3) -> VAMMesh:
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
