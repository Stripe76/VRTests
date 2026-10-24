extends Node3D

@onready var ui := $UIContainer/UI
@onready var ui_container := $UIContainer
@onready var ui_world_view : SubViewport = $UIContainer/WorldView/SubViewport

@onready var world  = $World
@onready var player := $Player
@onready var scene_manager : SceneManager = $SceneManager

var ui_active := false


func _init() -> void:
	generate_action_map()


func _ready() -> void:
	scene_manager.set_world(world)
	scene_manager.set_library(ui.get_library( ))
	
	ui.set_scene_manager(scene_manager)
	
	switch_ui()


func _input(event: InputEvent) -> void:
	if event.is_action_released("SwitchMode"):
		switch_ui()
	elif event.is_action_released("StartAnimation"):
		#scene_manager.toggle_animation("walking_ik")
		scene_manager.toggle_ragdoll()


func switch_ui():
	ui_active = not ui_active
	
	if ui_active:
		player.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	ui_container.visible = ui_active
	
	if ui_active:
		player.reparent(ui_world_view)
	else:
		player.reparent(self)


func generate_action_map():
	#add_action("SwitchMode",[MouseButton.MOUSE_BUTTON_RIGHT,KEY_ESCAPE])
	add_action("SwitchMode",[KEY_ESCAPE])
	
	add_action("NextMesh",[Key.KEY_2])
	add_action("NextMaterial",[Key.KEY_1])
	add_action("StartAnimation",[Key.KEY_SPACE])


func add_action(action_name: String,events: Array):
	InputMap.add_action(action_name)
	
	for e in events:
		if e is Key:
			var k := InputEventKey.new( ) 
			k.keycode = e
			InputMap.action_add_event(action_name,k)
		if e is MouseButton:
			var b := InputEventMouseButton.new()
			b.button_index = e
			InputMap.action_add_event(action_name,b)
