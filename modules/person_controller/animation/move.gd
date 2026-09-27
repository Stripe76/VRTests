@tool
class_name PersonMove extends Node

@export_tool_button("start/stop") var start = start_stop

@export var joint : Node:
	set(value):
		joint = value
		init_values()
	get:
		return joint
@export_range(-20,20) var speed : float = 1:
	set(value):
		speed = value
		for c in get_children():
			c.speed = speed
	get:
		return speed
@export_range(0,2) var duration : float:
	set(value):
		duration = value
		for c in get_children():
			c.duration = duration
	get:
		return duration


var go = false
func start_stop():
	go = not go
	step = -1


var step := -1

func _ready() -> void:
	joint = get_parent()


func _process(delta: float) -> void:
	if go:
		var current := 0
		for c in get_children():
			if current > step:
				c.start()
				step += 1
			if not c.update(delta):
				return
			current += 1
		step = -1


func init_values() -> void:
	for c : MoveStep in get_children():
		c.joint = joint
