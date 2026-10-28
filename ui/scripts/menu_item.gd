@tool
extends Node

class_name MenuItem

@export var name_override : String
@export var command : String
@export var parameter : String
@export var sub_parameter : String

static func create(title: String, command: String) -> MenuItem:
	var instance = MenuItem.new()
	instance.title = title
	instance.command = command
	return instance
