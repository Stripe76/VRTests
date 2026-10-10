@tool
class_name TweenFloat extends Node

@export var joint : Node

@export var signal_end : bool
@export_range(-1,1) var target : float:
	set(value):
		target = value
		if joint:
			joint.set(name,target)
	get:
		return target
@export var curve : Curve
@export_range(0,2) var delay : float = 0
@export_range(0,2) var duration : float = 1

var speed : float = 1
var begin : float
var value : float:
	set(value):
		if joint:
			joint.set(name,begin + curve.sample_baked(value) * (target-begin))
			#joint.set(name,begin + value * (target-begin))
	get:
		return 0


func _enter_tree() -> void:
	if not curve:
		curve = Curve.new()
		curve.add_point(Vector2(0,0),1,0,Curve.TANGENT_FREE,Curve.TANGENT_FREE)
		curve.add_point(Vector2(1,1),0,1,Curve.TANGENT_FREE,Curve.TANGENT_FREE)


func start():
	if joint:
		var tween := create_tween()
		if delay > 0:
			tween.tween_interval(delay*speed)
		tween.tween_callback(func(): begin = joint.get(name))
		#prints(name,begin,target)
		tween.tween_property(self,"value",1,duration*speed).set_trans(Tween.TRANS_LINEAR)
		if signal_end:
			tween.tween_callback(func (): get_parent().step_ended())
