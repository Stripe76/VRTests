extends Node3D

@onready var world  = %World
@onready var player := %Player
@onready var container := $UI
@onready var world_view := $UI/Container/WorldView/SubViewport
@onready var scene_manager : SceneManager = $SceneManager

var ui : UI
var ui_active := false

var _library := LibraryManager.new()


func _init() -> void:
	generate_action_map()


func _ready() -> void:
	_library.LoadData("/mnt/data/Games/Virtamate/AddonPackages/")
	#_library.LoadData("/mnt/data/Projects/Godot/library/")
	
	scene_manager.set_world(world)
	scene_manager.set_library(_library)
	
	ui = UI.new(_library,
				scene_manager,
				%MainMenu,
				%MainPanel,
				%Persons,
				%FocusCamera)
	add_child(ui)
	
	switch_ui()


func _input(event: InputEvent) -> void:
	if event.is_action_released("SwitchMode"):
		switch_ui()
	elif event.is_action_released("StartAnimation"):
		#scene_manager.toggle_animation("walking_ik")
		scene_manager.toggle_ragdoll()
	elif event.is_action_released("NextPerson"):
		scene_manager.select_next_person()


func switch_ui():
	ui_active = not ui_active
	
	if ui_active:
		player.visible = false
		player.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		player.visible = true
		player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	container.visible = ui_active
	ui.show_add_button = ui_active


func generate_action_map():
	add_action("SwitchMode",[KEY_ESCAPE])
	add_action("NextPerson",[KEY_TAB])
	
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
