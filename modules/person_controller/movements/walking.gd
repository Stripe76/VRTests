@tool
extends Node

@export_tool_button("start") var start_walking = start

@export var target : Node3D
@export var controller : PersonController:
	set(value):
		set_person_controller(value)
	get:
		return _controller
@export_range(0,3) var speed := 1.0

var _controller : PersonController

var _head : PersonHead
var _person : Person

var hd_left : PersonMove
var hd_right : PersonMove

var la_back : PersonMove
var la_front : PersonMove

var ra_back : PersonMove
var ra_front : PersonMove

var ts_left : PersonMove
var ts_right : PersonMove

var ll_step : PersonMove
var ll_push : PersonMove
var ll_turn_in : PersonMove
var ll_turn_out : PersonMove

var rl_step : PersonMove
var rl_push : PersonMove
var rl_turn_in : PersonMove
var rl_turn_out : PersonMove

var go := false
var auto_stopped := false

var debug_random_walk := true
var debug_fainting_count := 0

var c := 0
func start():
	_head.pinned_on = true
	
	if debug_fainting_count > 0:
		c += 1
	if c > debug_fainting_count:
		c = 0
		_controller.enable_ragdoll = true
		return
		
	if go:
		return
	go = true
	last_distance = 1_000_000
	
	#var spd := randf_range(1.3,2.0)
	var spd := 1.35
	
	ll_push.speed = 1
	rl_push.speed = 1
	ll_push.speed = 1
	rl_push.speed = 1
	
	ll_step.length = spd
	rl_step.length = spd
	
	la_front.length = 1
	ra_front.length = 1
	la_back.length = 1
	ra_back.length = 1
	
	ll_push.length = spd
	rl_push.length = spd
	ll_push.height = spd
	rl_push.height = spd
	
	var result := calculate_step_twist(_controller.person_position,_controller.person_forward,target.global_position)
	var twist = result["total_twist"]
	var back_twist = result["back_twist"]
	var front_twist = result["front_twist"]
	
	if twist < 0:
		if twist < -.5:
			#prints("s<0",front_twist,back_twist)
			ll_turn_out.width = back_twist
			rl_turn_in.width = front_twist
			
			ll_turn_out.start()
			rl_turn_in.start()
			return
		
		ll_push_ended()
	else:
		if twist > .5:
			#prints("s>0",front_twist,back_twist)
			rl_turn_out.width = back_twist
			ll_turn_in.width = front_twist
			
			rl_turn_out.start()
			ll_turn_in.start()
			return
		
		rl_push_ended()


func stop():
	go = false
	auto_stopped = false


var last_distance : float
func ll_push_ended():
	if go:
		if target:
			var result := calculate_step_twist(_controller.person_position,_controller.person_forward,target.global_position)
			var distance : float = result["distance"]
			if distance < 0.35 or (last_distance < 1.0 and distance > last_distance):
				ll_step.length = 0.1
				rl_push.length = 0.1
				la_back.length = 0
				ra_front.length = 0
				go = false
				auto_stopped = true
			if go and distance < 1.0:
				ll_step.length = distance / 1.0
				rl_push.length = distance / 1.0
				
			last_distance = distance
			
			if distance > 1.0:
				var look_at : Vector3 = target.global_position
				look_at += (look_at - _controller.person_position).normalized()
				look_at.y = 1.55
				create_tween().tween_property(_head.ik_target_head,"global_position",look_at,0.6).set_ease(Tween.EASE_OUT)
				#_head.ik_target_head.global_position = look_at
			
			if go:
				var twist = result["total_twist"]
				var back_twist = result["back_twist"]
				var front_twist = result["front_twist"]
				if twist < 0:
					#prints("l<0",front_twist,back_twist)
					ll_step.width = front_twist
					rl_push.width = back_twist
				else:
					#prints("l>0",front_twist,back_twist)
					ll_step.width = -front_twist
					rl_push.width = -back_twist
		
		ll_step.start()
		rl_push.start()
		
		ra_front.start()
		la_back.start()
		
		ts_left.start()
		hd_left.start()
	elif debug_random_walk and auto_stopped:
		target.global_position = Vector3(randf_range(-2.5,2.5),0,randf_range(-2.5,2.5))
		
		var t := create_tween()
		t.tween_interval(.5)
		t.tween_callback(start)


