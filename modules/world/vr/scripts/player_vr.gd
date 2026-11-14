class_name PlayerVR extends Node3D

#@export var target : Node3D
@export var mouse_pointer : Sprite2D:
	set(value):
		mouse_pointer = value
		
		#if main_menu:
			#main_menu.mouse_pointer = mouse_pointer
		if main_panel:
			main_panel.mouse_pointer = mouse_pointer
	get:
		return mouse_pointer

@onready var main_menu := $XRPlayer/MainMenu
@onready var main_panel := $XRPlayer/MainPanel

@onready var left_hand := $XRPlayer/LeftHand
@onready var right_hand := $XRPlayer/RightHand

var ui_visible : bool = true


func _ready() -> void:
	#main_menu.mouse_pointer = mouse_pointer
	main_panel.mouse_pointer = mouse_pointer
	
	main_panel.gui_drag_threshold = 25
	
	$XRPlayer/RightHand/FunctionPointer.pointing_event.connect(pointing_event)


func _process(_delta: float) -> void:
	if mouse_pointer and ui_visible:
		right_hand.can_move = not mouse_pointer.visible
	else:
		right_hand.can_move = true


func toggle_ui():
	ui_visible = not ui_visible
	main_menu.visible = ui_visible
	main_panel.visible = ui_visible


func pointing_event(event: XRToolsPointerEvent):
	var parent : Node = event.target.get_parent()
	if parent and parent.has_method("pointing_event"):
		parent.pointing_event(event)
