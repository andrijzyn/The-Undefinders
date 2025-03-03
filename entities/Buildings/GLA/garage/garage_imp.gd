extends Node3D
class_name GarageImp

var available_items = {
	"Soldier/soldier": { "icon": preload("res://entities/Units/USA/Infantry/Soldier/soldier_icon.PNG"), "cost": 100 }
}

var icon: Texture2D = preload("res://features/GUI/textures/barracks.png")
var is_builder: bool = false
var isSelected: bool = false;
@onready var animPlayer := $AnimationPlayer
@onready var spawn_point := $SpawnPoint

func _init() -> void:
	add_to_group(Constants.selectable)
	add_to_group(Constants.mouseChanger)

func setSelected(val:bool):
	isSelected = val
	if isSelected == true:
		animPlayer.play("Selected")
	else: animPlayer.stop()

func get_available_items() -> Dictionary:
	return available_items 

func spawn_unit(unit_name: String):
	await get_tree().create_timer(10.0).timeout
	animPlayer.play("GarageDoorOpening")
	await animPlayer.animation_finished

	var path = "res://entities/Units/USA/Infantry/" + unit_name + ".tscn"
	var unit_instance = load(path).instantiate()
	get_parent().add_child(unit_instance)
	unit_instance.global_transform.origin = spawn_point.global_transform.origin
	
	await get_tree().create_timer(5.0).timeout
	animPlayer.play("GarageDoorClose")
	await animPlayer.animation_finished
