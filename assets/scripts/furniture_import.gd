@tool
extends ImportBase

func _post_import(scene: Node) -> Object:
	export_node_scenes(scene,"","furnitures",false)
	
	return scene
