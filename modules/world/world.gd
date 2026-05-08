@tool
extends Node3D

@export_tool_button("Next mesh","ArrowRight") var next = _on_next_mesh

@onready var _vam_actor : VAMActor = $VAMActor

var pages : Dictionary

var daz_model : Daz3DMesh
var library_folder := "/mnt/data/Projects/Godot/library/"
#var library_folder := "d:/Projects/Godot/library/"

var current_mesh = 0
var current_material = 0


const MESHES := [
	"Gemma/Saves/scene/Gemma Redhead V1.json",
	"Amanda/Saves/scene/Amanda.json",
	"Zoey/Saves/scene/Zoey.json",
	"RenVR.Samantha_(HUB)_.1/Saves/scene/Samantha (HUB) .json",
	"JenniA/Saves/scene/JenniA.json",
	"Alba/Saves/scene/ICannotDie/Jenny/Jenny.json",
	"Barbie/Saves/scene/Barbie.json",
	"Keiko/Saves/scene/JUN/KEIKO/Keiko.json",
	"Anita/Saves/scene/Anita.json",
	"Viola/Saves/scene/Viola.json",
	"Rubyrose/Saves/scene/Rubyrose.json",
	"Anya2/Saves/scene/Anya.json",
	"Anita2/Saves/scene/LOOK/creati/Anita.json",
	"Anya/Saves/scene/Anya.json",
	"Merc/Saves/scene/Merc.json",
	"Angel/Saves/scene/Angel.json",
	"Aimee/Saves/scene/Aimee.json",
	"Alina/Saves/scene/Alina.json",
	"Gina/Saves/scene/Gina.json",
	"Serana/Saves/scene/Serana of Coldharbor.json",
	]


func _ready() -> void:
	daz_model = preload("res://modules/VAMActor/resources/Genesis2Female.dsf")
	
	var scene_folder = get_scene_folder(MESHES[current_mesh])
	var scene_file = get_relative_scene_file(MESHES[current_mesh])
	var hair_file = "Barbie/Custom/Hair/Female/RenVR/Barbie.vab"
	
	#_vam_actor = load("res://modules/VAMActor/vam_actor.tscn").instantiate()
	#_vam_actor.name = "VAMActor"
	#add_child(_vam_actor)
	#_vam_actor.owner = self
	
	_vam_actor.load_scene(daz_model,library_folder,scene_folder,scene_file,hair_file)
	#$VAMActor.load_skeleton(daz_model)
	#$VAMActor.load_mesh(daz_model,genitals_model,scene_folder,scene_file)	
	#$VAMActor.look_at = $Player
	#$VAMActor.load_materials_async(library_folder,scene_folder,scene_file)
	
	if not Engine.is_editor_hint() and true:
		$AnimationPlayer.play("walking_ik")


#func set_target(target: Node3D):
	#_vam_actor.look_at = target


func _on_next_mesh(align_material: bool = true) -> void:
	current_mesh += 1
	if current_mesh >= MESHES.size():
		current_mesh = 0
	
	var scene_file := get_relative_scene_file(MESHES[current_mesh])
	var scene_folder := get_scene_folder(MESHES[current_mesh])
	var hair_file = "Barbie/Custom/Hair/Female/RenVR/Barbie.vab"
	
	#_vam_actor.queue_free()
	#
	#_vam_actor = load("res://modules/VAMActor/vam_actor.tscn").instantiate()
	#_vam_actor.name = "VAMActor"
	#add_child(_vam_actor)
	#_vam_actor.owner = self

	#_vam_actor.load_skeleton(daz_model,library_folder,scene_folder,scene_file)
	#_vam_actor.load_mesh_async(daz_model,scene_folder,scene_file,hair_file)
	#_vam_actor.load_scene(daz_model,library_folder,scene_folder,scene_file,hair_file)
	_vam_actor.load_scene_async(daz_model,library_folder,scene_folder,scene_file,hair_file)
	
	#if align_material:
		#current_material = current_mesh
	#
		#scene_file = get_relative_scene_file(MESHES[current_material])
		#scene_folder = get_scene_folder(MESHES[current_material])
		#_vam_actor.load_materials_async(library_folder,scene_folder,scene_file)


func _on_next_materials() -> void:
	current_material += 1
	if current_material >= MESHES.size():
		current_material = 0
	
	var scene_file := get_relative_scene_file(MESHES[current_material])
	var scene_folder := get_scene_folder(MESHES[current_material])
	_vam_actor.load_materials_async(library_folder,scene_folder,scene_file)


func get_scene_folder(scene_file: String) -> String:
	return library_folder + scene_file.substr(0,scene_file.find("/")+1)


func get_relative_scene_file(scene_file: String) -> String:
	return scene_file.substr(scene_file.find("/")+1)
