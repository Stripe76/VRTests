@tool
class_name MoveStep extends Node

@export_tool_button("Reset","Reload") var reset_values = reset

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
@export var duration : float:
	get:
		var value := 0.0
		if Engine.is_editor_hint():
			for c in get_children():
				if c.signal_end:
					value += c.delay + c.duration
		return value


func _get_configuration_warning():
	var count := 0
	for c in get_children():
		if c.signal_end:
			count += 1
			if count > 1:
				return ["Too many signal_end set"]
	return []


func init_values() -> void:
	for c in get_children():
		c.joint = joint
	if Engine.is_editor_hint():
		update_configuration_warnings()


func reset():
	if joint:
		joint.ik_on = false
		joint.root_on = false
		
	for c in get_children():
		c.target = c.target


func start():
	var signal_end = true
	for c in get_children():
		if (c is TweenFloat or c is TweenVector3 or c is ValueBool) and c.signal_end:
			signal_end = false
		c.start()
	if signal_end:
		step_ended()


func step_ended():
	get_parent().step_ended()
