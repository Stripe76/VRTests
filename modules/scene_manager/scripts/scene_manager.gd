class_name SceneManager
extends Node

signal persons_list_changed
signal current_person_changed

var current_person : int:
	get:
		return _current_person_index

var VAM_ACTOR_SCENE : PackedScene = load("res://modules/VAMActor/vam_actor.tscn")

var _world : WorldScene
var _library : LibraryManager

var _persons := Array()
var _current_person : VAMActor
var _current_person_index = -1


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


func select_looks(id: int):
	if _current_person_index < 0:
		_current_person = VAM_ACTOR_SCENE.instantiate()
		_current_person_index = _persons.size()
		_current_person.name = "Person_%s" % _current_person_index
		
		_persons.push_back(_current_person)
		
		_world.add_person(_current_person)
	
	if _library and _current_person:
		#animation_was_playing = $AnimationPlayer.is_playing()
		#$AnimationPlayer.pause()
		_current_person.load_looks_async(_library,id,Vector3(_current_person_index * .50,0,_current_person_index * .50),looks_loaded)
	
	persons_list_changed.emit(self,_persons)


func looks_loaded():
	start_animation("RESET")


func toggle_animation(animation: String):
	if _current_person:
		var player : AnimationPlayer = _current_person.get_node("Actor")
		if player:
			if player.is_playing():
				player.pause()
			else:
				player.speed_scale = 1.0 + randf( )
				player.play(animation)


func start_animation(animation: String):
	if _current_person:
		var player : AnimationPlayer = _current_person.get_node("Actor")
		if player:
			_current_person.reset()
			
			player.speed_scale = 1.0 + randf( )
			player.play(animation)
