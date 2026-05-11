extends Control

@onready var _main_panel := $Main/MainPanel

var _library := LibraryManager.new()

var _looks_selection

func _init() -> void:
	_library.LoadData("/mnt/data/Games/Virtamate/AddonPackages/")
	
	_looks_selection = load("res://ui/panels/looks_selection.tscn").instantiate()
	_looks_selection.library = _library


func get_library( ) -> LibraryManager:
	return _library


func set_main_panel(panel: String):
	_main_panel.add_child(_looks_selection)
