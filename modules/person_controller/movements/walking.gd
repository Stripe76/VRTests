@tool
extends Node

#@export_tool_button("start") var start_walking = start

@export var controller : PersonController:
	set(value):
		set_person_controller(value)
	get:
		return _controller
@export_range(0,3) var speed := 1.0
@export var max_twist_angle: float = deg_to_rad(90.0)

@export_group("Debug")
@export var twist_line : Line3D
@export var target_line : Line3D
@export var forward_line : Line3D
@export var next_step_marker : Node3D
@export var await_signal : Signal

var _controller : PersonController

var _head : PersonHead
var _person : Person

var _hd_left : PersonMove
var _hd_right : PersonMove

var _la_back : PersonMove
var _la_front : PersonMove

var _ra_back : PersonMove
var _ra_front : PersonMove

var _ts_left : PersonMove
var _ts_right : PersonMove

var _ll_step : PersonMove
var _ll_push : PersonMove
var _ll_turn_in : PersonMove
var _ll_turn_out : PersonMove

var _rl_step : PersonMove
var _rl_push : PersonMove
var _rl_turn_in : PersonMove
var _rl_turn_out : PersonMove

var _is_walking : bool = false

var _steps : PackedVector3Array
var _current_step : int = -1
var _last_distance : float

signal _walking_ended

var c := 0
func walk_to(path: PackedVector3Array,await_signal: Signal) -> void:
	_head.pinned_on = true
	
	_steps = path
	_current_step = 0
	
	if _is_walking or _current_step >= _steps.size():
		return
	if next_step_marker and _current_step < _steps.size():
		next_step_marker.global_position = _steps[_current_step] + Vector3(0,0.05,0)
	
	_is_walking = true	
	_last_distance = 1_000_000
	
	#var spd := randf_range(1.3,2.0)
	var spd := 1.35
	
	_ll_push.speed = 1
	_rl_push.speed = 1
	_ll_push.speed = 1
	_rl_push.speed = 1
	
	_ll_step.length = spd
	_rl_step.length = spd
	
	_la_front.length = 1
	_ra_front.length = 1
	_la_back.length = 1
	_ra_back.length = 1
	
	_ll_push.length = spd
	_rl_push.length = spd
	_ll_push.height = spd
	_rl_push.height = spd
	
	var result := calculate_step_twist(_controller.person_position,_controller.person_forward,_steps[_current_step])
	var twist = result["total_twist"]
	var back_twist = result["back_twist"]
	var front_twist = result["front_twist"]
	
	if twist < 0:
		if twist < -.5:
			_ll_turn_out.width = back_twist
			_rl_turn_in.width = front_twist
			
			_ll_turn_out.start()
			_rl_turn_in.start()
			return
		
		ll_push_ended()
	else:
		if twist > .5:
			_rl_turn_out.width = back_twist
			_ll_turn_in.width = front_twist
			
			_rl_turn_out.start()
			_ll_turn_in.start()
			return
		
		rl_push_ended()


func stop_walking():
	_is_walking = false


func push_ended(this_leg_step : PersonMove,
				other_leg_push : PersonMove,
				this_arm_back : PersonMove,
				other_arm_front : PersonMove,
				this_torso : PersonMove,
				this_head : PersonMove,
				positive_twist: bool,
				await_signal) -> void:
	if _is_walking:
		if _current_step < 0 or _current_step >= _steps.size():
			return
		
		var target_position: Vector3 = _steps[_current_step]
		var is_last_step: bool = _current_step == _steps.size()-1
		var distance := (target_position - _controller.person_position).length()

		var ls := is_last_step and distance < 0.35
		var ns := not is_last_step and distance < 1
		var ld := (_last_distance < 1.0 and distance > _last_distance)
		if ls or ns or ld:
			_current_step += 1
			_last_distance = 1_000_000
			
			if next_step_marker and _current_step < _steps.size():
				next_step_marker.global_position = _steps[_current_step] + Vector3(0,0.05,0)
			#print("Walking step:",_current_step,"/",_steps.size())
			
			if is_last_step:
				other_leg_push.length = 0.1
				this_leg_step.length = 0.1
				other_arm_front.length = 0
				this_arm_back.length = 0
		elif is_last_step and distance < 1.0:
			other_leg_push.length = distance / 1.0
			this_leg_step.length = distance / 1.0
			
			_last_distance = distance
		else:
			_last_distance = distance
		
		if distance > 1:
			var look_at : Vector3 = _steps[_steps.size()-1]
			look_at += (look_at - _controller.person_position).normalized()
			look_at.y = 1.55
			create_tween().tween_property(_head.ik_target_head,"global_position",look_at,0.6).set_ease(Tween.EASE_OUT)
			
		if _current_step < _steps.size():
			var forward : Vector3
			if other_leg_push == _ll_push:
				forward = _controller.left_foot_forward
			else: 		
				forward = _controller.right_foot_forward
				
			target_position = _steps[_current_step]			
			var result := calculate_step_twist(_controller.person_position,forward,target_position)
			distance = result["distance"]
							
			if twist_line:
				var offset := Vector3(0,0.05,0) 
				var angle : float = result["angle"]
				var needed_twist : Vector3 = _controller.person_forward.rotated(Vector3.UP,-angle)
				
				twist_line.draw_path([_controller.person_position+offset,_controller.person_position+needed_twist+offset],Color.FIREBRICK)
				target_line.draw_path([_controller.person_position+offset,target_position+offset],Color.FOREST_GREEN)
				forward_line.draw_path([_controller.person_position+offset,_controller.person_position+_controller.person_forward+offset],Color.REBECCA_PURPLE)
			
			#if await_signal:
			#	await await_signal 
			
			var twist = result["total_twist"]
			var back_twist = result["back_twist"]
			var front_twist = result["front_twist"]
			
			if (positive_twist and twist > 0) or (not positive_twist and twist < 0):
				other_leg_push.width = back_twist
				this_leg_step.width = front_twist
			else:
				other_leg_push.width = -back_twist
				this_leg_step.width = -front_twist
		else:
			_is_walking = false
		
		this_leg_step.start()
		other_leg_push.start()
		
		other_arm_front.start()
		this_arm_back.start()
		
		this_torso.start()
		this_head.start()


