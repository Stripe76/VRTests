@tool
extends ImportBase

const TEXTURES_SUBFOLDER = "textures"


func _post_import(scene: Node) -> Object:
	#move_textures(scene)
	
	set_walls_hide_script(scene.find_child("Scene Collection"))
	
	export_walls_scene(scene,"Walls")
	
	export_node_scenes(scene,"Plants")
	export_node_scenes(scene,"Objects")
	export_node_scenes(scene,"Fixtures")
	export_node_scenes(scene,"Furnitures")
	
	var scene_collection = scene.find_child("Scene Collection")
	if scene_collection:
		scene.remove_child(scene_collection)
		
	return scene


func set_walls_hide_script(scene: Node):
	if scene:
		var walls_dir := {
			"NorthWall":Vector3.BACK,
			"SouthWall":Vector3.FORWARD,
			"EastWall":Vector3.LEFT,
			"WestWall":Vector3.RIGHT,
			"Floor":Vector3.UP,
			"Ceiling":Vector3.DOWN,
			}
		for walls in scene.get_children():
			print("Walls scripts")
			if walls.name.begins_with("Walls"):
				for w in walls.get_children():
					if walls_dir.has(w.name):
						prints("- ",w.name)
						w.set_script(load("res://assets/scripts/walls_hide.gd"))
						w.set("wall_normal",walls_dir[w.name])
				break


func export_walls_scene(scene: Node3D,collection_name: String):
	var collection = scene.find_child(collection_name)
	if collection:
		prints(collection_name)
		var packed_scene := PackedScene.new()
		set_owner(collection,collection)
		packed_scene.pack(collection)
		var path := "res://assets/" + collection_name.to_lower() + "/" + scene.name.to_lower() + ".scn"
		var error := ResourceSaver.save(packed_scene,path)
		prints("-",collection_name,"->",path,":",error_string(error))
		scene.remove_child(collection)
		collection.queue_free()
		
		var new_node = packed_scene.instantiate()
		new_node.scene_file_path = path
		scene.add_child(new_node)
		new_node.owner = scene
		#break


func move_textures(scene: Node):
	var glb_dir := get_source_file().get_base_dir()
	var texture_dir := glb_dir.path_join(TEXTURES_SUBFOLDER)
	var moved_textures: Dictionary = {}
	
	_process_mesh_materials(scene,texture_dir,moved_textures)
	
	if not moved_textures.is_empty():
		EditorInterface.get_resource_filesystem().call_deferred("scan")


func _process_mesh_materials(node: Node,target_dir: String,moved_textures: Dictionary):
	if node is MeshInstance3D:
		# Verifica tutti i materiali assegnati alle varie superfici della mesh
		for i in node.get_surface_override_material_count():
			var mat = node.get_surface_override_material(i)
			if mat is StandardMaterial3D:
				_relocate_material_textures(mat, target_dir, moved_textures)
				
		# Verifica anche il materiale interno alla risorsa Mesh stessa
		if node.mesh:
			for i in node.mesh.get_surface_count():
				var mat = node.mesh.surface_get_material(i)
				if mat is StandardMaterial3D:
					_relocate_material_textures(mat, target_dir, moved_textures)
	
	for child in node.get_children():
		_process_mesh_materials(child, target_dir, moved_textures)


func _relocate_material_textures(material: StandardMaterial3D, target_dir: String, moved_textures: Dictionary):
	# Proprietà dei materiali da controllare (puoi estendere la lista se usi rugosità, emissione, ecc.)
	var texture_channels = [
		"albedo_texture", 
		"roughness_texture", 
		"metallic_texture", 
		"normal_texture",
		"ao_texture",          # Ambient Occlusion (se la usi)
		"emission_texture"     # Emission (se hai luci sui mobili)
	]
	
	for channel in texture_channels:
		var tex = material.get(channel)
		if tex is Texture2D and tex.resource_path != "":
			var old_path = tex.resource_path
			
			# Se la texture si trova già nella sotto-cartella corretta, saltala
			if old_path.to_lower().contains("/" + TEXTURES_SUBFOLDER.to_lower() + "/"):
				moved_textures[old_path] = old_path
				continue
				
			var file_name = old_path.get_file()
			var new_path := target_dir.path_join(file_name)
			
			# Crea la sotto-cartella se non esiste ancora
			if not DirAccess.dir_exists_absolute(target_dir):
				DirAccess.make_dir_recursive_absolute(target_dir)
			
			# Sposta il file fisicamente sul disco (se non è già stato fatto in questo ciclo)
			if not moved_textures.has(old_path):
				if FileAccess.file_exists(old_path):
					var dir = DirAccess.open("res://")
					# Sposta il file della texture originale
					dir.rename(old_path, new_path)
					# Sposta anche il file .import associato per non corrompere Godot
					if FileAccess.file_exists(old_path + ".import"):
						dir.rename(old_path + ".import", new_path + ".import")
			moved_textures[old_path] = old_path
			
			# Riassegna la texture caricando il file dal nuovo percorso corretto
			var new_tex = load(new_path)
			if new_tex:
				material.set(channel, new_tex)
