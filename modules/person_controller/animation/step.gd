@tool
class_name MoveStep extends Node

@export var duration : float
@export var start : float
@export var end : float

@export var movement : float:
	set(value):
		movement = value
		set_movement(movement)
	get:
		return movement

@export var multiplier : float = 1.0

@export var joint : Node


func set_movement(move: float):
	if joint:
		for v in get_children():
			if v is ValueFloat:
				#var value = lerp(v.start*multiplier,v.end*multiplier,move)
				var value = cubic_interpolate(v.start*multiplier,v.end*multiplier,.3,.3,movement)
				joint.set(v.name,value)
				#print(v.name," ",value," (",v.start,";",v.end,";",move,")")
				#joint.set(v.name,lerp(v.start,v.end,(1 - cos(PI * movement)) / 2))
				#joint.set(v.name,cubic_interpolate(v.start*multiplier,v.end*multiplier,0.2,0.3,movement))
			elif v is ValueBool:
				#prints("v.name",v.end)
				joint.set(v.name,v.end)


func set_previous_steps(steps: Array):
	if steps:
		for v in get_children():
			if steps.size() > 0:
				for s : MoveStep in steps:
					var value = s.find_child(v.name)
					if value:
						#v.start = value.end
						v.start = 0
						break
	elif joint:
		for v in get_children():
			var value = joint.get(v.name)
			if value:
				v.start = value
