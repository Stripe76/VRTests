extends Node3D

@export var delta_curve := Curve.new()

@onready var camera : Node3D = $Camera3D

var move_speed := Vector3(1,1,1)
var mouse_sensitivity = 0.0025

var delta_move := 0.0
var last_move := Vector3()


func _ready() -> void:
	visibility_changed.connect(set_as_active)


func _process(delta: float) -> void:
	## Position
	var rotate = Vector3()
	#if Input.is_action_pressed("Forward"):
		#move.z = -move_speed.z
	#elif Input.is_action_pressed("Backward"):
		#move.z = move_speed.z
	if Input.is_action_pressed("Up"):
		rotate.x = move_speed.x
	elif Input.is_action_pressed("Down"):
		rotate.x = -move_speed.x
	if Input.is_action_pressed("Left"):
		rotate.y = -move_speed.y
	elif Input.is_action_pressed("Right"):
		rotate.y = move_speed.y
	
	if rotate.is_zero_approx() and delta_move > 0.0:
		delta_move -= delta * 2.0
		rotate = last_move
	else:
		if delta_move < 1.0:
			delta_move += delta
		last_move = rotate
	
	rotation += rotate * delta * delta_curve.sample(delta_move)
	
	check_walls_visibility()


const RAY_LENGTH = 25
func _physics_process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var space_state = get_world_3d().direct_space_state
		var mousepos = get_viewport().get_mouse_position()
		
		var origin = camera.project_ray_origin(mousepos)
		var end = origin + camera.project_ray_normal(mousepos) * RAY_LENGTH
		
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		#query.collide_with_areas = true
		
		var result = space_state.intersect_ray(query)
		if result:
			get_tree().call_group("Scene","set_person_position",origin,result.position)


var north_wall := true
var south_wall := true
var east_wall := true
var west_wall := true
var ceiling := true
func check_walls_visibility():
	var rot = wrap(rad_to_deg(rotation.y),0,360)
	#print(rot)
	
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
