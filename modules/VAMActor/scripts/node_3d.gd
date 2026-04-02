extends RigidBody3D


func _ready() -> void:
	self.apply_impulse(Vector3(10,0,10))
