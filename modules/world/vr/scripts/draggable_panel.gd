extends XRToolsInteractableBody

@export var camera : XRCamera3D

@onready var initial_offset : Vector3 = position

var grabbed := false
var distance := 0.0

var initial_camera_position : Vector3 = position


func _ready() -> void:
	pointer_event.connect(pointing_event)
	
	if camera:
		initial_camera_position = camera.position


func _process(_delta):
	if not visible or grabbed:
		return
		
	if camera:
		var camera_pos := camera.position - initial_camera_position
		#camera_pos = Vector3((camera_pos.x*2) as int / 2.0,(camera_pos.y*2) as int / 2.0,(camera_pos.z*2) as int / 2.0)
		position = initial_offset + camera_pos


func pointing_event(event: XRToolsPointerEvent):
	if event.event_type == XRToolsPointerEvent.Type.PRESSED:
		grabbed = true
		distance = (event.pointer.global_position - global_position).length()
		
		event.pointer.target = self
	elif event.event_type == XRToolsPointerEvent.Type.RELEASED:
		grabbed = false
		
		event.pointer.target = null
	elif event.event_type == XRToolsPointerEvent.Type.MOVED and grabbed:
		var controller_t : Transform3D = event.pointer.global_transform
		global_position = controller_t.origin -controller_t.basis.z * distance
		initial_offset = position
		
		if camera:
			initial_camera_position = camera.position
		
		look_at(controller_t.origin,Vector3.UP,true)
