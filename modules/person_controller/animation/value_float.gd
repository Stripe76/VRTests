@tool
class_name ValueFloat extends Node

@export_range(-1,1) var start : float:
	set(value):
		start = value
		var parent = get_parent()
		if parent:
			parent.set("movement",1)
	get:
		return start
@export_range(-1,1) var end : float:
	set(value):
		end = value
		var parent = get_parent()
		if parent:
			parent.set("movement",1)
	get:
		return end
