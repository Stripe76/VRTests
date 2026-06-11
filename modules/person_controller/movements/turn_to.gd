@tool
extends Node

@export_tool_button("start/stop") var start = start_stop

@export var controller : PersonController:
	set(value):
		set_person_controller(value)
	get:
		return _person_controller
@export_range(0,1) var movement : float:
	set(value):
		movement = value
		update_position( movement )
	get:
		return movement
@export_range(-4,4) var speed : float = 1.0:
	set(value):
		_speed = value
	get:
		return _speed

var _person_controller : PersonController
var _left_leg : PersonMove
var _right_leg : PersonMove

var _go := false
var _is_stopping := false

var _move : float = 0.0
var _speed : float = 0.0

func start_stop():
	if _go:
		_is_stopping = true
	else:
		_go = true
		_is_stopping = false


func _process(delta: float) -> void:
	if _go:
		_move += delta * _speed
		
		if _is_stopping:
			var wrapped_move = wrap(_move,0,1)
			
			if wrapped_move < 0.05 or wrapped_move > 0.95:
				_go = false
				_is_stopping = false
				_move = 0.0
				update_position(_move)
				return
		
		update_position(wrap(_move,0,1))


func set_person_controller(person_controller: PersonController) -> void:
	_person_controller = person_controller
	_left_leg = null
	_right_leg = null
	
	if _person_controller:
		_left_leg = _person_controller.find_child("LeftLeg").find_child("TurnToIn")
		_right_leg = _person_controller.find_child("RightLeg").find_child("TurnToOut")


func update_position(move: float)-> void:
	if _left_leg:
		_left_leg.movement = wrap(move,0,1)
	if _right_leg:
		_right_leg.movement = wrap(move,0,1)
