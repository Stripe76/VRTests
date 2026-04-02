@tool
extends Node3D

@export var activate_physics :  bool = false:
	set(value):
		activate_physics = value
		_activate_physics(activate_physics)
	get:
		return activate_physics

var positions : Dictionary = {}

func _activate_physics( b ):
	if Engine.is_editor_hint():
		for n in self.get_parent().get_children():
			if n is RigidBody3D:
				if activate_physics:
					positions[n.name] = n.position
				elif positions.has(n.name):
					n.position = positions[n.name]
		PhysicsServer3D.set_active(activate_physics)
