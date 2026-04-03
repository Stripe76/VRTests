@tool
class_name StepValue
extends Node

@export_range(0,1) var end : float:
	set(value):
		end = value
		var parent = get_parent()
		if parent:
			parent.set("movement",1)
	get:
		return end

@export_group("Debug")
@export_range(0,1) var start : float
