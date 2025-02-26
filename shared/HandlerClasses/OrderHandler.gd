class_name OrderHandler


static func listen(node:MovableUnit, delta):
	if Input.is_action_just_pressed("MRB") and Input.is_action_pressed("rotate") and node.isSelected:
		handleRotateOrder(node)
	elif Input.is_action_just_pressed("MRB") and Input.is_action_pressed("patrol") and node.isSelected:
		handlePatrolOrder(node)
	elif Input.is_action_just_pressed("MRB") and node.isSelected:
		handleMovingOrder(node)
	if Input.is_action_just_pressed("abort") and node.isSelected:
		handleAbortOrder(node)
	if node.isMoving:
		keepMoving(node, delta)
	if node.is_rotating:
		keepRotating(node, delta)
	if node.isPatrolling:
		keepPatrolling(node, delta)
	

static func handleRotateOrder(node: MovableUnit) -> void:
	var targetLocation = RaycastHandler.getRaycastResultPosition(node.mainCamera)
	var direction: Vector3 = targetLocation - node.position
	direction.y = 0
	if direction.length() != 0:
		direction = direction.normalized()
		node.target_angle = atan2(direction.x, direction.z)
		node.is_rotating = true
static func keepRotating(node:MovableUnit, delta) -> void:
	node.rotation.y = lerp_angle(node.rotation.y, node.target_angle, node.rotation_speed * delta)
	print("rotating")
	if Utils.angle_diff(node.rotation.y, node.target_angle) < node.threshold:
		node.rotation.y = node.target_angle
		node.is_rotating = false
		print("end")

static func handleRotateOrderbyPosition(node: MovableUnit, delta:float,  move_direction: Vector3) -> void:
	if move_direction.length() == 0:
		return
	if not node.is_rotating:
		node.target_angle = atan2(move_direction.x, move_direction.z)
		node.is_rotating = true
	#if node.is_rotating:
		#node.rotation.y = lerp_angle(node.rotation.y, node.target_angle, node.rotation_speed * delta)
		#if Utils.angle_diff(node.rotation.y, node.target_angle) < node.threshold:
		#	node.rotation.y = node.target_angle
		#	node.is_rotating = false

static func handleMovingOrder(node:MovableUnit) -> void:
	var targetLocation = RaycastHandler.getRaycastResultPosition(node.mainCamera)
	if Input.is_action_pressed("shift"):
		node.waypointQueue.append(targetLocation)
	else:
		node.waypointQueue.clear()
		node.velocity = Vector3.ZERO
		node.waypointQueue.append(targetLocation)
		_newPath(node)
	if not node.isMoving:
		_newPath(node)
		node.isMoving = true
static func keepMoving(node:MovableUnit, delta) -> void:
		var next_position = node.currentPaths[node.currentPath] - node.global_position
		handleRotateOrderbyPosition(node, delta, next_position)
		#node.rotation.y = atan2(next_position.x, next_position.z)
		node.direction = next_position.normalized()
		node.velocity = node.velocity.lerp(node.direction * node.SPEED, delta)
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

static func handlePatrolOrder(node:MovableUnit) -> void:
	var targetLocation = RaycastHandler.getRaycastResultPosition(node.mainCamera)
	# Если зажата клавиша shift, добавляем новую точку в уже существующий маршрут патрулирования
	if Input.is_action_pressed("shift"):
		if node.patrolPoints.size() == 0:
			node.patrolPoints.append(node.global_position)
		node.patrolPoints.append(targetLocation)
	# Если shift не зажат, создаём новый маршрут:
	# Начинаем с текущей позиции, затем добавляем выбранную точку
	else:
		node.patrolPoints.clear()
		node.patrolPoints.append(node.global_position)
		node.patrolPoints.append(targetLocation)
	if not node.isPatrolling:
		node.currentPatrolPoint = 0
		node.isPatrolling = true
	if node.patrolPoints.size() > 1:
		node.waypointQueue.clear()
		# Текущий сегмент – от точки patrolPoints[currentPatrolIndex] до следующей
		node.waypointQueue.append(node.patrolPoints[node.currentPatrolPoint])
		# Если достигли конца массива – цикл замкнут, поэтому следующий элемент – первый
		node.waypointQueue.append(node.patrolPoints[(node.currentPatrolPoint + 1) % node.patrolPoints.size()])
		_newPath(node)

static func keepPatrolling(node:MovableUnit, delta) -> void:
	# Вычисляем вектор до следующей точки в текущем маршруте
	var next_position = node.currentPaths[node.currentPath] - node.global_position
	#node.rotation.y = atan2(next_position.x, next_position.z)
	handleRotateOrderbyPosition(node, delta, next_position)
	node.direction = next_position.normalized()
	node.velocity = node.velocity.lerp(node.direction * node.SPEED, delta)
	
	# Если объект достиг текущей промежуточной точки пути
	if next_position.length_squared() < 1.0:
		if node.currentPath < (node.currentPaths.size() - 1):
			node.currentPath += 1
		# Если путь завершён, переходим к следующему сегменту патрулирования
		elif node.waypointQueue.size() > 1:
			# Обновляем индекс патрульной точки (циклично)
			node.currentPatrolPoint = (node.currentPatrolPoint + 1) % node.patrolPoints.size()
			
			# Обновляем очередь пути для нового сегмента
			node.waypointQueue.clear()
			node.waypointQueue.append(node.patrolPoints[node.currentPatrolPoint])
			node.waypointQueue.append(node.patrolPoints[(node.currentPatrolPoint + 1) % node.patrolPoints.size()])
			node.velocity = Vector3.ZERO
			_newPath(node)
		else:
			node.velocity = Vector3.ZERO
			node.isPatrolling = false
			node.patrolPoints.clear()


static func handleAbortOrder(node: MovableUnit) -> void: 
		node.isMoving = false
		node.waypointQueue.clear()
		node.currentPaths.clear()
		node.currentPath = 0
		node.is_rotating = false
		node.velocity = Vector3.ZERO
		node.isPatrolling = false
		node.patrolPoints.clear()


static func _newPath(node: MovableUnit) -> void:
	var safeTargetLocation = NavigationServer3D.map_get_closest_point(node.mapRID, node.waypointQueue[0])
	node.currentPaths = NavigationServer3D.map_get_path(node.mapRID, node.global_position, safeTargetLocation, true)
	node.currentPath = 0
