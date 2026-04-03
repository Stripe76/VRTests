@tool
class_name MoveStep
extends Node

@export var duration : float
@export var start : float
@export var end : float

@export var movement : float:
	set(value):
		movement = value
		set_movement(movement)
	get:
		return movement

@export var multiplier : float

@export var joint : Node


func set_movement(movement: float):
	if joint:
		for v : StepValue in get_children():
			joint.set(v.name,lerp(v.start*multiplier,v.end*multiplier,movement))
			#joint.set(v.name,lerp(v.start,v.end,(1 - cos(PI * movement)) / 2))
			#joint.set(v.name,cubic_interpolate(v.start*multiplier,v.end*multiplier,0.2,0.3,movement))


func set_previous_steps(steps: Array):
	if steps:
		for v : StepValue in get_children():
			if steps.size() > 0:
				for s : MoveStep in steps:
					var value : StepValue = s.find_child(v.name)
					if value:
						v.start = value.end
						break
	else:
		for c : StepValue in get_children():
			c.start = joint.get(c.name)
