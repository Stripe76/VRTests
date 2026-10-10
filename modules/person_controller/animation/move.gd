@tool
class_name PersonMove extends Node

@export_tool_button("Start","Forward") var start_step = start
@export var loop : bool = false

@export var joint : Node:
	set(value):
		joint = value
		init_values()
	get:
		return joint

@export_range(0,2) var speed : float = 1:
	set(value):
		speed = value
		for c in get_children():
			c.speed = speed
	get:
		return speed
@export var duration : float

signal move_ended

func _ready() -> void:
	joint = get_parent()


func init_values() -> void:
	for c in get_children():
		c.joint = joint


var last_step : Node
func start()-> void:
	var value := 0.0
	for c in get_children():
		value += c.duration
	duration = value
	
	last_step = get_children()[0]
	last_step.start()


func step_ended():
	var do_it = false if last_step != null else true
	for c in get_children():
		if do_it:
			#print("do_it")
			last_step = c
			last_step.start()
			return
		if c == last_step:
			do_it = true
	if loop:
		start()
	else:
		move_ended.emit()
