extends OpenXRCompositionLayerQuad

const NO_INTERSECTION = Vector2(-1.0, -1.0)

@export var controller : XRController3D
@export var hand_action : String = "trigger_click"
@export var mouse_action : String = "ax_button"

var was_pressed : bool = false
var was_intersect : Vector2 = NO_INTERSECTION

func _process(_delta):
	# Hide our pointer, we'll make it visible if we're interacting with the viewport.
	$Pointer.visible = false

	if controller and layer_viewport:
		var controller_t : Transform3D = controller.global_transform
		var intersect : Vector2 = intersects_ray(controller_t.origin, -controller_t.basis.z)

		if controller.get_input("grip"):
			return

		if intersect != NO_INTERSECTION:
			var mouse_pressed : bool = controller.is_button_pressed(mouse_action)
			var hand_pressed : bool = controller.is_button_pressed(hand_action)
			
			# Place our pointer where we're pointing
			var pos : Vector3 = _intersect_to_global_pos(intersect)
			$Pointer.visible = true
			$Pointer.global_position = pos						

			if was_intersect != NO_INTERSECTION and intersect != was_intersect:
				# Pointer moved
				var event : InputEventMouseMotion = InputEventMouseMotion.new()
				var from : Vector2 = _intersect_to_viewport_pos(was_intersect)
				var to : Vector2 = _intersect_to_viewport_pos(intersect)
				if was_pressed:
					event.button_mask = MOUSE_BUTTON_MASK_LEFT
				event.relative = to - from
				event.position = to
				layer_viewport.push_input(event)


			if hand_pressed and not was_pressed:
				var event : InputEventMouseButton = InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_RIGHT
				event.button_mask = MOUSE_BUTTON_MASK_RIGHT
				event.pressed = true
				event.position = _intersect_to_viewport_pos(intersect)
				layer_viewport.push_input(event)								
			elif not hand_pressed and was_pressed:
				var event : InputEventMouseButton = InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_RIGHT
				event.pressed = false
				event.position = _intersect_to_viewport_pos(intersect)
				layer_viewport.push_input(event)			

			if not mouse_pressed and was_pressed:
				# Button was let go?
				var event : InputEventMouseButton = InputEventMouseButton.new()
				event.button_index = 1
				event.pressed = false
				event.position = _intersect_to_viewport_pos(intersect)
				layer_viewport.push_input(event)
			elif mouse_pressed and not was_pressed:
				# Button was pressed?
				var event : InputEventMouseButton = InputEventMouseButton.new()
				event.button_index = 1
				event.button_mask = MOUSE_BUTTON_MASK_LEFT
				event.pressed = true
				event.position = _intersect_to_viewport_pos(intersect)
				layer_viewport.push_input(event)				

			was_pressed = mouse_pressed or hand_pressed
			was_intersect = intersect
		else:
			was_pressed = false
			was_intersect = NO_INTERSECTION

func mouseClick(pos: Vector3):
	var intersect : Vector2 = intersects_ray(pos, pos + Vector3.FORWARD)
	
	var event : InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = 1
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.pressed = true
	var a = _intersect_to_viewport_pos(intersect)
	event.position = a
	#layer_viewport.push_input(event)				

	event.pressed = false
	#layer_viewport.push_input(event)				
	
			
func _intersect_to_global_pos(intersect : Vector2) -> Vector3:
	if intersect != NO_INTERSECTION:
		var local_pos : Vector2 = (intersect - Vector2(0.5, 0.5)) * quad_size
		return global_transform * Vector3(local_pos.x, -local_pos.y, 0.0)
	else:
		return Vector3()
		
func _intersect_to_viewport_pos(intersect : Vector2) -> Vector2i:
	if layer_viewport and intersect != NO_INTERSECTION:
		var pos : Vector2 = intersect * Vector2(layer_viewport.size)
		return Vector2i(pos)
	else:
		return Vector2i(-1, -1)
