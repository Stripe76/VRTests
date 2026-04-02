class_name ShaderBinder extends DataBinder

func get_value(property : String,value):
	if data_source:
		data_source.get_shader_parameter(property,value)


func set_value(node : Node,property : String,value):
	if data_source is ShaderMaterial:
		data_source.set_shader_parameter(property,value)
		on_property_changed(node,property)
