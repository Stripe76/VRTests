@tool
extends Node

class_name MenuItem

@export var title : String:
	set(value):
		title = value
		name = title
	get:
		return title
	
@export var command : String
@export var parameter : String

static func create(title: String, command: String) -> MenuItem:
	var instance = MenuItem.new()
	instance.title = title
	instance.command = command
	return instance
