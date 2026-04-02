extends Area3D

func _ready() -> void:
	self.area_entered.connect(areaEntered)
	
func areaEntered():
	print("porco dio")
