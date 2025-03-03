extends Node

class_name MainCamera

var selected_nodes: Array[Node3D] = []
var selection_start: Vector2
var selection_rect: Rect2
var selecting: bool = false
var selection_overlay: ColorRect

func _ready() -> void:
	# Ініціалізація виділення
	selection_overlay = ColorRect.new()
	selection_overlay.color = Color(0, 0, 1, 0.3)
	selection_overlay.visible = false
	get_parent().add_child(selection_overlay)

func start_selection_box(event_position: Vector2) -> void:
	# Створення прямокутної рамки для виділення
	selecting = true
	selection_start = event_position
	selection_overlay.position = selection_start
	selection_overlay.size = Vector2.ZERO
	selection_overlay.visible = true

func update_selection_rectangle(event_position: Vector2) -> void:
	# Оновлення розміру рамки виділення
	selection_rect = Rect2(selection_start, event_position - selection_start).abs()
	selection_overlay.position = selection_rect.position
	selection_overlay.size = selection_rect.size

func handle_single_selection(oldSelections: Array[Node3D], newSelection: Node3D) -> Array[Node3D]:
	if oldSelections.size() > 1:
		for select in oldSelections:
			if select:
				select.setSelected(false)
		oldSelections.clear()
		handle_single_selection(oldSelections, newSelection)
	if newSelection and newSelection.is_in_group(Constants.selectable):
		if oldSelections.size() > 0 and oldSelections[0] and oldSelections[0] != newSelection:
			oldSelections[0].setSelected(false)
		oldSelections.clear()
		newSelection.setSelected(true)
		oldSelections.append(newSelection)
		return oldSelections
	elif oldSelections.size() > 0 and oldSelections[0]:
		oldSelections[0].setSelected(false)
		oldSelections.clear()
		return oldSelections
	oldSelections.clear()
	return oldSelections

func handle_multi_selection(camera: Camera3D):
	var space_state: PhysicsDirectSpaceState3D
	var viewport: Viewport
	var camera_3d: Camera3D
	var rect: Rect2
	var top_left: Vector2
	var bottom_right: Vector2
	var max_rays = 10000
	var selection_width = bottom_right.x - top_left.x
	var selection_height = bottom_right.y - top_left.y

	var grid_size_x = int(sqrt(max_rays * (selection_width / selection_height)))
	var grid_size_y = int(max_rays / grid_size_x)

	grid_size_x = max(grid_size_x, 3)
	grid_size_y = max(grid_size_y, 3)

	for node in camera.selected_nodes:
		if node.has_method("setSelected"):
			node.setSelected(false)
	camera.selected_nodes.clear()

	var selected_objects := {}
	for i in range(grid_size_x):
		for j in range(grid_size_y):
			var t_x = float(i) / (grid_size_x - 1)
			var t_y = float(j) / (grid_size_y - 1)
			var screen_pos = top_left.lerp(bottom_right, t_x)
			var screen_pos_y = top_left.lerp(bottom_right, t_y)

			screen_pos = Vector2(screen_pos.x, screen_pos_y.y)

			var from := camera_3d.project_ray_origin(screen_pos)
			var to := from + camera_3d.project_ray_normal(screen_pos) * 1000
			var query := PhysicsRayQueryParameters3D.create(from, to)
			var result := space_state.intersect_ray(query)

			if result and result.collider:
				selected_objects[result.collider] = true

	for obj in selected_objects.keys():
		if obj.has_method("setSelected"):
			obj.setSelected(true)
			camera.selected_nodes.append(obj)


func finalize_selection() -> void:
	# Завершення вибору
	selecting = false
	selection_overlay.visible = false


# Non-used


static func handleMultipleSelectionByShift(oldSelections: Array[Node3D], newSelection: Node3D) -> Array[Node3D]:
	if newSelection and newSelection.is_in_group(Constants.selectable):
		newSelection.setSelected(true)
		oldSelections.append(newSelection)
	return oldSelections
	
static func handleMultipleSelectionByDoubleClick(oldSelections: Array[Node3D], newSelection: Node3D, camera: MainCamera) -> Array[Node3D]:
	if newSelection and newSelection.is_in_group(Constants.selectable):
		var selectableNodes := camera.get_tree().get_nodes_in_group(Constants.selectable)
		var viewport_size: Vector2 = camera.get_viewport().size
		for node in selectableNodes:
			if node.get_class() == newSelection.get_class():
				var world_pos: Vector3 = node.global_transform.origin
				var to_object: Vector3 = world_pos - camera.global_transform.origin
				var camera_forward: Vector3 = -camera.global_transform.basis.z
				var z_depth: float = to_object.dot(camera_forward)
				
				if z_depth > 0:
					var projected: Vector3 = camera.project_position(Vector2(world_pos.x, world_pos.y), z_depth)
					var screen_pos := Vector2(projected.x, projected.y)
					
					if screen_pos.x >= 0 and screen_pos.x <= viewport_size.x and screen_pos.y >= 0 and screen_pos.y <= viewport_size.y:
						node.setSelected(true)
						oldSelections.append(node)
		return oldSelections
	return oldSelections
