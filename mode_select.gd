extends Control

var wait_for_it : String

const vr_scene = "res://modules/world_vr/vr.tscn"
const sbs_scene = "res://modules/world_sbs/sbs.tscn"


func _process(_delta: float) -> void:
	if wait_for_it:
		var progress := []
		var status = ResourceLoader.load_threaded_get_status(wait_for_it,progress)
		
		if ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS == status:
			$HBoxContainer.visible = false
			$ProgressBar.visible = true
			$ProgressBar.value = progress[0]*100
		
		if ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED == status:
			$ProgressBar.visible = false
			get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(wait_for_it))


func _on_button_vr_pressed() -> void:
	ResourceLoader.load_threaded_request(vr_scene)
	wait_for_it = vr_scene


func _on_button_sbs_pressed() -> void:
	ResourceLoader.load_threaded_request(sbs_scene)
	wait_for_it = sbs_scene
