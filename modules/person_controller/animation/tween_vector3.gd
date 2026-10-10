@tool
class_name TweenVector3 extends Node

@export var joint : Node

@export var signal_end : bool
@export var target : Vector3:
	set(value):
		target = value
		if joint:
			joint.set(name,value)
	get:
		return target
@export_range(0,2) var speed : float = 1
@export_range(0,1) var duration : float = 1


func start():
	if joint:
		print("Start ",name)
		var tween := create_tween()
		tween.tween_property(joint,name as String,target,duration*speed).set_trans(Tween.TRANS_CUBIC)
		if signal_end:
			tween.tween_callback(func (): get_parent().step_ended())
