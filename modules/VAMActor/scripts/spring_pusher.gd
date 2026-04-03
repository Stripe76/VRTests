@tool
class_name SpringPusher
extends Node

@export var force : Vector3:
	set(value):
		force = value
		counter = 50
@export var shape : CollisionShape3D
@export var spring_bone : SpringBoneSimulator3D

var counter : int = 0

func _init(spring: SpringBoneSimulator3D,collision_shape : CollisionShape3D) -> void:
	spring_bone = spring
	shape = collision_shape


func _physics_process(delta: float) -> void:
	#print(spring_bone)
	#print(force)
	
	spring_bone.external_force = force * delta * 600
	if counter == 0:
		force = Vector3(0,0,0)
	else:
		counter -= 1
