extends Node3D

var vr_mode := true

func _ready() -> void:
	if vr_mode:
		add_child(load("res://modules/world/vr/vr.tscn").instantiate( ))
	else:
		add_child(load("res://modules/world/flat/flat.tscn").instantiate( ))
