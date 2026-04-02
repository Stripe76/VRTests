extends XRController3D

signal rotate_object(rotation)

@export var player : Node3D

var selected_slider
var base_hand_rotation

var ui_visible : bool = false;
var b_was_pressed : bool = false;

func _physics_process(delta: float) -> void:
	var stick = get_vector2("primary")
	
	if selected_slider is HSlider:
		var diff = base_hand_rotation - rotation
		if diff.y > 0.2:
			selected_slider.value += 1
		elif diff.y < -0.2:
			selected_slider.value -= 1
	
	if stick.y > 0.5:
			var trans = Vector3(0,(stick.y-0.5)*delta,0)						
			player.translate(trans)
	if stick.y < -0.5:
			var trans = Vector3(0,(stick.y+0.5)*delta,0)						
			player.translate(trans)
			
	if stick.x > 0.2 or stick.x < -0.2:
		if stick.x > 0.2:
			stick.x -= 0.2
		elif stick.x < -0.2:
			stick.x += 0.2
		player.rotate(Vector3(0,1,0),stick.x*-delta)
	
	if is_button_pressed("by_button"):
		if not b_was_pressed:
			b_was_pressed = true
			get_tree().call_group("UI","toggle_ui")
	else:
		b_was_pressed = false	


func _on_main_panel_slider_clicked(slider) -> void:
	if slider:
		selected_slider = slider
		base_hand_rotation = rotation
