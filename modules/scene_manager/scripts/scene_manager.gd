class_name SceneManager extends Node

signal persons_list_changed
signal current_person_changed

@export var focus_camera: NodePath:
	set(value):
		_focus_camera = value
	get:
		return _focus_camera

var current_person : VAMActor:
	get:
		return _current_person
var current_person_id : int:
	get:
		return _current_person_index

var VAM_ACTOR_SCENE : PackedScene = load("res://modules/VAMActor/vam_actor.tscn")

var _world : WorldScene
var _library : LibraryManager

var _focus_camera : NodePath

var _persons := Array()
var _current_person : VAMActor
var _current_controller : PersonController:
	get:
		if _current_person:
			return _current_person.get_person_controller()
		return null
var _current_person_index: int = -1

var _remote_transform : RemoteTransform3D

signal next_walk_step


func set_world(world: WorldScene):
	_world = world


func get_library() -> LibraryManager:
	return _library


func set_library(library: LibraryManager):
	_library = library


func select_person(id: int):
	if id >= 0 and id < _persons.size():
		_current_person_index = id
		_current_person = _persons[_current_person_index]
	else:
		_current_person_index = -1
		_current_person = null
	current_person_changed.emit(self)


func select_next_person() -> void:
	if _persons.size() == 0:
		return
	var index : int = _current_person_index + 1
	if index >= _persons.size():
		index = 0
	_current_person_index = index
	_current_person = _persons[_current_person_index]
	
	current_person_changed.emit(self)


func select_looks(id: int):
	if _current_person_index < 0:
		var person_id := _persons.size()
		
		_current_person = VAM_ACTOR_SCENE.instantiate().with(person_id)
		_current_person_index = person_id
		_current_person.name = "Person_%s" % person_id
		_current_person.process_mode = Node.PROCESS_MODE_ALWAYS
		_current_person.look_loaded.connect(look_loaded)
		
		_persons.push_back(_current_person)		
		_world.add_person(_current_person)
		
		current_person_changed.emit(self)
	
	if _library and _current_person:
		_current_person.load_look_async(_library,id)
	
	persons_list_changed.emit(self,_persons)


func look_loaded(vam_actor: VAMActor):
	set_focus_camera("hip")


func set_person_position(origin: Vector3,position: Vector3):
	if _current_person:
		_current_person.global_position = position
		origin = Vector3(origin.x,position.y,origin.z)
		_current_person.look_at(origin,Vector3.UP,true)


func set_focus_camera(bone: String):
	var vam_actor := current_person
	if _focus_camera and vam_actor:
		if not _remote_transform:
			_remote_transform = RemoteTransform3D.new()
			_remote_transform.name = "FocusCameraTransfomr"
			_remote_transform.update_position = true
			_remote_transform.update_rotation = false
			_remote_transform.remote_path = _focus_camera
		
		var camera : Node3D = get_node(_focus_camera)
		if camera:
			camera.set_fov(32 if  bone == "head" else 72)
		
		var parent_node : Node3D = vam_actor.get_focus_camera_parent(bone)
		if _remote_transform and parent_node:
			if _remote_transform.get_parent():
				_remote_transform.get_parent().remove_child(_remote_transform)
			_remote_transform.position = Vector3();
			parent_node.add_child(_remote_transform)


func add_person_hair(hair_id: int):
	if _current_person:
		_current_person.add_hair(_library,hair_id,true)


func add_person_cloth(cloth_id: int):
	if _current_person:
		_current_person.add_cloth(_library,cloth_id,true)


func walk_person_to(destination: Vector3):
	var controller := _current_controller
	if controller and _world:
		var path := _world.get_traverse_path(controller.person_position,destination)
		
		_current_person.walk_to(path,next_walk_step)


func next_walking_step():
	next_walk_step.emit()


var ragdoll := false
func toggle_ragdoll():
	if _current_person:
		_current_person.stop_walking()
		
		var controller := _current_controller
		if controller:
			ragdoll = not ragdoll
			controller.enable_ragdoll = ragdoll


func reset_person():
	var controller := _current_controller
	if controller:
		controller.reset_pose()


func toggle_animation(animation: String):
	if _current_person:
		var player : AnimationPlayer = _current_person.get_animation_player()
		if player:
			if player.is_playing():
				player.stop()
				
				_current_person.reset()
				
				player.play("RESET")
			else:
				player.play(animation,-1,0.5+randf( ))


func start_animation(animation: String):
	if _current_person:
		var player : AnimationPlayer = _current_person.get_animation_player()
		if player:
			_current_person.reset()
			
			player.play(animation,-1,0.5+randf( ))
