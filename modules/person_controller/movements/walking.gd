@tool
extends Node

@export_tool_button("start/stop") var start = start_stop

@export var controller : PersonController:
	set(value):
		set_person_controller(value)
	get:
		return _person_controller
@export_range(0,3) var speed := 1.0

var _person_controller : PersonController

var _person : Person

var _left_arm : PersonMove
var _right_arm : PersonMove
var _torso : PersonMove

var _left_leg_step : PersonMove
var _right_leg_step : PersonMove
var _left_leg_push : PersonMove
var _right_leg_push : PersonMove


var go = false
func start_stop():
	go = not go
	
	if go:
		_left_leg_push.speed = speed
		_right_leg_push.speed = speed
		
		_right_leg_push.start()
		_left_leg_step.start()


func left_leg_step_ended():
	if go:
		_left_leg_push.start()
		_right_leg_step.start()
		#_torso.start()
func left_leg_push_ended():
	if go:
		_left_leg_step.start()
		_right_leg_push.start()

func right_leg_step_ended():
	if go:
		#_right_leg_push.start()
		#_torso.start()
		pass
func right_leg_push_ended():
	if go:
		#_right_leg_step.start()
		pass


func set_person_controller(person_controller: PersonController) -> void:
	_person_controller = person_controller
	
	if _person_controller:
		_person = _person_controller.find_child("Person")
		
		_left_arm = _person_controller.find_child("LeftArm").find_child("Walking")
		_right_arm = _person_controller.find_child("RightArm").find_child("Walking")
		
		_torso = _person_controller.find_child("Torso").find_child("Walking")
		
		_left_leg_step = _person_controller.find_child("LeftLeg").find_child("StepForward")
		_left_leg_step.move_ended.connect(left_leg_step_ended)
		_right_leg_step = _person_controller.find_child("RightLeg").find_child("StepForward")
		_right_leg_step.move_ended.connect(right_leg_step_ended)
		
		_left_leg_push = _person_controller.find_child("LeftLeg").find_child("PushBack")
		_left_leg_push.move_ended.connect(left_leg_push_ended)
		_right_leg_push = _person_controller.find_child("RightLeg").find_child("PushBack")
		_right_leg_push.move_ended.connect(right_leg_push_ended)
		
		#print(_left_leg_step)
		#print(_right_leg_step)
