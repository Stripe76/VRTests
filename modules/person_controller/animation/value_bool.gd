@tool
class_name ValueBool
extends Node

@export var end : bool:
	set(value):
		end = value
		var parent = get_parent()
		if parent:
			parent.set("movement",1)
	get:
		return end

@export_group("Debug")
@export var start : bool
