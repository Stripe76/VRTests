extends OpenXRCompositionLayerQuad

const NO_INTERSECTION = Vector2(-1.0, -1.0)

@export var controller : XRController3D
@export var mouse_pointer : Sprite2D 

@onready var initial_offset : Vector3 = position

var trigger_released := true

var was_pressed : bool = false
var was_intersect : Vector2 = NO_INTERSECTION

var mouse_wheel_counter := 0


func _ready() -> void:
	$PanelArea/CollisionShape3D.shape.size = Vector3(quad_size.x,quad_size.y,0.1)


func _process(_delta):
	if not visible:
		return
		
	if controller and layer_viewport:
		var controller_t : Transform3D = controller.global_transform
		var intersect : Vector2 = intersects_ray(controller_t.origin,-controller_t.basis.z)
		
		var primary := controller.get_vector2("primary")
		if primary.y > 0.1 or primary.y < -0.1:
			if mouse_wheel_counter == 0:
				var event : InputEventMouseButton = InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_WHEEL_UP if primary.y > 0 else MOUSE_BUTTON_WHEEL_DOWN
				event.button_mask = MOUSE_BUTTON_MASK_MIDDLE
				event.pressed = true
				event.position = _intersect_to_viewport_pos(intersect)
				layer_viewport.push_input(event)
				event.pressed = false
				layer_viewport.push_input(event)
			mouse_wheel_counter += 1
			if mouse_wheel_counter > 10-(10 * abs(primary.y)):
				mouse_wheel_counter = 0


func pointing_event(xr_event : XRToolsPointerEvent):
	var controller_t : Transform3D = xr_event.pointer.global_transform
	var intersect : Vector2 = intersects_ray(controller_t.origin,-controller_t.basis.z)
	
	if xr_event.event_type == XRToolsPointerEvent.Type.MOVED:
		var event : InputEventMouseMotion = InputEventMouseMotion.new()
		var from : Vector2 = _intersect_to_viewport_pos(was_intersect)
		var to : Vector2 = _intersect_to_viewport_pos(intersect)
		
		if mouse_pointer:
			mouse_pointer.visible = not (to.x < 0 and to.y < 0)
		
		event.relative = to - from
		event.position = to
		layer_viewport.push_input(event)
		
		was_intersect = intersect
	
	if xr_event.event_type == XRToolsPointerEvent.Type.PRESSED:
		var event : InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
		event.pressed = true
		event.position = _intersect_to_viewport_pos(intersect)
		layer_viewport.push_input(event)
	
	if xr_event.event_type == XRToolsPointerEvent.Type.RELEASED:
		var event : InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
		event.pressed = false
		event.position = _intersect_to_viewport_pos(intersect)
		layer_viewport.push_input(event)
	
	if xr_event.event_type == XRToolsPointerEvent.Type.EXITED:
		if mouse_pointer:
			mouse_pointer.visible = false


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
