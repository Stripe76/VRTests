@tool
class_name ProceduralMeshInstance3D
extends MeshInstance3D

#func _notification(what):
	#if not Engine.is_editor_hint():
		#return
#
	#print("_notification")  
	#print(what)  
	#
	#match what:
		#NOTIFICATION_EDITOR_PRE_SAVE:
			#if self.mesh:
				#self.mesh.clear_surfaces()

		#NOTIFICATION_EDITOR_POST_SAVE:
			#if self.mesh and self.mesh is ProceduralMesh:
				#self.mesh._generate()

#func _validate_property(property: Dictionary):
	#if property["name"] == "mesh":
		#property["usage"] = PROPERTY_USAGE_NONE
