extends ProductionBuilding
class_name GarageImp

var is_garage_active: bool = false
@onready var animPlayer := $AnimationPlayer
@onready var spawn_point := $SpawnPoint
@onready var exit_point := $ExitPoint

func _ready():
	super()
	available_items = {
		"Soldier/soldier": { "icon": preload("res://entities/Units/USA/Infantry/Soldier/soldier_icon.PNG"), "cost": 100, "time": 5.0}
	}
	icon = preload("res://features/GUI/textures/barracks.png")
	animPlayer.animation_finished.connect(_on_animation_finished)

func setSelected(val: bool):
	if is_garage_active:
		return true
	super(val)
	if isSelected:
		animPlayer.play("Selected")
	else:
		animPlayer.stop()

func on_production_complete(unit_name: String):
	is_garage_active = true
	animPlayer.play("GarageDoorOpening")
	await animPlayer.animation_finished

	var path = "res://entities/Units/USA/Infantry/" + unit_name + ".tscn"
	var unit_instance = load(path).instantiate()
	get_parent().add_child(unit_instance)
	unit_instance.global_transform.origin = spawn_point.global_transform.origin
	unit_instance.move_to_exit_point(exit_point.global_transform.origin)

	await unit_instance.reached_exit
	animPlayer.play("GarageDoorClose")
	await animPlayer.animation_finished

func _on_animation_finished(anim_name: String):
	if anim_name == "GarageDoorClose":
		is_garage_active = false
