@tool
class_name ValueBool
extends Node

@export var joint : Node

@export var target : bool:
	set(value):
		target = value
	get:
		return target


func start():
	if joint:
		joint.set(name,target)


func update(_move: float):
	pass
