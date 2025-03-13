class_name SelectionHandler

static func handleSingleSelection(oldSelections: Array[Node3D], newSelection: Node3D, caller: Node3D) -> Array[Node3D]:
	if newSelection and newSelection.is_in_group(Constants.selectable):
		if newSelection.get_multiplayer_authority() != caller.get_multiplayer_authority():
			return oldSelections
		if oldSelections.size() > 1:
			for select in oldSelections:
				if select:
					select.setSelected(false)
			oldSelections.clear()
			handleSingleSelection(oldSelections, newSelection, caller)
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

static func handleMultipleSelectionByShift(oldSelections: Array[Node3D], newSelection: Node3D, caller: Node3D) -> Array[Node3D]:
	if newSelection and newSelection.is_in_group(Constants.selectable):
		if newSelection.get_multiplayer_authority() == caller.get_multiplayer_authority():
			newSelection.setSelected(true)
			oldSelections.append(newSelection)
	return oldSelections
	
static func handleMultipleSelectionByDoubleClick(oldSelections: Array[Node3D], newSelection: Node3D, camera: MainCamera) -> Array[Node3D]:
	if newSelection and newSelection.is_in_group(Constants.selectable):
		var selectableNodes := camera.get_tree().get_nodes_in_group(Constants.selectable)
		var viewport_size: Vector2 = camera.get_viewport().size
		for node in selectableNodes:
			if node.get_class() == newSelection.get_class() and node.get_multiplayer_authority() == camera.get_multiplayer_authority():
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

static func handleSelectionBySelectionRect(camera: MainCamera):
	var space_state := camera.get_world_3d().direct_space_state
	var viewport := camera.get_viewport()
	var camera_3d := viewport.get_camera_3d()
	var rect := camera.selection_rect
	var top_left := rect.position
	var bottom_right := rect.end
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
		if obj.has_method("setSelected") and obj.get_multiplayer_authority() == camera.get_multiplayer_authority():
			obj.setSelected(true)
			camera.selected_nodes.append(obj)
