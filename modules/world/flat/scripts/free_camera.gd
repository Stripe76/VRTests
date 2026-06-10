extends Node3D

@export var delta_curve := Curve.new()

@onready var camera = $Camera3D

var move_speed := Vector3(1,1,1)
var mouse_sensitivity = 0.0025

var delta_move := 0.0
var last_move := Vector3()


func _ready() -> void:
	visibility_changed.connect(set_as_active)


func _process(delta: float) -> void:
	## Position
	var move = Vector3()
	if Input.is_action_pressed("Forward"):
		move.z = -move_speed.z
	elif Input.is_action_pressed("Backward"):
		move.z = move_speed.z
	if Input.is_action_pressed("Up"):
		move.y = -move_speed.y
	elif Input.is_action_pressed("Down"):
		move.y = move_speed.y
	if Input.is_action_pressed("Left"):
		move.x = -move_speed.x
	elif Input.is_action_pressed("Right"):
		move.x = move_speed.x
	
	if Input.is_action_pressed("Slow"):
		move *= 0.25
	
	if move.is_zero_approx() and delta_move > 0.0:
		delta_move -= delta * 2.0
		move = last_move
	else:
		if delta_move < 1.0:
			delta_move += delta
		last_move = move
	
	move = global_transform.basis * move
	position += move * delta * delta_curve.sample(delta_move)


const RAY_LENGTH = 10
func _physics_process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var origin = camera.global_position
		var end = origin + camera.project_ray_normal(get_viewport().get_visible_rect().size * 0.5) * RAY_LENGTH
		var query = PhysicsRayQueryParameters3D.create(origin,end)
		var space_state = get_world_3d().direct_space_state
		var result := space_state.intersect_ray(query)
		if result:
			get_tree().call_group("Scene","set_person_position",origin,result.position)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)


func set_as_active():
	camera.current = visible
	process_mode = Node.PROCESS_MODE_INHERIT if visible else Node.PROCESS_MODE_DISABLED
	
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		get_tree().call_group("WallsVisibility","toggle_wall_visibility","All",true)
