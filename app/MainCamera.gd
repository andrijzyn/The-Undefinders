extends Camera3D
class_name MainCamera

@export var CAMERA_SPEED_MULTPLIER := 0.05
@export var CAMERA_ROTATION_SPEED := 1
@export var ROTATION_SPEED_MULTIPLIER = 0.005
@export var ZOOM_SPEED_MULTPLIER := 200
@export var EDGE_MARGIN := 120
@export var EDGE_SCROLL_SPEED := 20

var selected_nodes: Array[Node3D] = []
const DRAG_THRESHOLD := 5
var ghost_shader = preload("res://shaders/ghost_shader.gdshader")

var dragging := false
var rotating := false
var selecting := false
var selection_start := Vector2()
var selection_rect := Rect2().abs()
var last_mouse_position := Vector2()
var phantom_building: Node3D = null
var rotating_building: bool = false
var can_place: bool = true
var overlapping_bodies_count: int = 0

var selection_overlay: ColorRect

func _init() -> void:
	add_to_group(Constants.cameras)

func _ready():
	# Create selection overlay UI
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
	handleEdgeScrolling(delta)
	cameraZoom(delta)
	HoverHandler.handleHover(self)

	if selecting:
		updateSelectionRectangle()

	# Move phantom building along the ground
	if phantom_building:
		if not rotating_building:
			var mouse_pos = get_viewport().get_mouse_position()
			var ray_origin = project_ray_origin(mouse_pos)
			var ray_dir = project_ray_normal(mouse_pos)
			var ground_plane = Plane(Vector3.UP, 0)
			var intersection = ray_plane_intersection(ray_origin, ray_dir, ground_plane)
			if intersection:
				intersection.y = 0
				phantom_building.global_transform.origin = intersection

func _input(event):
	# Handle mouse button events
	if event is InputEventMouseButton:
		if phantom_building:
			# Middle mouse button rotates phantom building
			if event.button_index == MOUSE_BUTTON_MIDDLE:
				if event.pressed:
					rotating_building = true
					last_mouse_position = event.position
				else:
					rotating_building = false
				return
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if selected_nodes.size() == 1 and selected_nodes[0] is ProductionBuilding:
				var ground_pos = get_ground_position(event.position)
				selected_nodes[0].set_rally_point(ground_pos)
		# Right mouse button - drag movement
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if phantom_building:
				cancel_building_placement()
				return
			dragging = event.pressed
			last_mouse_position = event.position

		# Middle mouse button - camera rotation
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			rotating = event.pressed
			last_mouse_position = event.position

		# Left mouse button - selection
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if is_mouse_over_ui():
				return # Block input if mouse is over UI
			if event.pressed:
				if phantom_building:
					finish_building_placement()
					return
				# Shift + click selects multiple units
				if Input.is_action_pressed("MULTI_SELECT"):
					var result = RaycastHandler.getRaycastResult(self)
					if result:
						selected_nodes = SelectionHandler.handleMultipleSelectionByShift(selected_nodes, result)
				elif event.double_click:
					# Double-click selects multiple objects of the same type
					var result = RaycastHandler.getRaycastResult(self)
					if result:
						selected_nodes = SelectionHandler.handleMultipleSelectionByDoubleClick(selected_nodes, result, self)
				else:
					# Start selection box
					selecting = true
					selection_start = event.position
					selection_overlay.position = selection_start
					selection_overlay.size = Vector2.ZERO
					selection_overlay.visible = true
			else:
				# Left button release
				if selecting:
					selecting = false
					selection_overlay.visible = false
					if event.position.distance_to(selection_start) > DRAG_THRESHOLD:
						SelectionHandler.handleSelectionBySelectionRect(self)
					else:
						var result = RaycastHandler.getRaycastResult(self)
						if result:
							selected_nodes = SelectionHandler.handleSingleSelection(selected_nodes, result)
					var ui = get_tree().get_root().get_node("MainScene/RTS_UI")
					if ui:
						ui.update_selected_objects(selected_nodes)

	# Handle mouse movement (drag and rotate)
	elif event is InputEventMouseMotion:
		if phantom_building and rotating_building:
			if is_mouse_over_ui():
				return # Block input if over UI
			var delta_angle = event.position.x - last_mouse_position.x
			phantom_building.rotate_y(-delta_angle * ROTATION_SPEED_MULTIPLIER)
			last_mouse_position = event.position
		if dragging:
			var delta_move = event.position - last_mouse_position
			var move_x = transform.basis.x * delta_move.x * CAMERA_SPEED_MULTPLIER
			var move_z = transform.basis.z * delta_move.y * CAMERA_SPEED_MULTPLIER
			move_x.y = 0
			move_z.y = 0
			position += move_x + move_z
			last_mouse_position = event.position
		elif rotating:
			var delta_rotate = (event.position - last_mouse_position) * ROTATION_SPEED_MULTIPLIER
			rotate_y(-delta_rotate.x)
			last_mouse_position = event.position

