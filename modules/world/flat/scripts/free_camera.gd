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
	var move = Vector3()
	if Input.is_action_pressed("Forward"):	move.z = -move_speed.z
	elif Input.is_action_pressed("Backward"):	move.z = move_speed.z
	if Input.is_action_pressed("Up"):	move.y = -move_speed.y
	elif Input.is_action_pressed("Down"):	move.y = move_speed.y
	if Input.is_action_pressed("Left"):	move.x = -move_speed.x
	elif Input.is_action_pressed("Right"):	move.x = move_speed.x
	
	if Input.is_action_pressed("Slow"):	move *= 0.25
	
	if move.is_zero_approx() and delta_move > 0.0:
		delta_move -= delta * 2.0
		move = last_move
	else:
		if delta_move < 1.0:
			delta_move += delta
		last_move = move
	
	move = global_transform.basis * move
	position += move * delta * delta_curve.sample(delta_move)


func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.fov *= .95
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.fov *= 1.05
	
	var right_button_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	
	if right_button_pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * mouse_sensitivity)
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func set_as_active():
	camera.current = visible
	process_mode = Node.PROCESS_MODE_INHERIT if visible else Node.PROCESS_MODE_DISABLED
	
	if visible:
		get_tree().call_group("WallsVisibility","toggle_wall_visibility","All",true)
