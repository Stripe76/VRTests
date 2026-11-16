class_name WallsHide extends Node3D

@export var wall_normal: Vector3 = Vector3.BACK 

static var is_hiding_enabled: bool = false

var wall_origin : Vector3

func _ready() -> void:
	var origin : Marker3D = find_child("WallOrigin")
	if origin:
		wall_origin = origin.global_position


func _process(_delta: float) -> void:
	#if not is_hiding_enabled:
		#if not visible:
			#visible = true
		#return
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	var camera_forward: Vector3 = (wall_origin - camera.global_transform.origin).normalized()
	var global_wall_normal: Vector3 = wall_normal
	
	if camera_forward.dot(global_wall_normal) < 0: 
		visible = false
	else:
		visible = true
