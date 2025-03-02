class_name OrderHandler

static func listen(node: MovableUnit, delta):
	if node.isSelected:
		if Input.is_action_just_pressed("CONTEXT"):
			if Input.is_action_pressed("ROTATE"):
				handleRotateOrder(node)
			elif Input.is_action_pressed("PATROL"):
				handlePatrolOrder(node)
			else:
				node.handle_order("move")

		if Input.is_action_just_pressed("ABORT"):
			handleAbortOrder(node)

	if node.isMoving:
		keepMoving(node, delta)
	elif node.isPatrolling:
		keepPatrolling(node, delta)
	else:
		keepRotating(node, delta)

static func handleRotateOrder(node: MovableUnit) -> void:
	var targetLocation = RaycastHandler.getRaycastResultPosition(node.mainCamera)
	var direction = (targetLocation - node.global_position).normalized()
	direction.y = 0
	if direction.length() > 0:
		node.target_angle = atan2(direction.x, direction.z)

static func keepRotating(node: MovableUnit, delta) -> void:
	if Utils.angle_diff(node.rotation.y, node.target_angle) > node.threshold:
		node.rotation.y = lerp_angle(node.rotation.y, node.target_angle, node.rotation_speed * delta)

static func handleRotateOrderbyPosition(node: MovableUnit, delta: float, move_direction: Vector3) -> void:
	if move_direction.length_squared() > 0.01:
		node.target_angle = atan2(move_direction.x, move_direction.z)
		node.rotation.y = lerp_angle(node.rotation.y, node.target_angle, node.rotation_speed * delta)

static func handleMovingOrder(node: MovableUnit) -> void:
	var targetLocation = RaycastHandler.getRaycastResultPosition(node.mainCamera)
	if not Input.is_action_pressed("shift"):
		node.waypointQueue.clear()
		node.velocity = Vector3.ZERO
	node.waypointQueue.append(targetLocation)
	_newPath(node)
	node.isMoving = true

static func keepMoving(node: MovableUnit, delta) -> void:
	var next_position = node.currentPaths[node.currentPath] - node.global_position
	handleRotateOrderbyPosition(node, delta, next_position)
	node.velocity = node.velocity.lerp(next_position.normalized() * node.SPEED, delta)
	
	if next_position.length_squared() < 1.0:
		if node.currentPath < node.currentPaths.size() - 1:
			node.currentPath += 1
		elif node.waypointQueue.size() > 1:
			if node.waypointQueue.size() > 0:
				node.waypointQueue.remove_at(0)
			node.velocity = Vector3.ZERO
			_newPath(node)
		else:
			node.velocity = Vector3.ZERO
			node.isMoving = false

static func handlePatrolOrder(node: MovableUnit) -> void:
	var targetLocation = RaycastHandler.getRaycastResultPosition(node.mainCamera)
	if Input.is_action_pressed("shift"):
		if node.patrolPoints.is_empty():
			node.patrolPoints.append(node.global_position)
		node.patrolPoints.append(targetLocation)
	else:
		node.patrolPoints = [node.global_position, targetLocation]
	node.currentPatrolPoint = 0
	node.isPatrolling = true
	_updatePatrolPath(node)

static func keepPatrolling(node: MovableUnit, delta) -> void:
	var next_position = node.currentPaths[node.currentPath] - node.global_position
	handleRotateOrderbyPosition(node, delta, next_position)
	node.velocity = node.velocity.lerp(next_position.normalized() * node.SPEED, delta)
	
	if next_position.length_squared() < 1.0:
		if node.currentPath < node.currentPaths.size() - 1:
			node.currentPath += 1
		else:
			node.currentPatrolPoint = (node.currentPatrolPoint + 1) % node.patrolPoints.size()
			_updatePatrolPath(node)

static func _updatePatrolPath(node: MovableUnit) -> void:
	node.waypointQueue = [
		node.patrolPoints[node.currentPatrolPoint],
		node.patrolPoints[(node.currentPatrolPoint + 1) % node.patrolPoints.size()]
	]
	_newPath(node)

static func handleAbortOrder(node: MovableUnit) -> void:
	node.isMoving = false
	node.isPatrolling = false
	node.velocity = Vector3.ZERO
	node.waypointQueue.clear()
	node.currentPaths.clear()
	node.patrolPoints.clear()
	node.currentPath = 0

static func _newPath(node: MovableUnit) -> void:
	if node.waypointQueue.is_empty():
		return
	var safeTargetLocation = NavigationServer3D.map_get_closest_point(node.mapRID, node.waypointQueue[0])
	node.currentPaths = NavigationServer3D.map_get_path(node.mapRID, node.global_position, safeTargetLocation, true)
	node.currentPath = 0
