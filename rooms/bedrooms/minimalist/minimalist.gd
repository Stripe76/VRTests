extends Node3D


func toggle_wall_visibility(wall: String,is_visible: bool):
	if wall == "South" or wall == "All":
		$"Scene Collection/Walls2/SouthWall".visible = is_visible
	if wall == "North" or wall == "All":
		$"Scene Collection/Walls2/North".visible = is_visible
	if wall == "East" or wall == "All":
		$"Scene Collection/Walls2/East".visible = is_visible
	if wall == "West" or wall == "All":
		$"Scene Collection/Walls2/WestWall".visible = is_visible
	if wall == "Ceiling" or wall == "All":
		$"Scene Collection/Walls2/Ceiling".visible = is_visible
	if wall == "Floor" or wall == "All":
		$"Scene Collection/Walls2/Floor".visible = is_visible
