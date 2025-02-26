class_name OrderHandler

static func handleRotateOrderbyClick(node: MovableUnit, camera: MainCamera, delta:float) -> void:
	if node.isSelected == true:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			
			var targetLocation = RaycastHandler.getRaycastResultPosition(camera)
			var direction: Vector3 = targetLocation - node.position
			direction.y = 0
			if direction.length() != 0:
				direction = direction.normalized()
				node.target_angle = atan2(direction.x, direction.z)
				node.is_rotating = true

			# Если установлена цель, продолжаем поворачивать объект
	if node.is_rotating:
		node.rotation.y = lerp_angle(node.rotation.y, node.target_angle, node.rotation_speed * delta)
		if Utils.angle_diff(node.rotation.y, node.target_angle) < node.threshold:
			node.rotation.y = node.target_angle
			node.is_rotating = false

static func handleRotateOrderbyPosition(node: MovableUnit, delta:float,  move_direction: Vector3) -> void:
	if move_direction.length() == 0:
		return
	if not node.is_rotating:
		node.target_angle = atan2(move_direction.x, move_direction.z)
		node.is_rotating = true
	if node.is_rotating:
		node.rotation.y = lerp_angle(node.rotation.y, node.target_angle, node.rotation_speed * delta)
		if Utils.angle_diff(node.rotation.y, node.target_angle) < node.threshold:
			node.rotation.y = node.target_angle
			node.is_rotating = false

static func handleMovingOrder(node:MovableUnit, camera: MainCamera, delta:float) -> void:
	if node.isSelected:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			var targetLocation = RaycastHandler.getRaycastResultPosition(camera)
			if Input.is_key_pressed(KEY_SHIFT):
				node.waypointQueue.append(targetLocation)
			else:
				node.waypointQueue.clear()
				node.velocity = Vector3.ZERO
				node.waypointQueue.append(targetLocation)
			node.navAgent.target_position = node.waypointQueue[0]
			
			node.isMoving = true

	if node.isMoving:
		var next_position = node.navAgent.get_next_path_position()
		node.direction = (next_position - node.global_transform.origin).normalized()
		handleRotateOrderbyPosition(node, delta, node.direction)
		node.velocity = node.velocity.lerp(node.direction * node.SPEED, delta)
		if node.navAgent.is_target_reached():
			node.velocity = Vector3.ZERO
			node.waypointQueue.remove_at(0)
			if node.waypointQueue.size() > 0:
				node.navAgent.target_position = node.waypointQueue[0]
			else:
				node.isMoving = false

static func handleAbortOrder(node: MovableUnit):
	if node.isSelected:
		if Input.is_action_just_pressed("abort"):
			node.isMoving = false
			node.is_rotating = false
			node.velocity = Vector3.ZERO
	
