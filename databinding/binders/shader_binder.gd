extends DataBinder

@export var shader : ShaderMaterial

func get_value(property : String,value):
	if shader:
		shader.set_shader_parameter(property,value)


func set_value(node : Node,property : String,value):
	if shader:
		return shader.get_shader_parameter(property)
	return null
