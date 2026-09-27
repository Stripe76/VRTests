@tool
class_name ValueFloat extends Node

@export var joint : Node

@export_range(-1,1) var target : float:
	set(value):
		target = value
		if joint:
			joint.set(name,value)
	get:
		return target
@export_range(-20,20) var speed : float = 1:
	set(value):
		speed = value
	get:
		return speed
@export_range(-20,20) var multiplier : float = 1:
	set(value):
		multiplier = value
	get:
		return multiplier
@export var curve : Curve

var begin := 0.0
var delta := .2


func start():
	#print(name,": start")
	begin = joint.get(name)
	delta = target - begin


func update(move: float):
	if joint and curve:
		var value : float = begin + delta * curve.sample_baked(move)
		
		joint.set(name,value)
