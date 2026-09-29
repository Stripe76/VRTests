@tool
class_name ValueFloat extends Node

@export var joint : Node

@export var set_begin : bool = true
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

var begin : float = 0:
	set(value):
		begin = value
		delta = target - value
	get:
		return begin
var delta := 0.0


func start():
	if set_begin:
		begin = joint.get(name)
	if name == "bend":
		print(name,": t=",target," b=",begin," d=",delta)


func update(move: float):
	if joint and curve:
		var value : float = begin + delta * curve.sample_baked(move)
		#if name == "bend":
			#print(begin,delta,value)
		
		joint.set(name,value)
