@tool
extends CharacterBody3D

func _physics_process(delta: float) -> void:
	var collision = move_and_collide(Vector3(0,0,0),true)
	#print("Yep!")
	
	if collision and collision.get_collision_count() > 0:
		var bone = collision.get_collider()
		
		if bone is PersonHandle:
			#print("Yep!")
			var spring = bone.spring_pusher
			
			if spring is SpringPusher:
				#print("Yep!")
				#var v = collision.get_normal()
				var v = (collision.get_position() - spring.shape.global_position).normalized()
				#print(v)
				spring.force = v *  collision.get_travel().length_squared()*100 * collision.get_depth() * -50
				#print(collision.get_travel().length_squared())
				#print(spring.force)
