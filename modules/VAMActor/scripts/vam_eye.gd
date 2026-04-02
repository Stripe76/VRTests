@tool
class_name VAMEye
extends Node3D

@export_range(0.0,5.0) var eye_color : float:
	set(value): 
		eye_color = value
		set_eye_color(eye_color)


const COLORS : Array = [
	[Color("ffffffff"),Color("c4e4f8ff"),Color("c4e4f8ff"),Color("217db1ff")],
	[Color("1b6f9fff"),Color("1b6f9fff"),Color("1b6f9fff"),Color("1b6f9fff")],
	[Color("532900ff"),Color("4c2500ff"),Color("c6d88eff"),Color("d4d579ff")],
	[Color("#FFFFFF"),Color("#FFFFFF"),Color("#FFFFFF"),Color("#FFFFFF")],
	[Color("#abd46b"),Color("#bd7852"),Color("#63a6bd"),Color("#f5ff4d")],
	[Color("#000000"),Color("#000000"),Color("#000000"),Color("#000000")],
	[Color("#000000"),Color("#000000"),Color("#000000"),Color("#000000")],
]


func _ready() -> void:
	$Eye.transform = $Eye.transform.scaled(Vector3(0.035,0.035,0.035))

func set_offset(offset: Vector3):
	$Eye.position = offset
	
	#set_eye_color(0)


func set_eye_color(value: float):
	var base : int = floor(value)
	if $Eye and base >= 0 and base+1 < COLORS.size():
		var material : ShaderMaterial = $Eye.get_surface_override_material(0)
		if material:
			value -= base
			
			var color_out1 = lerp(COLORS[base][0],COLORS[base+1][1],value)
			var color_in1 = lerp(COLORS[base][1],COLORS[base+1][0],value)
			var color_out2 = lerp(COLORS[base][2],COLORS[base+1][3],value)
			var color_in2 = lerp(COLORS[base][3],COLORS[base+1][2],value)
			
			material.set_shader_parameter("iris_color_outer_1",color_out1)
			material.set_shader_parameter("iris_color_inner_1",color_in1)
			material.set_shader_parameter("iris_color_outer_2",color_out2)
			material.set_shader_parameter("iris_color_inner_2",color_in2)
	
	
	
