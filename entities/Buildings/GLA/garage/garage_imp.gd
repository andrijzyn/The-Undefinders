extends Node3D
class_name GarageImp

var available_items = {
	"Soldier/soldier": { "icon": preload("res://entities/Units/USA/Infantry/Soldier/soldier_icon.PNG"), "cost": 100 }
}

var ui
var icon: Texture2D = preload("res://features/GUI/textures/barracks.png")
var is_builder: bool = false
var isSelected: bool = false;
@onready var animPlayer := $AnimationPlayer
@onready var spawn_point := $SpawnPoint

var production_queue: Array = []
var is_producing: bool = false
const MAX_QUEUE_SIZE: int = 10

func _init() -> void:
	add_to_group(Constants.selectable)
	add_to_group(Constants.mouseChanger)

func _ready() -> void:
	ui = get_tree().get_root().get_node("MainScene/RTS_UI")

func setSelected(val:bool):
	isSelected = val
	if isSelected == true:
		animPlayer.play("Selected")
	else: animPlayer.stop()

func get_available_items() -> Dictionary:
	return available_items 

func spawn_unit(unit_name: String):
	animPlayer.play("GarageDoorOpening")
	await animPlayer.animation_finished

	var path = "res://entities/Units/USA/Infantry/" + unit_name + ".tscn"
	var unit_instance = load(path).instantiate()
	get_parent().add_child(unit_instance)
	unit_instance.global_transform.origin = spawn_point.global_transform.origin
	
	await get_tree().create_timer(5.0).timeout
	animPlayer.play("GarageDoorClose")
	await animPlayer.animation_finished

func start_production(unit_name: String, unit_icon: Texture2D):
	if production_queue.size() < MAX_QUEUE_SIZE:
		production_queue.append({"name": unit_name, "icon": unit_icon, "progress": 0.0})
		ui.add_to_production(self, unit_icon)
		if not is_producing:
			process_next_in_queue()

func process_next_in_queue():
	if production_queue.is_empty():
		is_producing = false
		return

	is_producing = true
	var current_product = production_queue[0]
	for i in range(100):
		await get_tree().create_timer(0.1).timeout
		if production_queue.is_empty() or production_queue[0] != current_product:
			is_producing = false
			if not production_queue.is_empty():
				process_next_in_queue()
			return
		current_product["progress"] = (i + 1) / 100.0
		ui.update_production_progress(self, current_product["progress"])

	spawn_unit(current_product["name"])
	production_queue.pop_front()
	ui.complete_production(self)

	process_next_in_queue()

func cancel_production(index: int):
	if index >= 0 and index < production_queue.size():
		production_queue.remove_at(index)
		if index == 0 and is_producing:
			is_producing = false
			process_next_in_queue()
		ui.update_production_queue()
