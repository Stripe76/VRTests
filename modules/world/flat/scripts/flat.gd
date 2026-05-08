extends Node3D

@onready var ui := $UIContainer/UI
@onready var ui_container := $UIContainer
@onready var ui_world_view : SubViewport = $UIContainer/WorldView/SubViewport

@onready var world  = $World
@onready var player := $Player

@onready var animation := $World/AnimationPlayer

var ui_active := false


func _init() -> void:
	generate_action_map()


func _ready() -> void:
	world.set_library(ui.get_library( ))
	
	switch_ui()


func _input(event: InputEvent) -> void:
	if event.is_action_released("SwitchMode"):
		switch_ui()
	elif event.is_action_released("StartAnimation"):
		if animation.is_playing():
			animation.pause()
		else:
			animation.play()


func _unhandled_input(event):
	if not ui_active:
		if event.is_action_released("NextMesh"):
			world._on_next_mesh()
			#$World/AnimationPlayer.stop()
			animation.pause()
		elif event.is_action_released("NextMaterial"):
			world._on_next_materials()


func switch_ui():
	if ui_active:
		ui_active = false
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		ui_active = true
		player.process_mode = Node.PROCESS_MODE_DISABLED
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	ui_container.visible = ui_active
	if ui_active:
		player.reparent(ui_world_view)
	else:
		player.reparent(self)


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
	add_action("SwitchMode",[MouseButton.MOUSE_BUTTON_RIGHT,KEY_ESCAPE])
	
	add_action("NextMesh",[Key.KEY_2])
	add_action("NextMaterial",[Key.KEY_1])
	add_action("StartAnimation",[Key.KEY_SPACE])


func add_action(name: String,events: Array):
	InputMap.add_action(name)
	
	for e in events:
		if e is Key:
			var k := InputEventKey.new( ) 
			k.keycode = e
			InputMap.action_add_event( name,k )
		if e is MouseButton:
			var b := InputEventMouseButton.new()
			b.button_index = e
			InputMap.action_add_event( name,b )
