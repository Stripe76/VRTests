class_name DataBinder extends Node

var signals : Dictionary
var data_source : RefCounted

func set_datasource(ds):
	data_source = ds

func get_value(property : String,value):
	if data_source:
		data_source.get_value(property,value)


func set_value(node : Node,property : String,value):
	if data_source:
		data_source.set_value(property,value)

func on_property_changed(node : Node,property : String):
	if signals.has(property):
		var subscribers : Array = signals[property]
		if subscribers:
			for n in subscribers:
				if n != node:
					n.property_changed()

func subscribe(node : Node, property : String):
	var subscribers
	if signals.has(property):
		subscribers = signals[property]
	else:
		subscribers = []
		signals[property] = subscribers
	subscribers.append(node)
