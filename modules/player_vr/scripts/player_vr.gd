extends Node3D

@export var target : Node3D
@export var collision : Vector3

signal next_mesh()
signal next_materials()

signal slider_changed(value)

var ui_visible : bool = true

func _ready() -> void:
	target = $XRPlayer
#	var a = get_node("XRPlayer/RightHand/RightHand/Hand_Nails_R/Armature/Skeleton3D/BoneAttachment3D/Poke") as XRToolsPoke
#	if a:
#		a.pointing_event.connect(func ():
#			print("area enter")
#			var poke = get_node("XRPlayer/RightHand/RightHand/Hand_Nails_R/Armature/Skeleton3D/BoneAttachment3D/Poke") as Node3D
#			$XRPlayer/Navigation.mouseClick(poke.global_position)
#			)


func _physics_process(delta: float) -> void:
	var pos = $XRPlayer/RightHand/RightHand/Hand_Nails_R/Armature/Skeleton3D/BoneAttachment3D/Poke.global_position
	pos.z += 0.025
	pos.y += 0.01
	collision = pos


func _on_main_panel_slider_changed(value: Variant) -> void:
	slider_changed.emit(value)


func toggle_ui():
	ui_visible = not ui_visible
	$XRPlayer/Navigation.visible = ui_visible
	$XRPlayer/MainPanel.visible = ui_visible
	$XRPlayer/UI.visible = ui_visible
	

func set_pages(pages : Dictionary):
	$UIViewports.pages = pages


func set_head_skin_shader(shader):
	$UIViewports.set_head_skin_shader(shader)


func _on_right_hand_button_pressed(name: String) -> void:
	if name == "ax_button":
		next_mesh.emit()
	if name == "by_button":
		next_materials.emit()
