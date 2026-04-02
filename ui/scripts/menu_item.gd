extends Node

class_name MenuItem

@export var Title : String
@export var Command : String
@export var Parameter : String

static func create(title: String, command: String) -> MenuItem:
	var instance = MenuItem.new()
	instance.Title = title
	instance.Command = command
	return instance
