@tool
extends Node

class_name MenuItem

@export var name_override : String
@export var command : String
@export var parameter : String
@export var sub_parameter : String
@export var drag_data_type : String

var button : Control


static func create(title: String,item_command: String) -> MenuItem:
	var instance = MenuItem.new()
	instance.title = title
	instance.command = item_command
	return instance
