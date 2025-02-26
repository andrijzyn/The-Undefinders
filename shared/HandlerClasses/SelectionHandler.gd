class_name SelectionHandler

static func handleSingleSelection (oldSelections: Array[Node3D], newSelection: Node3D) -> Array[Node3D]:
	if oldSelections.size() > 1:
		for select in oldSelections:
			if select:
				select.setSelected(false)
		oldSelections.clear()
		handleSingleSelection(oldSelections, newSelection)
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

static func handleMultipleSelectionByShift(oldSelections:Array[Node3D], 
newSelection:Node3D) -> Array[Node3D]:
	if newSelection and newSelection.is_in_group(Constants.selectable):
		newSelection.setSelected(true)
		oldSelections.append(newSelection)
	return oldSelections
	
static func handleMultipleSelectionByDoubleClick(oldSelections:Array[Node3D], 
newSelection:Node3D, camera: MainCamera) -> Array[Node3D]:
	if newSelection and newSelection.is_in_group(Constants.selectable):
		var selectableNodes := camera.get_tree().get_nodes_in_group(Constants.selectable)
		var viewport_size: Vector2 = camera.get_viewport().size
		for node in selectableNodes:
			if node.get_class() == newSelection.get_class():
				var world_pos: Vector3 = node.global_transform.origin
				# Определяем, находится ли объект перед камерой
				var to_object: Vector3 = world_pos - camera.global_transform.origin
				var camera_forward: Vector3 = -camera.global_transform.basis.z
				var z_depth: float = to_object.dot(camera_forward)
				
				if z_depth > 0:
					# Вызываем project_position с двумя аргументами:
					# - мировая позиция объекта
					# - расстояние z_depth вдоль направления камеры
					var projected: Vector3 = camera.project_position(Vector2(world_pos.x, world_pos.y), 
					z_depth)
					var screen_pos:= Vector2(projected.x, projected.y)
					
					# Проверяем, что экранные координаты попадают в область вьюпорта
					if screen_pos.x >= 0 and screen_pos.x <= viewport_size.x \
					   and screen_pos.y >= 0 and screen_pos.y <= viewport_size.y:
						node.setSelected(true)
						oldSelections.append(node)
		return oldSelections
	return oldSelections

static func handleSelectionBySelectionRect(camera: MainCamera):
	var selectable_nodes := camera.get_tree().get_nodes_in_group(Constants.selectable)
	for node in camera.selected_nodes:
		node.setSelected(false)
		camera.selected_nodes.clear()
	for node in selectable_nodes:
		var screen_pos = camera.get_viewport().get_camera_3d().unproject_position(node.global_transform.origin)
		
		if camera.selection_rect.has_point(screen_pos):
			node.setSelected(true)
			camera.selected_nodes.append(node)