func get_ground_position(mouse_pos: Vector2) -> Vector3:
	var ray_origin = project_ray_origin(mouse_pos)
	var ray_dir = project_ray_normal(mouse_pos)
	var ground_plane = Plane(Vector3.UP, 0)
	var intersection = ray_plane_intersection(ray_origin, ray_dir, ground_plane)
	if intersection:
		intersection.y = 0
	return intersection

func updateSelectionRectangle():
	var current_mouse_pos = get_viewport().get_mouse_position()
	selection_rect = Rect2(selection_start, current_mouse_pos - selection_start).abs()
	selection_overlay.position = selection_rect.position
	selection_overlay.size = selection_rect.size

func cameraZoom(delta:float)-> void:
	if position.y >= 10 and Input.is_action_just_pressed("ZOOM_IN"):
		# -transform.basis.z дает локальный вектор "вперед" камеры
		var zoom_offset: Vector3 = -transform.basis.z * ZOOM_SPEED_MULTPLIER * delta
		print("Zoom offset: ", zoom_offset)
		position += zoom_offset
	elif Input.is_action_just_pressed("ZOOM_OUT") and position.y < 40:
		var zoom_offset: Vector3 = -transform.basis.z * -1 * ZOOM_SPEED_MULTPLIER * delta
		print("Zoom offset: ", zoom_offset)
		position += zoom_offset

func handleEdgeScrolling(delta: float) -> void:
	if is_mouse_over_ui():
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
	var speed_x = calculate_speed_multiplier.call(mouse_pos.x, EDGE_MARGIN, viewport_size.x)
	var speed_z = calculate_speed_multiplier.call(mouse_pos.y, EDGE_MARGIN, viewport_size.y)

	# Корректное направление движения
	move_dir += transform.basis.x * speed_x
	move_dir += transform.basis.z * speed_z

	# Убираем перемещение по Y
	move_dir.y = 0

	# Применяем множитель скорости (от 0 до 100%)
	if move_dir.length() > 0:
		position += move_dir.normalized() * EDGE_SCROLL_SPEED * abs(speed_x + speed_z) * delta

func start_building_placement(building_name: String) -> void:
	# If there is an old phantom object, delete and restore the materials
	if phantom_building:
		fix_building_transparency(phantom_building)
		phantom_building.queue_free()
		phantom_building = null
	
	# Load new phantom object
	var path = "res://entities/Buildings/" + building_name + ".tscn"
	if ResourceLoader.exists(path):
		var building_scene = load(path).instantiate()
		
		duplicate_meshes(building_scene)
	
		phantom_building = building_scene
		phantom_building.rotation = Vector3(phantom_building.rotation.x, 0.0, phantom_building.rotation.z)
		phantom_building.scale = Vector3(0.5, 0.5, 0.5)
	
		apply_ghost_shader(phantom_building)
		disable_colliders(phantom_building)
		setup_phantom_area(phantom_building)
		get_tree().get_current_scene().add_child(phantom_building)
	else:
		print("Error: Scene not found at path:", path)

