class_name WallsHide extends Node3D

@export var wall_normal: Vector3 = Vector3.BACK 

static var is_hiding_enabled: bool = false

func _process(_delta: float) -> void:
	#if not is_hiding_enabled:
		#if not visible:
			#visible = true
		#return
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	var camera_forward: Vector3 = -camera.global_transform.basis.z.normalized()
	var global_wall_normal: Vector3 = global_transform.basis * wall_normal.normalized()

	var dot_limit = 0.24
	if wall_normal.y > 0 or wall_normal.y < 0:
		dot_limit = 0.1
	if camera_forward.dot(global_wall_normal) > dot_limit: 
		visible = false
	else:
		visible = true
