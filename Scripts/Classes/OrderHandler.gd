class_name OrderHandler

static func handleRotateOrder(node: MovableUnit, camera: MainCamera, delta:float) -> void:
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
