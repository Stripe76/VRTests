@tool
class_name ValueFloat extends Node

@export var joint : Node

@export var signal_end : bool
@export_range(-1,1) var target : float:
	set(value):
		target = value
		if joint:
			joint.set(name,value)
	get:
		return target
@export_range(0,2) var speed : float = 1


func start():
	if joint:
		joint.set(name,target)
