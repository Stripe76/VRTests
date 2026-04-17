class_name PersonHandle
extends Area3D

@export var spring_pusher : SpringPusher

var limb : PersonLimb

var press_to_hold := true

func pick_up(node: XRToolsFunctionPickup):
		#print("pick_up")
	if limb:
		limb.pinned_on = true
		
		var remote : RemoteTransform3D =  node.find_child("RemoteTransform")
		if remote:
			remote.remote_path = limb.ik_target.get_path()
	pass

func let_go(node: XRToolsFunctionPickup,_linearVel,_angularVel):
	var remote : RemoteTransform3D =  node.find_child("RemoteTransform")
	if remote:
		remote.remote_path = NodePath()


func can_pick_up(node) -> bool:
	#print("can_pick_up")
	return true


func is_picked_up():
	return false


func request_highlight(node,higjlight):
	pass