func rl_push_ended():
	if go:
		if target:
			var result := calculate_step_twist(_controller.person_position,_controller.person_forward,target.global_position)
			var distance : float = result["distance"]
			if distance < 0.35 or (last_distance < 1.0 and distance > last_distance):
				ll_push.length = 0.1
				rl_step.length = 0.1
				la_front.length = 0
				ra_back.length = 0
				go = false
				auto_stopped = true
			if go and distance < 1.0:
				ll_push.length = distance / 1.0
				rl_step.length = distance / 1.0
			last_distance = distance
			
			if distance > 1:
				var look_at : Vector3 = target.global_position
				look_at += (look_at - _controller.person_position).normalized()
				look_at.y = 1.55
				create_tween().tween_property(_head.ik_target_head,"global_position",look_at,0.6).set_ease(Tween.EASE_OUT)
				
			if go:
				var twist = result["total_twist"]
				var back_twist = result["back_twist"]
				var front_twist = result["front_twist"]
					
				if twist > 0:
					#prints("r>0",front_twist,back_twist)
					ll_push.width = back_twist
					rl_step.width = front_twist
				else:
					#prints("r<0",front_twist,back_twist)
					ll_push.width = -back_twist
					rl_step.width = -front_twist
		
		rl_step.start()
		ll_push.start()
		
		la_front.start()
		ra_back.start()
		
		ts_right.start()
		hd_right.start()
	elif debug_random_walk and auto_stopped:
		target.global_position = Vector3(randf_range(-2.5,2.5),0,randf_range(-2.5,2.5))
		
		var t := create_tween()
		t.tween_interval(.5)
		t.tween_callback(start)


func ll_turn_out_ended():
	rl_push_ended()


func rl_turn_out_ended():
	ll_push_ended()


func set_person_controller(person_controller: PersonController) -> void:
	_controller = person_controller
	
	if _controller:
		_head = _controller.find_child("Head")
		_person = _controller.find_child("Person")
		
		hd_left = _controller.find_child("Head").find_child("WalkLeft")
		hd_right = _controller.find_child("Head").find_child("WalkRight")
		
		la_back = _controller.find_child("LeftArm").find_child("WalkBack")
		la_front = _controller.find_child("LeftArm").find_child("WalkFront")
		
		ra_back = _controller.find_child("RightArm").find_child("WalkBack")
		ra_front = _controller.find_child("RightArm").find_child("WalkFront")
		
		ts_left = _controller.find_child("Torso").find_child("WalkLeft")
		ts_right = _controller.find_child("Torso").find_child("WalkRight")
		
		ll_step = _controller.find_child("LeftLeg").find_child("StepForward")
		ll_push = _controller.find_child("LeftLeg").find_child("PushBack")
		ll_turn_in = _controller.find_child("LeftLeg").find_child("TurnIn")
		ll_turn_out = _controller.find_child("LeftLeg").find_child("TurnOut")
		ll_push.move_ended.connect(ll_push_ended)
		ll_turn_out.move_ended.connect(ll_turn_out_ended)
		
		rl_step = _controller.find_child("RightLeg").find_child("StepForward")
		rl_push = _controller.find_child("RightLeg").find_child("PushBack")
		rl_turn_in = _controller.find_child("RightLeg").find_child("TurnIn")
		rl_turn_out = _controller.find_child("RightLeg").find_child("TurnOut")
		rl_push.move_ended.connect(rl_push_ended)
		rl_turn_out.move_ended.connect(rl_turn_out_ended)


@export var max_twist_angle: float = deg_to_rad(90.0) # Maximum steering twist per step

func calculate_step_twist(skeleton_pos: Vector3, skeleton_forward: Vector3, target_pos: Vector3) -> Dictionary:
	# 1. Flatten vectors to the XZ plane (ignore Y)
	var skel_pos_2d = Vector2(skeleton_pos.x,skeleton_pos.z)
	var target_pos_2d = Vector2(target_pos.x,target_pos.z)
	var forward_2d = Vector2(skeleton_forward.x,skeleton_forward.z).normalized()
	var distance := (target_pos_2d - skel_pos_2d).length()
	
	# 2. Calculate the direction vector from skeleton to target
	var to_target_2d = (target_pos_2d - skel_pos_2d).normalized()
	
	# 3. Get the signed angle between the current forward direction and the target
	# Returns a value between -PI and +PI (Negative = Left, Positive = Right)
	var total_needed_angle = forward_2d.angle_to(to_target_2d)
	
	# 4. Clamp the angle to the maximum twist budget
	var clamped_angle = clamp(total_needed_angle,-max_twist_angle,max_twist_angle)
	
	# 5. Split the twist between the legs 
	# Note: Depending on how your rig is built, the back leg might need to twist 
	# in the opposite direction (-clamped_angle / 2.0) to assist the turn.
	var front_leg_twist = clamped_angle / 2.0
	var back_leg_twist = clamped_angle / 2.0 
	
	return {
		"total_twist": total_needed_angle / max_twist_angle,
		"front_twist": abs(front_leg_twist / (max_twist_angle/2.0)),
		"back_twist": abs(back_leg_twist / (max_twist_angle/2.0)),
		"distance": distance
	}
