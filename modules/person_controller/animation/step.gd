@tool
class_name MoveStep extends Node

@export_tool_button("Reset","Reload") var reset_button = reset

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
			c.multiplier = speed
	get:
		return speed
@export_range(0,2) var duration : float = 1

@export var begin : float
@export var end : float

@export_range(0,1) var movement : float:
	set(value):
		movement = value
		update(movement)
	get:
		return movement
@export var multiplier : float = 1.0


func init_values() -> void:
	for c in get_children():
		c.joint = joint


func reset():
	if joint:
		for c in get_children():
			joint.set(c.name,c.target)


func start():
	for c in get_children():
		c.start()


func update(move: float):
	for c in get_children():
		c.update(move)
