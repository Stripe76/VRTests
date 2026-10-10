@tool
class_name ValueBool extends Node

@export var joint : Node

@export var signal_end : bool
@export var target : bool:
	set(value):
		target = value
		if joint:
			joint.set(name,value)
	get:
		return target
@export_range(0,2) var delay : float = 0
@export_range(0,2) var duration : float = 1


var speed : float = 1


func start():
	if joint:
		var tween := create_tween()
		if delay > 0:
			tween.tween_interval(delay*speed)
		tween.tween_callback(func (): joint.set(name,target))
		if not is_zero_approx(duration):
			tween.tween_interval(duration*speed)
			tween.tween_callback(func (): joint.set(name,not target))
		if signal_end:
			tween.tween_callback(func (): get_parent().step_ended())
