extends Node3D

@onready var world :  WorldScene = $World
@onready var player : PlayerVR = $PlayerVR
@onready var scene_manager : SceneManager = $SceneManager

var xrInterface : XRInterface

var ui : UI
var ui_active := false

var _library := LibraryManager.new()


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
			
	_library.LoadData("/mnt/data/Games/Virtamate/AddonPackages/")
	#_library.LoadData("/mnt/data/Projects/Godot/library/")
	
	scene_manager.set_world(world)
	scene_manager.set_library(_library)
	#scene_manager.select_looks(39)
	
	ui = UI.new(_library,
				scene_manager,
				$PlayerVR/MainMenu,
				$PlayerVR/MainPanel,
				$PlayerVR/Persons,
				null)
	
	ui.pointer_sprite = PointerSprite.new()
	ui.pointer_sprite.visible = false
	player.mouse_pointer = ui.pointer_sprite
	
	add_child(ui)


func _on_openxr_pose_recentered():
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)
