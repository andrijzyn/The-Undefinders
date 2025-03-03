extends Node

class_name CameraController

@export var camera_speed_multiplier := 0.05
@export var camera_rotation_speed := 1
@export var zoom_speed_multiplier := 200
@export var edge_margin := 120
@export var edge_scroll_speed := 20

var last_mouse_position := Vector2()
var rotating := false
var dragging := false

# Додано посилання на камеру
var camera: Camera3D

func _ready() -> void:
	# Ініціалізація камери
	camera = get_parent().get_node("MainCamera") as Camera3D # Припускаємо, що ваша камера знаходиться в батьківському контейнері

func _process(delta: float) -> void:
	handle_edge_scrolling(delta)
	handle_camera_zoom(delta)
	# handle_mouse_motion(delta)

func handle_edge_scrolling(delta: float) -> void:
	if userInterface.is_mouse_over_ui():
		return  # Блокировать ввод, если курсор над UI

	var viewport_size = get_viewport().size
	var mouse_pos = get_viewport().get_mouse_position()

	# Проверяем, что курсор в пределах окна
	if mouse_pos.x < 0 or mouse_pos.x > viewport_size.x or mouse_pos.y < 0 or mouse_pos.y > viewport_size.y:
		return

	var move_dir = Vector3.ZERO

	# Функция для расчёта множителя скорости
	var calculate_speed_multiplier = func(pos: float, margin: float, max_size: float) -> float:
		if pos <= margin:
			return -(1.0 - (pos / margin))  # Левый/верхний край (отрицательное значение)
		elif pos >= max_size - margin:
			return 1.0 - ((max_size - pos) / margin)  # Правый/нижний край (положительное значение)
		return 0.0

	# Рассчитываем множитель скорости
	var speed_x = calculate_speed_multiplier.call(mouse_pos.x, edge_margin, viewport_size.x)
	var speed_z = calculate_speed_multiplier.call(mouse_pos.y, edge_margin, viewport_size.y)

	# Корректное направление движения
	move_dir += camera.transform.basis.x * speed_x
	move_dir += camera.transform.basis.z * speed_z

	# Убираем перемещение по Y
	move_dir.y = 0

	# Применяем множитель скорости (от 0 до 100%)
	if move_dir.length() > 0:
		camera.position += move_dir.normalized() * edge_scroll_speed * abs(speed_x + speed_z) * delta

func handle_camera_zoom(delta: float) -> void:
	if camera.position.y >= 10 and Input.is_action_just_pressed("ZOOM_IN"):
		# -camera.transform.basis.z дает локальный вектор "вперед" камеры
		var zoom_offset: Vector3 = -camera.transform.basis.z * zoom_speed_multiplier * delta
		print("Zoom offset: ", zoom_offset)
		camera.position += zoom_offset
	elif Input.is_action_just_pressed("ZOOM_OUT") and camera.position.y < 40:
		var zoom_offset: Vector3 = -camera.transform.basis.z * -1 * zoom_speed_multiplier * delta
		print("Zoom offset: ", zoom_offset)
		camera.position += zoom_offset

func start_drag(event_position: Vector2) -> void:
	# Початок перетягування
	last_mouse_position = event_position
	dragging = true

func stop_drag() -> void:
	# Завершення перетягування
	dragging = false

func start_rotate(event_position: Vector2) -> void:
	# Початок обертання камери
	last_mouse_position = event_position
	rotating = true

func stop_rotate() -> void:
	# Завершення обертання
	rotating = false
