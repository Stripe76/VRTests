extends Node3D


func get_traverse_path(origin: Vector3,destination: Vector3) -> PackedVector3Array:
	var map: RID = get_world_3d().get_navigation_map()
	if map:
		var path:= NavigationServer3D.map_get_path(map,origin,destination,true)
		if path.size() > 1:
			path.remove_at(0)
		for i in path.size():
			path[i].y = 0			
		#prints("Path:",origin,"->",path)
		
		return path
	return PackedVector3Array()
