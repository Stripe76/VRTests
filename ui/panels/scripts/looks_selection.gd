extends Control

@onready var items := $ScrollContainer/Items

var library : LibraryManager
var looks_button : PackedScene = load("res://ui/panels/looks_button.tscn")


func _ready() -> void:
	if library and items:
		var count := library.Looks_GetCount()
		for i in count:
			var b : LooksButton = looks_button.instantiate().with_data(library,i)
			items.add_child(b)
