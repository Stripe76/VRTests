@tool
extends Node3D

@export_group("Spot")
@export_range(5,25) var range : float = 5.0:
	set(value):
		range = value
		set_spot_value("spot_range",range)
	get:
		return range
@export_range(0.5,4.0) var attenuation : float = 2.0:
	set(value):
		attenuation = value
		set_spot_value("spot_attenuation",attenuation)
	get:
		return attenuation
@export_range(5.0,180.0) var angle : float = 40.0:
	set(value):
		angle = value
		set_spot_value("spot_angle",angle)
	get:
		return angle
@export_exp_easing("angle_attenuation") var angle_attenuation : float = 1.0:
	set(value):
		angle_attenuation = value
		set_spot_value("spot_angle_attenuation",angle_attenuation)
	get:
		return angle_attenuation

@export_group("Light")
@export_range(.5,20.0) var energy : float = 2.0:
	set(value):
		energy = value
		set_spot_value("light_energy",energy)
		set_spot_value("light_indirect_energy",energy)
	get:
		return energy


func set_spot_value(property: String,value: float):
	for c in get_children():
		if c is SpotLight3D:
			c.set(property,value)
