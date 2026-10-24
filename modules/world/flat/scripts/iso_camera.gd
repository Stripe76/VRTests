extends Node3D

@export var delta_curve := Curve.new()

@onready var camera : Node3D = $Camera3D

var move_speed := Vector3(1,1,1)
var mouse_sensitivity = 0.0025

var delta_move := 0.0
var last_move := Vector3()

var right_button_pressed := false


func _ready() -> void:
	visibility_changed.connect(set_as_active)


func _process(delta: float) -> void:
	var value = Vector3()
	if Input.is_action_pressed("Backward"):	value.x = move_speed.x
	elif Input.is_action_pressed("Forward"):	value.x = -move_speed.x
	if Input.is_action_pressed("Left"):	value.y = -move_speed.y
	elif Input.is_action_pressed("Right"):	value.y = move_speed.y
	
	if value.is_zero_approx() and delta_move > 0.0:
		delta_move -= delta * 2.0
		value = last_move
	else:
		if delta_move < 1.0:
			delta_move += delta
		last_move = value
	
	rotation += value * delta * delta_curve.sample(delta_move)
	
	check_walls_visibility()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.fov *= .95
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.fov *= 1.05
		
	right_button_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	
	if right_button_pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		if  event is InputEventMouseMotion:
			var value = Vector3(-event.relative.y,-event.relative.x,0)
			
			rotation += value * mouse_sensitivity
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


var north_wall := true
var south_wall := true
var east_wall := true
var west_wall := true
var ceiling := true
func check_walls_visibility():
	var rot = wrap(rad_to_deg(rotation.y),0,360)
	
	north_wall = check_wall("North",rot,125,235,north_wall)
	south_wall = check_wall("South",rot,305,55,south_wall)
	east_wall = check_wall("East",rot,35,145,east_wall)
	west_wall = check_wall("West",rot,215,325,west_wall)
	
	var ceiling_visible = camera.global_position.y < 2.5
	if ceiling_visible != ceiling:
		get_tree().call_group("WallsVisibility","toggle_wall_visibility","Ceiling",ceiling_visible)
		
		ceiling = ceiling_visible


func check_wall(wall_name: String,rot: float,start: float,end: float,current:bool) -> bool:
	var is_visibile : bool
	if start < end:
		is_visibile = not (rot > start and rot < end)
	else:
		is_visibile = not (rot > start or rot < end)
	if is_visibile != current:
		get_tree().call_group("WallsVisibility","toggle_wall_visibility",wall_name,is_visibile)
	return is_visibile


func set_as_active():
	camera.current = visible
	process_mode = Node.PROCESS_MODE_INHERIT if visible else Node.PROCESS_MODE_DISABLED
	
	north_wall = true
	south_wall = true
	east_wall = true
	west_wall = true
	ceiling = true
	
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
