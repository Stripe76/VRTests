extends XRController3D

signal rotate_object(rotation)

@export var player : Node3D

var selected_slider
var base_hand_rotation

var ui_visible : bool = false;
var b_was_pressed : bool = false;

var can_move := true
var grip_released := true


func _physics_process(delta: float) -> void:
	var stick = get_vector2("primary")
	
	if selected_slider is HSlider:
		var diff = base_hand_rotation - rotation
		if diff.y > 0.2:
			selected_slider.value += 1
		elif diff.y < -0.2:
			selected_slider.value -= 1
	
	if can_move:
		if stick.y > 0.2:
			stick.y -= 0.2
		elif stick.y < -0.2:
			stick.y += 0.2
		if stick.x > 0.2:
			stick.x -= 0.2
		elif stick.x < -0.2:
			stick.x += 0.2
		
		var trans = basis * Vector3.FORWARD * (stick.y*delta)
		trans.y = 0
		player.translate(trans)
		
		trans = basis * Vector3.RIGHT * (stick.x*delta)
		trans.y = 0
		player.translate(trans)
	
	if is_button_pressed("by_button"):
		if not b_was_pressed:
			b_was_pressed = true
			get_tree().call_group("UI","toggle_ui")
	else:
		b_was_pressed = false
		
	if get_input("grip"):
		if grip_released:
			grip_released = false
			
			$Flashlight.visible = not $Flashlight.visible
	else:
		grip_released = true


func _on_main_panel_slider_clicked(slider) -> void:
	if slider:
		selected_slider = slider
		base_hand_rotation = rotation
