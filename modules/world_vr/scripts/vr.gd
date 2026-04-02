extends Node3D

var xrInterface : XRInterface


func _ready() -> void:
	if not Engine.is_editor_hint():
		xrInterface = XRServer.find_interface("OpenXR")	
		
		if xrInterface and xrInterface.is_initialized():
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			get_viewport().use_xr = true
			get_viewport().vrs_mode = Viewport.VRS_XR
			#get_viewport().size = Vector2(1024,768);
			#XRServer.world_scale = 1.0
			xrInterface.pose_recentered.connect(_on_openxr_pose_recentered)
			
			XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT,true)
			
	#$World.set_target($PlayerVR.target)
	
	$PlayerVR.next_mesh.connect($World._on_next_mesh)
	$PlayerVR.next_materials.connect($World._on_next_materials)


func _on_openxr_pose_recentered():
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)
