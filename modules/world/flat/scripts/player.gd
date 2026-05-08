class_name PlayerFlat
extends Node3D

@export var delta_curve := Curve.new()

@onready var camera = $Camera3D

var move_speed := Vector3(1,1,1)
var mouse_sensitivity = 0.0025


func _ready() -> void:
	generate_action_map()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


var delta_move := 0.0
var last_move := Vector3()
func _process(delta: float) -> void:
	var move = Vector3()
	if Input.is_action_pressed("Forward"):
		move.z = -move_speed.z
	elif Input.is_action_pressed("Backward"):
		move.z = move_speed.z
	elif Input.is_action_pressed("Up"):
		move.y = -move_speed.y
	elif Input.is_action_pressed("Down"):
		move.y = move_speed.y
	elif Input.is_action_pressed("Left"):
		move.x = -move_speed.x
	elif Input.is_action_pressed("Right"):
		move.x = move_speed.x
	
	if Input.is_action_pressed("Slow"):
		move *= 0.25
	
	if move.is_zero_approx() and delta_move > 0.0:
		delta_move -= delta * 1.5
		move = last_move
	else:
		if delta_move < 1.0:
			delta_move += delta
		last_move = move
	
	move = global_transform.basis * move
	position += move * delta * delta_curve.sample(delta_move)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		#rotation.z = clamp(camera.rotation.z, deg_to_rad(-90), deg_to_rad(90))


#func _unhandled_key_input(event: InputEvent) -> void:
	#if event.is_action_pressed("Up"):
		#move.y = move_speed.y
	#elif event.is_action("Down"):
		#move.y = -move_speed.y
	#elif event.is_action("Left"):
		#move.x = -move_speed.x
	#elif event.is_action("Right"):
		#move.x = move_speed.x


func generate_action_map():
	add_action( "Forward",[Key.KEY_W] )
	add_action( "Backward",[Key.KEY_S] )
	add_action( "Up",[Key.KEY_Q] )
	add_action( "Down",[Key.KEY_E] )
	add_action( "Left",[Key.KEY_A,Key.KEY_LEFT] )
	add_action( "Right",[Key.KEY_D,Key.KEY_RIGHT] )
	add_action( "Slow",[Key.KEY_SHIFT] )


func add_action(name: String,events: Array):
	InputMap.add_action(name)
	
	for e in events:
		if e is Key:
			var k := InputEventKey.new( ) 
			k.keycode = e
			InputMap.action_add_event( name,k )
