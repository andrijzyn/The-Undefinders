extends Control

@onready var selection_menu: PanelContainer = $SelectionMenu
@onready var action_menu: PanelContainer = $ActionMenu
@onready var minimap_panel: PanelContainer = $MinimapPanel
@onready var selection_panel: PanelContainer = $SelectionPanel
@onready var selection_container: VBoxContainer = $SelectionMenu/SelectionContainer
@onready var buildings_container: GridContainer = $ActionMenu/ActionContainer
@onready var button_left: Button = $ButtonLeft
@onready var button_right: Button = $ButtonRight
@onready var button_minimap: Button = $ButtonMap
@onready var button_selection: Button = $ButtonSelection
@onready var bottom_panel: Control = $BottomPanel

var selection_is_moved: bool = true
var minimap_is_moved: bool = true
var bottom_is_moved: bool = false
const MOVE_OFFSET: int = 133
const MOVE_TIME: float = 0.5
var selected_objects = {}
var buildings = {
	"garage_imp": { "icon": preload("res://Textures/barracks.png"), "cost": 200, "size": Vector2(2,2) },
	"factory": { "icon": preload("res://Textures/factory.png"), "cost": 300, "size": Vector2(3,3) },
	"power_plant": { "icon": preload("res://Textures/power_plant.png"), "cost": 150, "size": Vector2(2,2) }
}

func _ready():
	update_buildings_display()
	button_left.pressed.connect(_on_bottom_button_pressed)
	button_right.pressed.connect(_on_bottom_button_pressed)
	button_minimap.pressed.connect(_on_minimap_button_pressed)
	button_selection.pressed.connect(_on_selection_button_pressed)

func _on_selection_button_pressed():
	var target_y_panel = selection_panel.position.y - MOVE_OFFSET if !selection_is_moved else selection_panel.position.y + MOVE_OFFSET
	var target_y_buttons = button_selection.position.y - MOVE_OFFSET if !selection_is_moved else button_selection.position.y + MOVE_OFFSET
	var target_y_inner_panel = selection_menu.position.y - MOVE_OFFSET if !selection_is_moved else selection_menu.position.y + MOVE_OFFSET
	
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
	animate_element(bottom_panel, target_y_panel)
	animate_element(button_left, target_y_buttons)
	animate_element(button_right, target_y_buttons)
	animate_element(action_menu, target_y_inner_panel)

	bottom_is_moved = !bottom_is_moved

func animate_element(element: Control, target_y: float):
	var tween = create_tween()
	tween.tween_property(element, "position:y", target_y, MOVE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _process(delta:float) -> void:
	update_selection_display()

func update_selection_display():
	for child in selection_container.get_children():
		child.queue_free()
	
	for object_type in selected_objects.keys():
		var object_data = selected_objects[object_type]
		if object_data.count > 1:
			var group_icon = preload("res://scenes/gui/group_icon.tscn").instantiate()
			group_icon.get_node("TextureRect").texture = object_data.icon
			group_icon.get_node("Label").text = str(object_data.count)
			selection_container.add_child(group_icon)
		else:
			for i in range(object_data.count):
				var unit_icon = preload("res://scenes/gui/unit_icon.tscn").instantiate()
				unit_icon.get_node("TextureRect").texture = object_data.icon
				selection_container.add_child(unit_icon)

func update_buildings_display():
	for child in buildings_container.get_children():
		child.queue_free()
	
	if buildings_container is GridContainer:
		buildings_container.columns = 3
	
	for building in buildings.keys():
		var building_button = preload("res://scenes/gui/building_button.tscn").instantiate()
		var texture_rect = building_button.get_node_or_null("TextureRect")
		if texture_rect:
			texture_rect.texture = buildings[building].icon
		building_button.connect("pressed", Callable(self, "on_building_selected").bind(building))
		buildings_container.add_child(building_button)

func on_building_selected(building_name: String):
	print("Building selected:", building_name)
	var camera = get_tree().get_root().get_node("MainScene/Camera3D")
	if camera:
		camera.start_building_placement(building_name)

func update_selected_objects(selected_nodes: Array):
	selected_objects.clear()
	for node in selected_nodes:
		var object_type = node.name
		if object_type in selected_objects:
			selected_objects[object_type].count += 1
		else:
			var icon = null
			if node.has_method("get_icon"):
				icon = node.get_icon()
			selected_objects[object_type] = {
				"icon": icon if icon else preload("res://textures/default.png"),
				"count": 1
			}
	update_selection_display()
