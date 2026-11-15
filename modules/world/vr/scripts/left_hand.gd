extends XRController3D

@export var player : Node3D

func _physics_process(delta: float) -> void:
	var stick = get_vector2("primary")	
	if stick.y > 0.5:
			var trans = Vector3(0,(stick.y-0.5)*delta,0)
			player.translate(trans)
	if stick.y < -0.5:
			var trans = Vector3(0,(stick.y+0.5)*delta,0)
			player.translate(trans)
				
	if stick.x > 0.2 or stick.x < -0.2:
		if stick.x > 0.2:
			stick.x -= 0.2
		elif stick.x < -0.2:
			stick.x += 0.2
		player.rotate(Vector3(0,1,0),stick.x*-delta)
