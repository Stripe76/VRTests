class_name ImportBase extends EditorScenePostImport

func export_node_scenes(scene: Node3D,collection_name: String,export_folder: = "",apply_offset: bool = true):
	export_folder = collection_name.to_lower() if export_folder.is_empty() else export_folder
	
	var collection = scene if collection_name.is_empty() else scene.find_child(collection_name)
	if collection:
		prints(export_folder if collection_name.is_empty() else collection_name)
		for node : Node3D in collection.get_children():
			var packed_scene := PackedScene.new()
			var offset := offset_children_nodes(node) if apply_offset else Vector3.ZERO
			set_owner(node,node)
			packed_scene.pack(node)
			var path := "res://assets/" + export_folder + "/" + node.name.to_lower() + ".scn"
			var error := ResourceSaver.save(packed_scene,path)
			prints("-",node.name,"->",path,":",error_string(error))
			collection.remove_child(node)
			node.queue_free()
			
			var new_node = packed_scene.instantiate()
			new_node.scene_file_path = path
			new_node.position = offset
			collection.add_child(new_node)
			new_node.owner = scene
			#break
		if collection.get_parent():
			collection.owner = null
			collection.get_parent().remove_child(collection)
			scene.add_child(collection)
			collection.owner = scene


func offset_children_nodes(node: Node3D) -> Vector3:
	var offset := Vector3.ZERO
	for c : Node3D in node.get_children():
		if not c is MeshInstance3D:
			for s : Node3D in c.get_children():
				s.position = s.position - offset
			if c.get_child_count() == 0:
				c.queue_free()
		else:
			offset = c.position
			c.position = c.position - offset
	return offset


func set_owner(node: Node3D,owner_to_set:Node3D):
	for c in node.get_children():
		c.owner = owner_to_set
		set_owner(c,owner_to_set)
