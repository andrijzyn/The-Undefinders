extends Node3D

# Імпортуємо необхідні компоненти
@onready var camera: Camera3D = $Camera3D
@onready var ui: userInterface = userInterface.new()
@onready var raycast_handler: RaycastHandler = RaycastHandler.new()
@onready var building_controller: BuildingController = BuildingController.new()

var selection_is_moved: bool = true
var minimap_is_moved: bool = true
var bottom_is_moved: bool = false
const MOVE_OFFSET: int = 133
const MOVE_TIME: float = 0.5
var selected_objects = {}
var buildings = {
	"GLA/garage/garage_imp": { "icon": preload("res://features/GUI/textures/barracks.png"), "cost": 200, "size": Vector2(2,2) },
	"factory": { "icon": preload("res://features/GUI/textures/factory.png"), "cost": 300, "size": Vector2(3,3) },
	"power_plant": { "icon": preload("res://features/GUI/textures/power_plant.png"), "cost": 150, "size": Vector2(2,2) }
}

var tween_cache: Dictionary = {}

# Параметри для побудови
var is_building: bool = false
var current_building: String = ""
var building_preview: Node3D = null

# Функція ініціалізації
func _ready():
	add_child(ui)  # Додаємо інтерфейс до основної сцени

# Функція початку побудови
func start_building(building_name: String):
	if is_building:
		return  # Якщо вже будується будівля, нічого не робимо
	
	is_building = true
	current_building = building_name
	building_preview = create_building_preview(building_name)
	get_tree().current_scene.add_child(building_preview)

# Функція для створення попереднього виду будівлі
func create_building_preview(building_name: String) -> Node3D:
	# Створення попереднього вигляду будівлі (фантомної)
	var building_scene = load("res://features/Buildings/" + building_name + ".tscn").instantiate()
	building_scene.position = camera.project_ray_origin(get_viewport().get_mouse_position())
	return building_scene

# Функція для скасування будівництва
func cancel_building():
	if building_preview:
		building_preview.queue_free()
	is_building = false
	current_building = ""
	building_preview = null

# Оновлення в процесі гри
func _process(delta: float) -> void:
	if is_building and building_preview:
		update_building_preview_position()

# Оновлення позиції попереднього виду будівлі
func update_building_preview_position():
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var space_state = camera.get_world_3d().direct_space_state
	var result = space_state.intersect_ray(query)
	
	if result:
		building_preview.position = result.position
	else:
		building_preview.position = to

# Оновлення вибору об'єктів (відповідає за вибір одиниць)
func update_selected_objects(selected_nodes: Array) -> void:
	ui.update_selected_objects(selected_nodes)

# Взаємодія з об'єктами через Raycasting
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if ui.is_mouse_over_ui():
			return

		var result = raycast_handler.getRaycastResult(camera)
		if result:
			if result.collider is Unit:  # Якщо це одиниця, додаємо до вибору
				var selected_units = []
				selected_units.append(result.collider)
				update_selected_objects(selected_units)
			elif result.collider is Building:  # Якщо це будівля
				print("Building selected: " + result.collider.name)

# Функція для завершення розміщення будівлі (після того, як мишка відпущена)
func finish_building():
	if building_preview and is_building:
		# Створюємо реальну будівлю на місці попереднього вигляду
		var building = load("res://entities/Buildings/ + current_building" + ".tscn").instantiate()
		building.position = building_preview.position
		get_tree().current_scene.add_child(building)
		building_preview.queue_free()  # Видаляємо попередній вигляд
		is_building = false
		current_building = ""
		building_preview = null

# Викликається після натискання миші на екран, коли потрібно завершити розміщення
func _on_mouse_release():
	finish_building()

# additional

func animate_element(element: Control, target_y: float):
	var tween: Tween
	if not element in tween_cache:
		tween = create_tween()
		tween_cache[element] = tween
	else:
		tween = tween_cache[element]
	tween.tween_property(element, "position:y", target_y, MOVE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
