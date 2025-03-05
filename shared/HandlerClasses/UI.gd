extends Control

@onready var selection_menu: PanelContainer = $SelectionMenu
@onready var action_menu: PanelContainer = $ActionMenu
@onready var queue_menu: PanelContainer = $QueueMenu
@onready var minimap_panel: PanelContainer = $MinimapPanel
@onready var selection_panel: PanelContainer = $SelectionPanel
@onready var selection_container: GridContainer = $SelectionMenu/SelectionContainer
@onready var action_container: GridContainer = $ActionMenu/ActionContainer
@onready var queue_container: GridContainer = $QueueMenu/QueueContainer
@onready var button_left: Button = $ButtonLeft
@onready var button_right: Button = $ButtonRight
@onready var button_minimap: Button = $ButtonMap
@onready var button_selection: Button = $ButtonSelection
@onready var bottom_panel: Control = $BottomPanel
@onready var button_left_background: Control = $ButtonRightPanel
@onready var button_right_background: Control = $ButtonLeftPanel

var selection_is_moved: bool = true
var minimap_is_moved: bool = true
var bottom_is_moved: bool = false
const MOVE_OFFSET: int = 133
const MOVE_TIME: float = 0.5
var production_queues = {}
var selected_objects = {}
var buildings = {
	"GLA/garage/garage_imp": { "icon": preload("res://features/GUI/textures/barracks.png"), "cost": 200, "size": Vector2(2,2) },
	"factory": { "icon": preload("res://features/GUI/textures/factory.png"), "cost": 300, "size": Vector2(3,3) },
	"power_plant": { "icon": preload("res://features/GUI/textures/power_plant.png"), "cost": 150, "size": Vector2(2,2) }
}

func _ready():
	update_action_display()
	button_left.pressed.connect(_on_bottom_button_pressed)
	button_right.pressed.connect(_on_bottom_button_pressed)
	button_minimap.pressed.connect(_on_minimap_button_pressed)
	button_selection.pressed.connect(_on_selection_button_pressed)

func _on_selection_button_pressed():
	if selection_container.get_child_count() > 0:
		return

	var target_y_panel = selection_panel.position.y - 50 if !selection_is_moved else selection_panel.position.y + 50
	var target_y_buttons = button_selection.position.y - 50 if !selection_is_moved else button_selection.position.y + 50
	var target_y_inner_panel = selection_menu.position.y - 50 if !selection_is_moved else selection_menu.position.y + 50
	
	animate_element(selection_panel, target_y_panel)
	animate_element(button_selection, target_y_buttons)
	animate_element(selection_menu, target_y_inner_panel)
	
	selection_is_moved = !selection_is_moved

func _on_minimap_button_pressed():
	var target_y_panel = minimap_panel.position.y - MOVE_OFFSET if !minimap_is_moved else minimap_panel.position.y + MOVE_OFFSET
	var target_y_buttons = button_minimap.position.y - MOVE_OFFSET if !minimap_is_moved else button_minimap.position.y + MOVE_OFFSET
	
	animate_element(minimap_panel, target_y_panel)
	animate_element(button_minimap, target_y_buttons)
	
	minimap_is_moved = !minimap_is_moved

func _on_bottom_button_pressed():
	var target_y_panel = bottom_panel.position.y - MOVE_OFFSET if !bottom_is_moved else bottom_panel.position.y + MOVE_OFFSET
	var target_y_buttons = button_left.position.y - MOVE_OFFSET if !bottom_is_moved else button_left.position.y + MOVE_OFFSET
	var target_y_inner_panel = action_menu.position.y - MOVE_OFFSET if !bottom_is_moved else action_menu.position.y + MOVE_OFFSET
	var target_y_button_background = button_left_background.position.y - MOVE_OFFSET if !bottom_is_moved else button_left_background.position.y + MOVE_OFFSET
	
	animate_element(bottom_panel, target_y_panel)
	animate_element(button_left, target_y_buttons)
	animate_element(button_right, target_y_buttons)
	animate_element(action_menu, target_y_inner_panel)
	animate_element(queue_menu, target_y_inner_panel)
	animate_element(button_left_background, target_y_button_background)
	animate_element(button_right_background, target_y_button_background)

	bottom_is_moved = !bottom_is_moved

