@tool
class_name RagdollBone extends PhysicalBone3D

var _bone_idx : int
var _person_id : int


func _init(person_id:int, bone_idx: int):
	_bone_idx = bone_idx
	_person_id = person_id


func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().call_group("UI","person_clicked",_person_id)
