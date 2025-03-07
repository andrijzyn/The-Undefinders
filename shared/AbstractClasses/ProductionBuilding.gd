extends Node3D
class_name ProductionBuilding

var available_items: Dictionary = {}
var ui
var icon: Texture2D
var is_builder: bool = false
var isSelected: bool = false
var is_producing: bool = false
var production_queue: Array = []
const MAX_QUEUE_SIZE: int = 10

func _init():
	add_to_group(Constants.selectable)
	add_to_group(Constants.mouseChanger)

func _ready():
	ui = get_tree().get_root().get_node("MainScene/RTS_UI")

func setSelected(val: bool):
	isSelected = val

func get_available_items() -> Dictionary:
	return available_items 

func on_production_complete(item_name: String):
	pass

func start_production(item_name: String, item_icon: Texture2D):
	if production_queue.size() < MAX_QUEUE_SIZE:
		var production_time = available_items[item_name].get("time", 5.0)
		production_queue.append({
			"name": item_name,
			"icon": item_icon,
			"progress": 0.0,
			"production_time": production_time
		})
		ui.add_to_production(self, item_icon)
		if not is_producing:
			process_next_in_queue()

func process_next_in_queue():
	if production_queue.is_empty():
		is_producing = false
		return

	is_producing = true
	var current_product = production_queue[0]
	var progress = current_product.get("progress", 0.0)
	var production_time = current_product["production_time"]
	for i in range(int(progress * 100), 100):
		await get_tree().create_timer(production_time / 100.0).timeout
		if production_queue.is_empty() or production_queue[0] != current_product:
			is_producing = false
			if not production_queue.is_empty():
				process_next_in_queue()
			return
		current_product["progress"] = (i + 1) / 100.0
		ui.update_production_progress(self, current_product["progress"])

	on_production_complete(current_product["name"])
	production_queue.pop_front()
	ui.complete_production(self)

	process_next_in_queue()

func cancel_production(index: int):
	if index >= 0 and index < production_queue.size():
		var progress_to_transfer = 0.0
		if index == 0 and is_producing and production_queue.size() > 1:
			if production_queue[1]["name"] == production_queue[0]["name"]:
				progress_to_transfer = production_queue[0]["progress"]
		production_queue.remove_at(index)

		if progress_to_transfer > 0.0 and not production_queue.is_empty():
			production_queue[0]["progress"] = progress_to_transfer
		if index == 0 and is_producing:
			is_producing = false
			process_next_in_queue()

		ui.update_production_queue()
