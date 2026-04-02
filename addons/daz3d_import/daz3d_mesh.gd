@tool
class_name Daz3DMesh extends Resource

@export var vertices : PackedVector3Array
@export var normals : PackedVector3Array
@export var indeces : PackedInt32Array
@export var uvs : PackedVector2Array
@export var materials : PackedInt32Array
@export var bones : Array
@export var weights : Array
@export var linked_vertices : Dictionary


func _init(p_detachment_leaders = []):
	vertices = []
	normals = []
	indeces = []
	uvs = []
	materials = []
	bones = []
	weights = []
	linked_vertices = {}
