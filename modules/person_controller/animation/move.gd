@tool
class_name PersonMove extends Node

@export var joint : Node:
	set(value):
		joint = value
		init_values()
	get:
		return joint
@export_range(-20,20) var speed : float = 1:
	set(value):
		speed = value
		for c in get_children():
			c.speed = speed
	get:
		return speed
@export_range(0,2) var duration : float:
	set(value):
		duration = value
		for c in get_children():
			c.duration = duration
	get:
		return duration
@export_range(0,1) var movement : float:
	set(value):
		movement = value
		if is_zero_approx(movement):
			last_step = null
		update(movement)
	get:
		return movement

var total_steps : int
var total_duration : float

func _ready() -> void:
	joint = get_parent()


func init_values() -> void:
	total_steps = 0
	total_duration = 0
	for c : MoveStep in get_children():
		total_steps += 1
		total_duration += c.duration
		c.joint = joint
		
	#var previous_steps := []
	var begin : float = 0
	for s : MoveStep in get_children():
		s.begin = begin
		begin += s.duration / total_duration
		s.end = begin
		#s.set_previous_steps(previous_steps)
		#previous_steps.insert(0,s)


var last_step
func update(value: float)-> void:
	for s : MoveStep in get_children():
		if s.begin < value and s.end > value:
			if last_step != s:
				s.start()
			#s.multiplier = multiplier
			s.movement = ((value - s.begin) / (s.end-s.begin))
			last_step = s
