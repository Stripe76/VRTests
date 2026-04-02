extends RayCast3D

# Future proofing.
#const XRServer = ARVRServer

var _is_activating_gui := false
var _old_raycast_collider: Area3D = null
var _old_viewport: SubViewport = null
var _old_viewport_point: Vector2
var _ws := 1.0

@onready var _controller : XRController3D = get_parent()

func _process(_delta):
	return
	_scale_ray()
	var raycast_collider = get_collider()
	# First of all, check if we need to release a previous mouse click.
	if _old_raycast_collider and raycast_collider != _old_raycast_collider:
		_release_mouse()
	elif raycast_collider:
		_try_send_input_to_gui(raycast_collider)


func _try_send_input_to_gui(raycast_collider):
	var sprite = raycast_collider.get_child(0) as Sprite3D
	#if not (viewport is Viewport):
		#return # This isn't something we can give input to.
	if not sprite:
		return
	var viewport = sprite.viewport as SubViewport

	var collider_transform = raycast_collider.global_transform
	if (collider_transform * global_transform.origin).z < 0:
		return # Don't allow pressing if we're behind the GUI.

	# Convert the collision to a relative position. Expects the 2nd child to be a CollisionShape.
	var shape_size = raycast_collider.get_child(1).shape.extents * 2
	var collision_point = get_collision_point()	
	var collider_scale = collider_transform.basis.get_scale()
	var local_point = sprite.to_local(collision_point)
	#local_point /= (collider_scale * collider_scale)
	local_point /= shape_size
	local_point += Vector3(0.5, -0.5, 0) # X is about 0 to 1, Y is about 0 to -1.	
	
	# Find the viewport position by scaling the relative position by the viewport size. Discard Z.
	var viewport_size = Vector2(viewport.size.x,viewport.size.y)
	var viewport_point = Vector2(local_point.x, -local_point.y) * viewport_size

	# Send mouse motion to the GUI.
	var event : InputEventMouseMotion = InputEventMouseMotion.new()
	var from : Vector2 = _old_viewport_point
	var to : Vector2 = viewport_point
	event.relative = to - from
	event.position = to
	viewport.push_input(event)
	
	print(to)

	# Figure out whether or not we should trigger a click.
	var desired_activate_gui := false
	var distance = global_transform.origin.distance_to(collision_point) / XRServer.world_scale
	if distance < 0.1:
		desired_activate_gui = true # Allow "touching" the GUI.
	else:
		desired_activate_gui = _is_trigger_pressed() # Else, use the trigger.

	# Send a left click to the GUI depending on the above.
	if desired_activate_gui != _is_activating_gui:
		var buttonevent = InputEventMouseButton.new()
		buttonevent.pressed = desired_activate_gui
		buttonevent.button_index = MOUSE_BUTTON_LEFT
		buttonevent.position = viewport_point
		viewport.push_input(buttonevent)
		_is_activating_gui = desired_activate_gui
		_old_raycast_collider = raycast_collider
		_old_viewport_point = viewport_point
		_old_viewport = viewport


func _release_mouse():
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = _old_viewport_point	
	_old_viewport.push_input(event)
	
	_old_raycast_collider = null
	_is_activating_gui = false


func _is_trigger_pressed():
	return _controller.is_button_pressed("ax_button")


func _scale_ray():
	var new_ws = XRServer.world_scale
	if _ws != new_ws:
		_ws = new_ws
		scale = Vector3.ONE * _ws
