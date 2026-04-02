@tool
class_name VAMOBJMesh extends Resource

@export var vertices : PackedVector3Array
@export var indeces : PackedInt32Array
@export var normals : PackedVector3Array
@export var uvs : PackedVector2Array
@export var materials : PackedInt32Array


func _init(p_detachment_leaders = []):
	vertices = []
	indeces = []
	normals = []
	uvs = []
	materials = []
