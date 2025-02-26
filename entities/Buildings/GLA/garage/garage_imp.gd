extends Node3D
class_name GarageImp

var isSelected: bool = false;
@onready var animPlayer := $AnimationPlayer

func _init() -> void:
	add_to_group(Constants.selectable)
	add_to_group(Constants.mouseChanger)

func setSelected(val:bool):
	isSelected = val
	if isSelected == true:
		animPlayer.play("Выделение|Selected")
	else: animPlayer.stop()
