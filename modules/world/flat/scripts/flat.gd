extends Node3D

@onready var ui := $UI
@onready var player := $Player

var ui_active := false

func _ready() -> void:
	generate_action_map()
	
	switch_ui()


func _unhandled_input(event):
	if not ui_active:
		if event.is_action_released("NextMesh"):
			$World._on_next_mesh()
			#$World/AnimationPlayer.stop()
			$World/AnimationPlayer.pause()
		elif event.is_action_released("NextMaterial"):
			$World._on_next_materials()
		elif event.is_action_released("StartAnimation"):
			if $World/AnimationPlayer.is_playing():
				$World/AnimationPlayer.pause()
			else:
				$World/AnimationPlayer.play()
	
	if event.is_action_released("SwitchMode"):
		switch_ui()


func switch_ui():
	if ui_active:
		ui_active = false
		ui.visible = ui_active
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		ui_active = true
		ui.visible = ui_active
		player.process_mode = Node.PROCESS_MODE_DISABLED
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


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
	add_action("SwitchMode",[MouseButton.MOUSE_BUTTON_RIGHT])
	
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