# Duplicate the mesh so that its materials are not shared
func duplicate_meshes(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		node.mesh = node.mesh.duplicate()
	for child in node.get_children():
		duplicate_meshes(child)

func disable_colliders(node: Node) -> void:
	if node is CollisionShape3D:
		node.disabled = true
	for child in node.get_children():
		disable_colliders(child)

func enable_colliders(node: Node) -> void:
	if node is CollisionShape3D:
		node.disabled = false
	for child in node.get_children():
		enable_colliders(child)

func find_first_collision_shape(node: Node) -> CollisionShape3D:
	if node is CollisionShape3D:
		return node
	for child in node.get_children():
		var collider = find_first_collision_shape(child)
		if collider:
			return collider
	return null

# Add Area3D for intersection detection
func setup_phantom_area(node: Node) -> void:
	var area = Area3D.new()
	var new_collision_shape = CollisionShape3D.new()
	
	var original_collider = find_first_collision_shape(node)
	new_collision_shape.shape = original_collider.shape.duplicate()
	new_collision_shape.position = original_collider.position
	new_collision_shape.rotation = original_collider.rotation
	
	area.add_child(new_collision_shape)
	area.monitoring = true
	area.monitorable = true
	area.collision_layer = 2
	area.collision_mask = 2
	node.add_child(area)
	area.connect("body_entered", Callable(self,"_on_phantom_area_body_entered"))
	area.connect("body_exited", Callable(self, "_on_phantom_area_body_exited"))

func _on_phantom_area_body_entered(body: Node) -> void:
	overlapping_bodies_count += 1
	set_phantom_collision_state(true)

func _on_phantom_area_body_exited(body: Node) -> void:
	overlapping_bodies_count -= 1
	if overlapping_bodies_count <= 0:
		overlapping_bodies_count = 0
		set_phantom_collision_state(false)

func set_phantom_collision_state(is_colliding: bool) -> void:
	can_place = not is_colliding
	update_phantom_material_color(phantom_building, is_colliding)

func update_phantom_material_color(node: Node, is_colliding: bool) -> void:
	if node is MeshInstance3D and node.mesh:
		for i in range(node.mesh.get_surface_count()):
			var mat = node.mesh.surface_get_material(i)
			if mat and (mat is ShaderMaterial):
				if is_colliding:
					mat.set_shader_parameter("albedo_color", Color(1, 0, 0))
				else:
					var orig_mat = mat.get_shader_parameter("original_material")
					if orig_mat and orig_mat is StandardMaterial3D:
						mat.set_shader_parameter("albedo_color", orig_mat.albedo_color)
	if node:
		for child in node.get_children():
				update_phantom_material_color(child, is_colliding)

func apply_ghost_shader(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		var surface_count = node.mesh.get_surface_count()
		for i in range(surface_count):
			var orig_mat = node.mesh.surface_get_material(i)
			if orig_mat and not (orig_mat is ShaderMaterial):
				var ghost_material := ShaderMaterial.new()
				ghost_material.shader = ghost_shader
				ghost_material.set_shader_parameter("ghost_alpha", 0.5)
				ghost_material.set_shader_parameter("original_material", orig_mat)

				if orig_mat is StandardMaterial3D:
					ghost_material.set_shader_parameter("albedo_texture", orig_mat.albedo_texture)
					ghost_material.set_shader_parameter("albedo_color", orig_mat.albedo_color)

				node.mesh.surface_set_material(i, ghost_material)

	for child in node.get_children():
		apply_ghost_shader(child)

func fix_building_transparency(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		var surface_count = node.mesh.get_surface_count()
		for i in range(surface_count):
			var orig_mat = node.mesh.surface_get_material(i)
			if orig_mat and orig_mat is ShaderMaterial:
				var prev_mat = orig_mat.get_shader_parameter("original_material")
				if prev_mat:
					node.mesh.surface_set_material(i, prev_mat)

	for child in node.get_children():
		fix_building_transparency(child)

func cancel_building_placement() -> void:
	if phantom_building:
		fix_building_transparency(phantom_building)
		phantom_building.queue_free()
		phantom_building = null

func finish_building_placement() -> void:
	if phantom_building and can_place:
		for child in phantom_building.get_children():
			if child is Area3D:
				child.queue_free()
		enable_colliders(phantom_building)
		fix_building_transparency(phantom_building)
		phantom_building = null

func ray_plane_intersection(origin: Vector3, dir: Vector3, plane: Plane) -> Vector3:
	var denom = plane.normal.dot(dir)
	if abs(denom) < 0.001:
		return Vector3.ZERO
	var t = -(plane.normal.dot(origin) + plane.d) / denom
	if t < 0:
		return Vector3.ZERO
	return origin + dir * t

func is_mouse_over_ui() -> bool:
	var ui = get_tree().get_root().get_node("MainScene/RTS_UI")
	if not ui:
		return false
	
	var mouse_pos = get_viewport().get_mouse_position()
	
	for node in ui.find_children("", "Control", true):
		if node.visible and node.get_global_rect().has_point(mouse_pos):
			return true
	
	return false
