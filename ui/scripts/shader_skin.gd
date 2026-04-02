extends Control

var _binder : DataBinder

func set_material_binder(binder):
	_binder = binder
	$"TabContainer/Base tone/DataContext".data_binder = binder

func _skin_color_picked(color):
	_binder.set_value(self,"light_noise",color)
