@tool
class_name PersonMove
extends Node

@export_tool_button("Reset","Reload") var reset_action = init_values

@export_range(0,1) var movement : float:
	set(value):
		movement = value
		update_position( movement )
	get:
		return movement
@export_range(0,1) var multiplier : float = 1:
	set(value):
		multiplier = value
		update_position(movement)
	get:
		return multiplier

@export var joint : Node:
	set(value):
		joint = value
		init_values()
	get:
		return joint

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
	
	var previous_steps := []
	var start : float = 0
	for s : MoveStep in get_children():
		s.start = start
		start += s.duration / total_duration
		s.end = start
		s.set_previous_steps(previous_steps)
		previous_steps.insert(0,s)

func update_position( value: float )-> void:
	for s : MoveStep in get_children():
		if s.start < value and s.end > value:
			s.multiplier = multiplier
			s.movement = ((value - s.start) / (s.end-s.start))
			break
