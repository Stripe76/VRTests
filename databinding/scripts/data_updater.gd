extends Node

@export var property_name : String

var data_binder : DataBinder

func _ready() -> void:
	var parent = get_parent()
	if parent is HSlider:
		parent.value_changed.connect(_on_value_changed)


func _on_value_changed(value: float):
	if not data_binder:
		data_binder = _get_data_binder()
	if data_binder:
		data_binder.set_value(get_parent(),property_name,value)


func _get_data_binder() -> DataBinder:
	var data_context = find_parent("DataContext") as DataContext
	if data_context:
		return data_context.data_binder
	return null
