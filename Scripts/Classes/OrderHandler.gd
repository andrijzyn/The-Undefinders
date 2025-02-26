class_name OrderHandler


static func listen(node:MovableUnit, delta):
	if Input.is_action_just_pressed("MRB") and Input.is_action_pressed("rotate") and node.isSelected:
		handleRotateOrder(node, delta)
	elif Input.is_action_just_pressed("MRB") and node.isSelected:
		handleMovingOrder(node)
	if Input.is_action_just_pressed("abort") and node.isSelected:
		handleAbortOrder(node)
	if node.isMoving:
		keepMoving(node, delta)
	if node.is_rotating:
		keepRotating(node, delta)
	

static func handleRotateOrder(node: MovableUnit, delta:float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		
		var targetLocation = RaycastHandler.getRaycastResultPosition(node.mainCamera)
		var direction: Vector3 = targetLocation - node.position
		direction.y = 0
		if direction.length() != 0:
			direction = direction.normalized()
			node.target_angle = atan2(direction.x, direction.z)
			node.is_rotating = true
static func keepRotating(node:MovableUnit, delta):
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
static func handleMovingOrder(node:MovableUnit) -> void:
	var targetLocation = RaycastHandler.getRaycastResultPosition(node.mainCamera)
	if Input.is_action_pressed("shift"):
		node.waypointQueue.append(targetLocation)
		print("Added")
	else:
		node.waypointQueue.clear()
		node.velocity = Vector3.ZERO
		node.waypointQueue.append(targetLocation)
		_newPath(node)
	if not node.isMoving:
		_newPath(node)
		node.isMoving = true
		print("true")
static func keepMoving(node:MovableUnit, delta):
		var next_position = node.currentPaths[node.currentPath] - node.global_position
		#handleRotateOrderbyPosition(node, delta, next_position)
		node.rotation.y = atan2(next_position.x, next_position.z)
		node.direction = next_position.normalized()
		node.velocity = node.velocity.lerp(node.direction * node.SPEED, delta)
		print(node.velocity)
		if next_position.length_squared() < 1.0:
			if node.currentPath < (node.currentPaths.size() - 1):
				node.currentPath += 1 
			elif node.waypointQueue.size() > 1: 
				node.waypointQueue.remove_at(0)
				node.velocity = Vector3.ZERO
				_newPath(node)
			else: 
				node.velocity = Vector3.ZERO
				node.isMoving = false
static func handleAbortOrder(node: MovableUnit): 
	
		node.isMoving = false
		node.is_rotating = false
		node.velocity = Vector3.ZERO


static func _newPath(node: MovableUnit) -> void:
	var safeTargetLocation = NavigationServer3D.map_get_closest_point(node.mapRID, node.waypointQueue[0])
	node.currentPaths = NavigationServer3D.map_get_path(node.mapRID, node.global_position, safeTargetLocation, true)
	node.currentPath = 0
