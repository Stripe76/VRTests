@tool
class_name VAMActor extends Node3D

@export_group("Debug")
@export_tool_button("Generate","Reload") var generate_action = debug_generate_model
@export_tool_button("Load texture","Reload") var set_textures = debug_set_textures
@export var test_look_id := 2
@export var texture_id := 2
@export_tool_button("Ragdoll","PhysicalBone3D") var set_ragdoll = debug_set_ragdoll

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

var _person_id : int = -1
var _look_id : int = -1

var _mesh : VAMMesh
var _skeleton : VAMSkeleton
var _person_controller : PersonController

var _mesh_thread : Thread
var _materials_thread : Thread

var _mutex = Mutex.new()
var _loading_scene := false
var _loading_material := false

var _hairs : Array = []
var _clothes : Array = []

signal look_loaded
signal hairs_list_changed
signal clothes_list_changed

# Debug
var _library : LibraryManager
var _ragdoll_active := false


func with(person_id: int) -> VAMActor:
	_person_id = person_id
	
	return self


func _ready() -> void:
	if Engine.is_editor_hint() and not get_parent() is Node3D:
		debug_generate_model()
	else:
		$Floor.queue_free()


func _exit_tree():
	if _mesh_thread and _mesh_thread.is_alive():
		_mesh_thread.wait_to_finish()
	if _materials_thread and _materials_thread.is_alive():
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
		_library.LoadData("/mnt/data/Projects/Godot/library/")
	if _library:
		load_look(_library,test_look_id)


func debug_set_textures():
	if _library and _mesh:
		_mesh.load_materials_async(_library,texture_id)


func debug_set_ragdoll():
	if _person_controller:
		_ragdoll_active = not _ragdoll_active
		
		$PhysicsToggle.activate_physics = true
		
		_person_controller.enable_ragdoll = _ragdoll_active


func get_focus_camera_parent(bone: String):
	if _skeleton:
		return _skeleton.find_child(bone)
	return null


func walk_to(glb_position: Vector3):
	if _person_controller:
		_person_controller.enable_X = true
		_person_controller.enable_Y = true
		_person_controller.enable_Z = true
		_person_controller.enable_rotation = true
		
		$Target.global_position = glb_position
		$Movements/Walking.start()
func stop_walking():
	$Movements/Walking.stop()


func get_hairs() -> Array:
	return _hairs
func add_hair(library: LibraryManager,hair_id: int,remove_if_present: bool):
	var parent : Node3D = _skeleton.find_child("head")
	if not parent:
		parent = self
	_mesh.head_tris["Origin"] = parent.position
	
	if remove_if_present:
		for c in _hairs:
			if c.id == hair_id:
				remove_hair(hair_id)
				return
	
	var hair : VAMHair = load("res://modules/VAMActor/vam_hair.tscn").instantiate()
	hair.name = "VAMHair"
	hair._how_many = 6
	hair.force_lerp = 0.5
	
	_hairs.push_back(PersonItem.new(hair_id,hair))
	
	parent.add_child(hair)
	
	#hair.load_hair(library,hair_id,_mesh.head_tris)
	hair.load_hair_async(library,hair_id,_mesh.head_tris)
	
	hairs_list_changed.emit(self)
func remove_hair(hair_id: int):
	for i in _hairs.size():
		if _hairs[i].id == hair_id:
			var parent = _hairs[i].node.get_parent()
			if parent:
				parent.remove_child(_hairs[i].node)
			_hairs.remove_at(i)
			break
	hairs_list_changed.emit(self)


func get_clothes() -> Array:
	return _clothes
func add_cloth(library: LibraryManager,cloth_id: int,remove_if_present: bool):
	if remove_if_present:
		for c in _clothes:
			if c.id == cloth_id:
				remove_cloth(cloth_id)
				return
	
	var cloth = load("res://modules/VAMActor/vam_cloth.tscn").instantiate()
	cloth.name = "VAMCloth"
	#cloth.load_cloth(library,_look_id,cloth_id)
	cloth.load_cloth_async(library,_look_id,cloth_id)
	cloth.skeleton = _skeleton.get_path()
	
	_clothes.push_back(PersonItem.new(cloth_id,cloth))
	
	_skeleton.add_child(cloth)
	
	clothes_list_changed.emit(self)
func remove_cloth(cloth_id: int):
	for i in _clothes.size():
		if _clothes[i].id == cloth_id:
			_skeleton.remove_child(_clothes[i].node)
			_clothes.remove_at(i)
			break
	clothes_list_changed.emit(self)


func load_look(library: LibraryManager,lookID: int):
	_look_id = lookID
	
	load_look_pre()
	
	_skeleton = VAMSkeleton.new()
	_skeleton.name = "VAMSkeleton"
	_skeleton.load_skeleton(_daz_model,library,lookID)

	_mesh = VAMMesh.new()
	_mesh.name = "VAMMesh"
	
	_mesh.left_eye_bone = _skeleton.left_eye_bone_origin + Vector3(0,0,-0.005)
	_mesh.right_eye_bone = _skeleton.right_eye_bone_origin + Vector3(0,0,-0.005)
	
	_mesh.load_mesh(_daz_model,library,lookID)
	_mesh.mesh = _mesh.full_body
	_mesh.load_materials_async(library,lookID)
	
	_person_controller = load_person_controller(_skeleton,_mesh)


func load_look_async(library: LibraryManager,lookID: int):
	_mutex.lock()
	if _loading_scene or _loading_material:
		return
	_loading_scene = true
	_mutex.unlock()
	
	load_look_pre()
	
	_look_id = lookID
	
	var skeleton = VAMSkeleton.new()
	skeleton.name = "VAMSkeleton"
	skeleton.skeleton_loaded.connect(skeleton_loaded)
	skeleton.load_skelton_async(_daz_model,library,lookID)


func skeleton_loaded(skeleton: VAMSkeleton,library: LibraryManager,look_id: int):
	_skeleton = skeleton
	
	var mesh = VAMMesh.new()
	mesh.name = "VAMMesh"
	
	mesh.left_eye_bone = skeleton.left_eye_bone_origin + Vector3(0,0,-0.005)
	mesh.right_eye_bone = skeleton.right_eye_bone_origin+ Vector3(0,0,-0.005)
	
	mesh.mesh_loaded.connect(mesh_loaded)
	mesh.materials_loaded.connect(materials_loaded)
	mesh.load_mesh_async(_daz_model,library,look_id)


func mesh_loaded(mesh: VAMMesh,library: LibraryManager,looksID: int):
	_mesh = mesh
	
	_mesh.load_materials_async(library,looksID)
	
	_person_controller = load_person_controller(_skeleton,_mesh)
	
	$Movements.person_controller = _person_controller
	
	look_loaded.emit(self)


func materials_loaded(_mesh_: VAMMesh,_library_: LibraryManager,_looksID: int):
	_loading_scene = false


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


func load_person_controller(skeleton: VAMSkeleton,mesh: VAMMesh )-> PersonController:
	var person_controller = PersonController.new(_person_id,skeleton)
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
	
	if $Movements:
		$Movements.person_controller = person_controller
	
	return person_controller


class PersonItem:
	var id: int
	var node: Node3D
	var visible : bool:
		set(value):
			if node:
				node.visible = value
		get:
			if node:
				return node.visible
			return false
	
	func _init(item_id: int,item_node: Node3D) -> void:
		id = item_id
		node = item_node
