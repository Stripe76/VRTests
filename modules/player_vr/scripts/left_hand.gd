extends XRController3D

@export var player : Node3D

func _physics_process(delta: float) -> void:
	var stick = get_vector2("primary")	
	if stick.y > 0.2:
		stick.y -= 0.2
	elif stick.y < -0.2:
		stick.y += 0.2
	if stick.x > 0.2:
		stick.x -= 0.2
	elif stick.x < -0.2:
		stick.x += 0.2
	
	var trans = basis * Vector3.FORWARD * (stick.y*delta)
	trans.y = 0
	player.translate(trans)

	trans = basis * Vector3.RIGHT * (stick.x*delta)
	trans.y = 0
	player.translate(trans)
