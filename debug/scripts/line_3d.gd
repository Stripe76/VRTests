class_name Line3D extends MeshInstance3D

var material : StandardMaterial3D

func _init() -> void:
	mesh = ImmediateMesh.new()
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	set_material_override(material)


func draw_path(path: PackedVector3Array,color: Color = Color(1,0,1)) -> void:
	if material:
		material.albedo_color = color
	var im: ImmediateMesh = mesh
	im.clear_surfaces()
	#im.surface_begin(Mesh.PRIMITIVE_POINTS, null)
	#im.surface_add_vertex(path[0])
	#im.surface_add_vertex(path[path.size() - 1])
	#im.surface_end()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP,null)
	for current_vector in path:
		im.surface_add_vertex(current_vector)
	im.surface_end()


func draw_forward_path(length: float = 1) -> void:
	draw_path([Vector3.ZERO,Vector3.FORWARD*length])


func draw_back_path(length: float = 1) -> void:
	draw_path([Vector3.ZERO,Vector3.BACK*length])
