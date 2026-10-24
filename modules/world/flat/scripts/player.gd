class_name PlayerFlat extends Node3D

@onready var free_camera := $FreeCamera
@onready var pivot_camera := $PivotCamera

var current_camera := 0 

func _ready() -> void:
	generate_action_map()
	
	free_camera.set_as_active()
	pivot_camera.set_as_active()
	
	cycle_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("CycleCamera"):
		cycle_camera()


func cycle_camera():
		current_camera += 1
		
		if current_camera % 2 == 0:
			pivot_camera.visible = true
			free_camera.visible = false
		else:
			free_camera.visible = true
			pivot_camera.visible = false


func generate_action_map():
	add_action( "CycleCamera",[Key.KEY_F1] )
	
	add_action( "Up",[Key.KEY_Q] )
	add_action( "Down",[Key.KEY_E] )
	add_action( "Left",[Key.KEY_A,Key.KEY_LEFT] )
	add_action( "Right",[Key.KEY_D,Key.KEY_RIGHT] )
	add_action( "Forward",[Key.KEY_W] )
	add_action( "Backward",[Key.KEY_S] )
	
	add_action( "Slow",[Key.KEY_SHIFT] )


func add_action(action_name: String,events: Array):
	InputMap.add_action(action_name)
	
	for e in events:
		if e is Key:
			var k := InputEventKey.new( ) 
			k.keycode = e
			InputMap.action_add_event( action_name,k )
