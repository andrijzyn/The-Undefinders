extends Player
class_name PlayerHuman

func _process(delta: float) -> void:
	if selected_nodes.size() > 0 and selected_nodes[0] and selected_nodes[0] is not ProductionBuilding:
		if Input.is_action_just_pressed("ROTATE"):
			toggleReadyRotate()
		elif Input.is_action_just_pressed("PATROL"):
			toggleReadyPatrol()
		elif Input.is_action_just_pressed("ATTACK"):
			toggleReadyAttack()

		if (Input.is_action_just_released("MULTI_SELECT") and 
		isReadytoPatrol): toggleReadyPatrol()
		elif (Input.is_action_just_released("CONTEXT") 
		and isReadytoPatrol and not Input.is_action_pressed("MULTI_SELECT")): toggleReadyPatrol()
		
		if Input.is_action_just_pressed("CONTEXT") and isReadytoAttack:
			for node in selected_nodes:
				node.start_attack()
		elif Input.is_action_just_pressed("ABORT") or Input.is_action_just_pressed("CONTEXT"):
			for node in selected_nodes:
				node.stop_attack()
	MovementOrderHandler.listen(self, delta)

# ----------- PLAYABLE NODES HANDLING VARS ----------
var selected_nodes: Array[Node3D] = []
var isReadytoRotate := false
var isReadytoPatrol := false
var isReadytoAttack := false

# -------------- HANDLING ORDER STAND-BY -----------
func toggleReadyPatrol() -> void:
	isReadytoPatrol = !isReadytoPatrol
	if isReadytoPatrol: 
		isReadytoRotate = false 
		isReadytoAttack = false
func toggleReadyRotate() -> void:
	isReadytoRotate = !isReadytoRotate
	if isReadytoRotate: 
		isReadytoPatrol = false  
		isReadytoAttack = false
func toggleReadyAttack() -> void:
	isReadytoAttack = !isReadytoAttack
	if isReadytoAttack: 
		isReadytoPatrol = false  
		isReadytoRotate = false 



# ------- ORDERS HANDLING ----- 
class MovementOrderHandler:
	## Ожидает ввода и вызывает соответствующий обработчик команды[br]
	## [param node: MovableUnit] - юнит, которому передаются команды[br]
	## [method OrderHandler.listen]
	static func listen(player: Player, delta):
		if player.selected_nodes.size() > 0 and player.selected_nodes[0] is not ProductionBuilding:
			if Input.is_action_just_pressed("CONTEXT"):
				var targetLocation = RaycastHandler.getRaycastResultPosition(player.camera)
				if player.isReadytoRotate:
					for node in player.selected_nodes:
						handleRotateOrder(node, targetLocation)
						node.mainCamera.player.toggleReadyRotate()
				elif player.isReadytoPatrol:
					#var positions = _get_distributed_positions_around_point(targetLocation, player.selected_nodes.size(), 2.0)
					var positions = get_matrix_positions_around_point(targetLocation, player.selected_nodes.size(), 2.0)
					for i in range(player.selected_nodes.size()):
						handlePatrolOrder(player.selected_nodes[i], positions[i])
				elif not player.isReadytoAttack:
					#var positions = _get_distributed_positions_around_point(targetLocation, player.selected_nodes.size(), 2.0)
					var positions = get_matrix_positions_around_point(targetLocation, player.selected_nodes.size(), 2.0)
					
					for i in range(player.selected_nodes.size()):
						handleMovingOrder(player.selected_nodes[i], positions[i])
			if Input.is_action_just_pressed("ABORT"):
				for node in player.selected_nodes:
					handleAbortOrder(node)


	## Обрабатывает команду поворота юнита в указанном направлении[br]
	## [param node: MovableUnit] - юнит, который должен начать поворот[br]
	## [method OrderHandler.handleRotateOrder]
	static func handleRotateOrder(node: MovableUnit, targetLocation: Vector3) -> void:
		var direction = Vector3(targetLocation.x - node.global_position.x, 0, targetLocation.z - node.global_position.z).normalized()
		if direction.length() > 0:
			node.target_angle = atan2(direction.x, direction.z)
			if not node.isRotating:
				handleAbortOrder(node)
			node.isRotating = true


	## Обрабатывает команду перемещения юнита в указанную точку или массив точек(через shift)[br]
	## [param node: MovableUnit] - юнит, который должен начать двигаться[br]
	## [method OrderHandler.handleMovingOrder]
	static func handleMovingOrder(node: MovableUnit, targetLocation: Vector3) -> void:

		if not Input.is_action_pressed("MULTI_SELECT"):
			node.waypointQueue.clear()
			handleAbortOrder(node)
		node.waypointQueue.append(targetLocation)
		PathHandler.newPath(node)
		node.isMoving = true

	## Обрабатывает команду патрулирования между текущей позицией и указанной точкой или между массивом точек(через shift)[br]
	## [param node: MovableUnit] - юнит, который должен начать патрулирование[br]
	## [method OrderHandler.handlePatrolOrder]
	static func handlePatrolOrder(node: MovableUnit, targetLocation: Vector3) -> void:
		if Input.is_action_pressed("MULTI_SELECT"):
			if node.patrolPoints.is_empty():
				node.patrolPoints.append(node.global_position)
			node.patrolPoints.append(targetLocation)
		else:
			node.patrolPoints = [node.global_position, targetLocation]
		node.currentPatrolPoint = 0
		node.isPatrolling = true
		PathHandler.updatePatrolPath(node)

	## Обрабатывает команду отмены всех действий юнита[br]
	## [param node: MovableUnit] - юнит, чьи выполняемые действия необходимо немедленно прекратить[br]
	## [method OrderHandler.handleAbortOrder]
	static func handleAbortOrder(node: MovableUnit) -> void:
		node.isMoving = false
		node.isPatrolling = false
		node.velocity = Vector3.ZERO
		node.waypointQueue.clear()
		node.currentPaths.clear()
		node.patrolPoints.clear()
		node.currentPath = 0
	
	static func _get_distributed_positions_around_point(center: Vector3, count: int, radius: float) -> Array[Vector3]:
		var positions: Array[Vector3] = []
		var angle_step = TAU / count  # TAU = 2 * PI
		for i in range(count):
			var angle = i * angle_step
			var offset = Vector3(cos(angle), 0, sin(angle)) * radius
			# Можно добавить случайный сдвиг:
			offset.x += randf_range(-0.5, 0.5)
			offset.z += randf_range(-0.5, 0.5)
			positions.append(center + offset)
		return positions
	static func get_matrix_positions_around_point(center: Vector3, count: int, spacing: float) -> Array[Vector3]:
		var positions: Array[Vector3] = []
		# Определяем количество столбцов (колонок) в сетке
		var cols = ceil(sqrt(count))  
		var rows = ceil(count / cols)  
		# Начальная точка сетки, центрируем её вокруг center
		var start_x = center.x - (cols - 1) * spacing / 2
		var start_z = center.z - (rows - 1) * spacing / 2
		var index = 0
		for row in range(rows):
			for col in range(cols):
				if index >= count:
					return positions  # Останавливаем, если юнитов меньше, чем ячеек в сетке
				# Вычисляем координаты с небольшим случайным сдвигом
				var pos_x = start_x + col * spacing + randf_range(-spacing * 0.3, spacing * 0.3)
				var pos_z = start_z + row * spacing + randf_range(-spacing * 0.3, spacing * 0.3)
				positions.append(Vector3(pos_x, center.y, pos_z))
				index += 1
		return positions
