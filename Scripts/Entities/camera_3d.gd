extends Camera3D
class_name MainCamera

@export var SPEED := 10
@export var ZOOM_SPEED := 200
@export var EDGE_SCROLL_SPEED := 5
@export var EDGE_MARGIN := 50
@export var EDGE_SCROLL_ACCEL := 10  # Acceleration multiplier
@export var ROTATION_SPEED := 2.0

var selected_nodes: Array[Node3D] = []
const DRAG_THRESHOLD := 5

var dragging := false
var rotating := false
var selecting := false
var selection_start := Vector2()
var selection_rect := Rect2().abs()
var last_mouse_position := Vector2()

var selection_overlay: ColorRect

func _init() -> void:
	add_to_group(Constants.cameras)

func _ready():
	var canvas_layer = CanvasLayer.new()
	get_viewport().add_child.call_deferred(canvas_layer)

	var selection_container = Control.new()
	selection_container.name = "SelectionContainer"
	selection_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_layer.add_child(selection_container)

	selection_overlay = ColorRect.new()
	selection_overlay.color = Color(0, 0, 1, 0.3)
	selection_overlay.visible = false
	selection_container.add_child(selection_overlay)

func _process(delta:float) -> void:
	MouseChanger.mouseChange(self)
	cameraMovement(delta)
	handleEdgeScrolling(delta)
	handleRotation(delta)
	if selecting:
		updateSelectionRectangle()

func _input(event):
	# Pressed Event (Left-Selection | Middle - Rotation | Right - Dragging)
	if event is InputEventMouseButton:
		# Правая кнопка – перемещение (drag)
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			last_mouse_position = event.position

		# Средняя кнопка – вращение
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			rotating = event.pressed
			last_mouse_position = event.position

		# Левая кнопка – выделение
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Если зажата клавиша Shift или происходит двойной клик – выполняем мгновенное выделение
				if Input.is_action_pressed("shift"):
					var result = RaycastHandler.getRaycastResult(self)
					if result:
						selected_nodes = SelectionHandler.handleMultipleSelectionByShift(selected_nodes, result)
				elif event.double_click:
					var result = RaycastHandler.getRaycastResult(self)
					if result:
						selected_nodes = SelectionHandler.handleMultipleSelectionByDoubleClick(selected_nodes, result, self)
				else:
					# Иначе начинаем выделение рамкой
					selecting = true
					selection_start = event.position
					selection_overlay.position = selection_start
					selection_overlay.size = Vector2.ZERO
					selection_overlay.visible = true

			else:
				# Отпускание левой кнопки
				if selecting:
					selecting = false
					selection_overlay.visible = false
					# Если рамка достаточно большая – считаем, что это drag-выделение
					if event.position.distance_to(selection_start) > DRAG_THRESHOLD:
						SelectionHandler.handleSelectionBySelectionRect(self)
					else:
						# Если рамка почти не изменилась – это клик по объекту
						var result = RaycastHandler.getRaycastResult(self)
						if result:
							selected_nodes = SelectionHandler.handleSingleSelection(selected_nodes, result)


	# RMB Movement
	elif event is InputEventMouseMotion:
		if dragging:
			var delta_move = event.position - last_mouse_position
			var move_x = transform.basis.x * delta_move.x * 0.05  # Sensitivity
			var move_z = transform.basis.z * delta_move.y * 0.05

			move_x.y = 0
			move_z.y = 0

			var movement = move_x + move_z
			movement = movement.normalized() * movement.length()

			position += movement
			last_mouse_position = event.position
		elif rotating:
			var delta_rotate = (event.position - last_mouse_position) * 0.005
			rotate_y(-delta_rotate.x)
			last_mouse_position = event.position

func updateSelectionRectangle():
	var current_mouse_pos = get_viewport().get_mouse_position()
	selection_rect = Rect2(selection_start, current_mouse_pos - selection_start).abs()
	selection_overlay.position = selection_rect.position
	selection_overlay.size = selection_rect.size

func cameraMovement(delta:float)-> void:
	var directionZ := Input.get_axis("ui_down", "ui_up")
	var directionX := Input.get_axis("ui_right", "ui_left")

	var move_x = transform.basis.x * directionX * SPEED * delta
	var move_z = transform.basis.z * directionZ * SPEED * delta
	move_x.y = 0
	move_z.y = 0

	position -= move_x + move_z

	if position.y >= 10 and Input.is_action_just_pressed("MWU"):
		# -transform.basis.z дает локальный вектор "вперед" камеры
		var zoom_offset: Vector3 = -transform.basis.z * ZOOM_SPEED * delta
		print("Zoom offset: ", zoom_offset)
		position += zoom_offset
	elif Input.is_action_just_pressed("MWD") and position.y < 40:
		var zoom_offset: Vector3 = -transform.basis.z * -1 * ZOOM_SPEED * delta
		print("Zoom offset: ", zoom_offset)
		position += zoom_offset

func handleEdgeScrolling(delta: float) -> void:
	var viewport_size = get_viewport().size
	var mouse_pos = get_viewport().get_mouse_position()

	#Checking if the cursor is in the window
	if mouse_pos.x < 0 or mouse_pos.x > viewport_size.x or mouse_pos.y < 0 or mouse_pos.y > viewport_size.y:
		return

	var move_dir = Vector3.ZERO
	var speed_multiplier_x = 0.0
	var speed_multiplier_z = 0.0

	if mouse_pos.x <= EDGE_MARGIN:
		speed_multiplier_x = 1.0 - (mouse_pos.x / EDGE_MARGIN)
		move_dir.x += 1
	elif mouse_pos.x >= viewport_size.x - EDGE_MARGIN:
		speed_multiplier_x = 1.0 - ((viewport_size.x - mouse_pos.x) / EDGE_MARGIN)
		move_dir.x -= 1

	if mouse_pos.y <= EDGE_MARGIN:
		speed_multiplier_z = 1.0 - (mouse_pos.y / EDGE_MARGIN)
		move_dir.z += 1
	elif mouse_pos.y >= viewport_size.y - EDGE_MARGIN:
		speed_multiplier_z = 1.0 - ((viewport_size.y - mouse_pos.y) / EDGE_MARGIN)
		move_dir.z -= 1

	# Applying acceleration
	var total_speed_multiplier = max(speed_multiplier_x, speed_multiplier_z)
	if move_dir != Vector3.ZERO:
		var move_x = transform.basis.x * move_dir.x
		var move_z = transform.basis.z * move_dir.z
		move_x.y = 0
		move_z.y = 0
		position -= (move_x + move_z).normalized() * (EDGE_SCROLL_SPEED + total_speed_multiplier * EDGE_SCROLL_ACCEL) * delta

func handleRotation(delta: float) -> void:
	if Input.is_action_pressed("rotate_left"):
		rotate_y(ROTATION_SPEED * delta)
	elif Input.is_action_pressed("rotate_right"):
		rotate_y(-ROTATION_SPEED * delta)
