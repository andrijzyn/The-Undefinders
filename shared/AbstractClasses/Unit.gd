extends Node3D
class_name Unit

var Component_Basic: Component_Basic
var Component_Moving: Component_Moving
var Component_Attack: Component_Attack

func _init() -> void:
	add_to_group(Constants.selectable)
	add_to_group(Constants.movable)
