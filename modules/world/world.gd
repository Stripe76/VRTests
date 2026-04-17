@tool
extends Node3D

var pages : Dictionary

var daz_model : Daz3DMesh
var genitals_model : Mesh
var library_folder := "/mnt/data/Projects/Godot/library/"
#var library_folder := "d:/Projects/Godot/library/"

var current_mesh = 2
var current_material = 2

const MESHES := [
	"Keiko/Saves/scene/JUN/KEIKO/Keiko.json",
	"Anya2/Saves/scene/Anya.json",
	"Anya/Saves/scene/Anya.json",
	"Anita/Saves/scene/Anita.json",
	"Merc/Saves/scene/Merc.json",
	"Barbie/Saves/scene/Barbie.json",
	"Angel/Saves/scene/Angel.json",
	"Rubyrose/Saves/scene/Rubyrose.json",
	"Aimee/Saves/scene/Aimee.json",
	"Alba/Saves/scene/ICannotDie/Jenny/Jenny.json",
	"Alina/Saves/scene/Alina.json",
	"Anita2/Saves/scene/LOOK/creati/Anita.json",
	"Gina/Saves/scene/Gina.json"
	]

func _ready() -> void:
	daz_model = preload("res://modules/VAMActor/resources/Genesis2Female.dsf")
	
	var scene_folder = get_scene_folder(MESHES[current_mesh])
	var scene_file = get_relative_scene_file(MESHES[current_mesh])
	
	$VAMActor.load_scene(daz_model,genitals_model,library_folder,scene_folder,scene_file)
	#$VAMActor.load_skeleton(daz_model)
	#$VAMActor.load_mesh(daz_model,genitals_model,scene_folder,scene_file)	
	#$VAMActor.look_at = $Player
	#$VAMActor.load_materials_async(library_folder,scene_folder,scene_file)
	
	if not Engine.is_editor_hint():
		$AnimationPlayer.play("walking")


func set_target(target: Node3D):
	$VAMActor.look_at = target


func _on_next_mesh(align_material: bool = true) -> void:
	current_mesh += 1
	if current_mesh >= MESHES.size():
		current_mesh = 0
	
	var scene_file := get_relative_scene_file(MESHES[current_mesh])
	var scene_folder := get_scene_folder(MESHES[current_mesh])
	$VAMActor.load_mesh_async(daz_model,genitals_model,scene_folder,scene_file)
	
	if align_material:
		current_material = current_mesh
	
		scene_file = get_relative_scene_file(MESHES[current_material])
		scene_folder = get_scene_folder(MESHES[current_material])
		$VAMActor.load_materials_async(library_folder,scene_folder,scene_file)


func _on_next_materials() -> void:
	current_material += 1
	if current_material >= MESHES.size():
		current_material = 0
	
	var scene_file := get_relative_scene_file(MESHES[current_material])
	var scene_folder := get_scene_folder(MESHES[current_material])
	$VAMActor.load_materials_async(library_folder,scene_folder,scene_file)


func get_scene_folder(scene_file: String) -> String:
	return library_folder + scene_file.substr(0,scene_file.find("/")+1)


func get_relative_scene_file(scene_file: String) -> String:
	return scene_file.substr(scene_file.find("/")+1)
