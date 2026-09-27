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
@export_range(0,2) var duration : float:
	set(value):
		duration = value
	get:
		return duration
@export var curve : Curve

var time := 0.0
var begin := 0.0
var delta := 10.0


func start():
	time = 0.0
	begin = joint.get(name)
	delta = target - begin
	#print("begin: ",begin," delta: ",delta)


func update(elapsed: float):
	time += elapsed
	
	if time > duration:
		return true
	if joint and curve:
		var value : float = clamp(begin + (speed/100.0) * multiplier * curve.sample_baked(time/duration),-1,1)
		begin = value
		joint.set(name,value)
	return false