func animate_element(element: Control, target_y: float):
	var tween = create_tween()
	tween.tween_property(element, "position:y", target_y, MOVE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func adjust_selection_panel():
	if !selection_is_moved:
		if selection_container.get_child_count() == 0:
			selection_menu.size.y = 40
		await get_tree().process_frame

		var menu_height = selection_menu.size.y
		var panel_target_y = selection_menu.position.y + menu_height + 45 - selection_panel.size.y
		
		selection_panel.position.y = panel_target_y
		button_selection.position.y = selection_panel.position.y + selection_panel.size.y - button_selection.size.y - 10

func _process(_delta:float) -> void:
	adjust_selection_panel()
	update_selection_display()

func update_selection_display():
	if selection_is_moved:
		return

	for child in selection_container.get_children():
		child.queue_free()

	selection_container.columns = 4
	var total_elements = 0

	for object_type in selected_objects.keys():
		var object_data = selected_objects[object_type]
		if object_data.count > 1:
			var group_icon = preload("res://shared/HUD/group_icon.tscn").instantiate()
			group_icon.get_node("TextureRect").texture = object_data.icon
			group_icon.get_node("Label").text = str(object_data.count)
			selection_container.add_child(group_icon)
			total_elements += 1
		else:
			for i in range(object_data.count):
				var unit_icon = preload("res://shared/HUD/unit_icon.tscn").instantiate()
				unit_icon.get_node("TextureRect").texture = object_data.icon
				selection_container.add_child(unit_icon)
				total_elements += 1

	var num_rows = ceil(float(total_elements) / selection_container.columns)
	var row_height = 32 + 4
	var padding_bottom = 10
	var new_height = (num_rows * row_height) + padding_bottom + 5

	var min_height = 40
	var max_height = 300
	new_height = clamp(new_height, min_height, max_height)

	selection_menu.custom_minimum_size.y = new_height

func update_action_display():
	for child in action_container.get_children():
		child.queue_free()

	if action_container is GridContainer:
		action_container.columns = 3

	var available_items = {}
	var is_builder = false
	var is_selected = false

	for obj in selected_objects.keys():
			if obj.has_method("get_available_items"):
				is_selected = true
				available_items = obj.get_available_items()
				is_builder = obj.is_builder
				break

	if is_selected:
		for item in available_items.keys():
			var button = preload("res://shared/HUD/action_button.tscn").instantiate()
			var texture_rect = button.get_node_or_null("TextureRect")
			if texture_rect:
				texture_rect.texture = available_items[item].icon
			var callback = "on_building_selected" if is_builder else "on_unit_selected"
			button.connect("pressed", Callable(self, callback).bind(item))
			action_container.add_child(button)
	else:
		for building in buildings.keys():
			var building_button = preload("res://shared/HUD/action_button.tscn").instantiate()
			var texture_rect = building_button.get_node_or_null("TextureRect")
			if texture_rect:
				texture_rect.texture = buildings[building].icon
			building_button.connect("pressed", Callable(self, "on_building_selected").bind(building))
			action_container.add_child(building_button)

func on_building_selected(building_name: String):
	print("Building selected:", building_name)
	var camera = get_tree().get_root().get_node("MainScene/Camera3D")
	if camera:
		camera.start_building_placement(building_name)

func on_unit_selected(unit_name: String):
	print("Unit selected:", unit_name)

	for obj in selected_objects.keys():
		if obj is GarageImp:
			if production_queues.has(obj) and production_queues[obj].queue.size() >= 10:
				print("Production queue full")
				return
			obj.start_production(unit_name, obj.available_items[unit_name].icon)
			break

func update_selected_objects(selected_nodes: Array):
	selected_objects.clear()

	for node in selected_nodes:
		var icon = preload("res://features/GUI/textures/default.png")
		if node.get("icon") != null:
			icon = node.icon

		var object_key = node
		if object_key in selected_objects:
			selected_objects[object_key].count += 1
		else:
			selected_objects[object_key] = {
				"icon": icon,
				"count": 1
			}

	update_action_display()
	update_selection_display()

func update_production_queue():
	var existing_producers = {}
	for child in queue_container.get_children():
		if child.has_meta("producer"):
			var producer = child.get_meta("producer")
			if not production_queues.has(producer) or production_queues[producer].queue.is_empty():
				child.queue_free()
			else:
				existing_producers[producer] = child
		else:
			child.queue_free()

	var row_index = 0
	var col_index = 0
	for producer in production_queues.keys():
		var queue_data = production_queues[producer]

		if queue_data.queue.is_empty():
			if producer in existing_producers:
				existing_producers[producer].queue_free()
			continue

		var producer_ui
		if producer in existing_producers:
			producer_ui = existing_producers[producer]
		else:
			producer_ui = preload("res://shared/HUD/queue_producer.tscn").instantiate()
			producer_ui.set_meta("producer", producer)
			queue_container.add_child(producer_ui)

		producer_ui.get_node("TextureRect").texture = producer.icon
		var product_grid = producer_ui.get_node("GridContainer")

		var existing_products = {}
		for child in product_grid.get_children():
			var icon = child.get_node("TextureRect").texture
			existing_products[icon] = child

		for product_data in queue_data.queue:
			var product_ui
			if existing_products.has(product_data.icon):
				product_ui = existing_products[product_data.icon]
				product_ui.get_node("TextureRect/Label").text = str(product_data.count)
				product_ui.get_node("ProgressBar").value = product_data.progress * 100
				existing_products.erase(product_data.icon)
			else:
				product_ui = preload("res://shared/HUD/queue_product.tscn").instantiate()
				product_ui.get_node("TextureRect").texture = product_data.icon
				product_ui.get_node("TextureRect/Label").text = str(product_data.count)
				product_ui.get_node("ProgressBar").value = product_data.progress * 100
				product_grid.add_child(product_ui)
				product_ui.connect("pressed", Callable(self, "_on_product_clicked").bind(producer, product_data))
		for leftover in existing_products.values():
			leftover.queue_free()

		producer_ui.update_grid_layout()
		producer_ui.position = Vector2(col_index * 225, row_index * 50)
		col_index += 1
		if col_index >= 2:
			col_index = 0
			row_index += 1

func find_existing_product_ui(grid, product_data):
	for child in grid.get_children():
		if child.get_node("TextureRect").texture == product_data.icon:
			return child
	return null

func _on_product_clicked(producer, product_data):
	if production_queues.has(producer):
		var queue = production_queues[producer].queue
		for i in range(queue.size()):
			if queue[i].icon == product_data.icon:
				if queue[i].count > 1:
					queue[i].count -= 1
				else:
					queue.remove_at(i)
				producer.cancel_production(i)
				break

		if queue.is_empty():
			production_queues.erase(producer)

	update_production_queue()

func add_to_production(producer, product_icon):
	if not production_queues.has(producer):
		production_queues[producer] = { "queue": [] }

	var queue = production_queues[producer].queue
	if queue.size() > 0 and queue[-1].icon == product_icon:
		queue[-1].count += 1
	else:
		queue.append({ "icon": product_icon, "count": 1, "progress": 0.0 })  

	update_production_queue()

func update_production_progress(producer, progress):
	if production_queues.has(producer) and production_queues[producer].queue.size() > 0:
		production_queues[producer].queue[0].progress = progress
		update_production_queue()

func complete_production(producer):
	if production_queues.has(producer):
		var queue = production_queues[producer].queue
		if queue.size() > 0:
			if queue[0].count > 1:
				queue[0].count -= 1
			else:
				queue.pop_front()

		if queue.is_empty():
			production_queues.erase(producer)

	update_production_queue()