func ll_push_ended():
	push_ended(_ll_step,_rl_push,_la_back,_ra_front,_ts_left,_hd_left,false,await_signal)


func rl_push_ended():
	push_ended(_rl_step,_ll_push,_ra_back,_la_front,_ts_right,_hd_right,true,await_signal)


func ll_turn_out_ended():
	rl_push_ended()


func rl_turn_out_ended():
	ll_push_ended()


func set_person_controller(person_controller: PersonController) -> void:
	_controller = person_controller
	
	if _controller:
		_head = _controller.find_child("Head")
		_person = _controller.find_child("Person")
		
		_hd_left = _controller.find_child("Head").find_child("WalkLeft")
		_hd_right = _controller.find_child("Head").find_child("WalkRight")
		
		_la_back = _controller.find_child("LeftArm").find_child("WalkBack")
		_la_front = _controller.find_child("LeftArm").find_child("WalkFront")
		
		_ra_back = _controller.find_child("RightArm").find_child("WalkBack")
		_ra_front = _controller.find_child("RightArm").find_child("WalkFront")
		
		_ts_left = _controller.find_child("Torso").find_child("WalkLeft")
		_ts_right = _controller.find_child("Torso").find_child("WalkRight")
		
		_ll_step = _controller.find_child("LeftLeg").find_child("StepForward")
		_ll_push = _controller.find_child("LeftLeg").find_child("PushBack")
		_ll_turn_in = _controller.find_child("LeftLeg").find_child("TurnIn")
		_ll_turn_out = _controller.find_child("LeftLeg").find_child("TurnOut")
		_ll_push.move_ended.connect(ll_push_ended)
		_ll_turn_out.move_ended.connect(ll_turn_out_ended)
		
		_rl_step = _controller.find_child("RightLeg").find_child("StepForward")
		_rl_push = _controller.find_child("RightLeg").find_child("PushBack")
		_rl_turn_in = _controller.find_child("RightLeg").find_child("TurnIn")
		_rl_turn_out = _controller.find_child("RightLeg").find_child("TurnOut")
		_rl_push.move_ended.connect(rl_push_ended)
		_rl_turn_out.move_ended.connect(rl_turn_out_ended)


func calculate_step_twist(skeleton_pos: Vector3, skeleton_forward: Vector3, target_pos: Vector3) -> Dictionary:
	# 1. Flatten vectors to the XZ plane (ignore Y)
	var skel_pos_2d := Vector2(skeleton_pos.x,skeleton_pos.z)
	var target_pos_2d := Vector2(target_pos.x,target_pos.z)
	var forward_2d := Vector2(skeleton_forward.x,skeleton_forward.z).normalized()
	var distance := (target_pos_2d - skel_pos_2d).length()
	
	# 2. Calculate the direction vector from skeleton to target
	var to_target_2d := (target_pos_2d - skel_pos_2d).normalized()
	
	# 3. Get the signed angle between the current forward direction and the target
	# Returns a value between -PI and +PI (Negative = Left, Positive = Right)
	var total_needed_angle := forward_2d.angle_to(to_target_2d)
	
	# 4. Clamp the angle to the maximum twist budget
	var clamped_angle = clamp(total_needed_angle,-max_twist_angle,max_twist_angle)
	
	# 5. Split the twist between the legs 
	# Note: Depending on how your rig is built, the back leg might need to twist 
	# in the opposite direction (-clamped_angle / 2.0) to assist the turn.
	var front_leg_twist = clamped_angle / 2.0
	var back_leg_twist = clamped_angle / 2.0 
	
	return {
		"angle": clamped_angle, 
		"distance": distance,
		"total_twist": total_needed_angle / max_twist_angle,
		"front_twist": abs(front_leg_twist / (max_twist_angle/2.0)),
		"back_twist": abs(back_leg_twist / (max_twist_angle/2.0)),
	}
