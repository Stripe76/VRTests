@tool
extends Node

@export_tool_button("start/stop") var start = start_stop

@export var controller : PersonController:
	set(value):
		set_person_controller(value)
	get:
		return _person_controller
@export_range(0,3) var speed := .75

var _person_controller : PersonController

var _left_arm : PersonMove
var _right_arm : PersonMove
var _torso : PersonMove
var _left_leg : PersonMove
var _right_leg : PersonMove

var go = false
func start_stop():
	go = not go

var move := 0.0
func _process(delta: float) -> void:
	if go:
		move += delta * speed
		
		if _left_arm:
			_left_arm.movement = wrap(move,0,1)
		if _right_arm:
			_right_arm.movement = wrap(move+0.5,0,1)
		if _torso:
			_torso.movement = wrap(move,0,1)
		if _left_leg:
			_left_leg.movement = wrap(move,0,1)
		if _right_leg:
			_right_leg.movement = wrap(move+0.5,0,1)


func set_person_controller(person_controller: PersonController) -> void:
	_person_controller = person_controller
	
	if _person_controller:
		_left_arm = _person_controller.find_child("LeftArm").find_child("Walking")
		_right_arm = _person_controller.find_child("RightArm").find_child("Walking")
		
		_torso = _person_controller.find_child("Torso").find_child("Walking")
		
		_left_leg = _person_controller.find_child("LeftLeg").find_child("Walking")
		_right_leg = _person_controller.find_child("RightLeg").find_child("Walking")
		
		print(_left_leg)
		print(_right_leg)
